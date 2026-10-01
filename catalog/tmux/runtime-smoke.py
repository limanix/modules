import base64
import fcntl
import os
from pathlib import Path
import pty
import select
import shlex
import struct
import subprocess
import sys
import termios
import time
import tty


if len(sys.argv) > 1 and sys.argv[1] == "--capture":
    tty.setraw(0)
    with open(sys.argv[2], "wb", buffering=0) as capture:
        while data := os.read(0, 4096):
            capture.write(data)
    sys.exit(0)


tmux = os.environ["LMX_TMUX"]
root = Path.cwd()


class Client:
    def __init__(self, name, configuration, session, directory, command=None):
        self.name = name
        self.output = bytearray()
        self.child, self.terminal = pty.fork()
        if self.child == 0:
            fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
            arguments = [
                tmux, "-L", name, "-f", configuration,
                "new-session", "-s", session, "-c", str(directory),
            ]
            if command:
                arguments.append(command)
            os.execv(tmux, arguments)
        self.wait(lambda: self.run("has-session", "-t", session, check=False).returncode == 0)

    def run(self, *arguments, check=True):
        self.drain()
        return subprocess.run(
            [tmux, "-L", self.name, *arguments], capture_output=True, check=check,
        )

    def text(self, *arguments):
        return self.run(*arguments).stdout.decode().strip()

    def drain(self):
        while select.select([self.terminal], [], [], 0)[0]:
            try:
                self.output.extend(os.read(self.terminal, 65536))
            except OSError:
                break

    def wait(self, condition, seconds=15):
        deadline = time.monotonic() + seconds
        while not condition():
            self.drain()
            if time.monotonic() >= deadline:
                raise AssertionError(("tmux condition timed out", self.output[-4096:]))
            time.sleep(0.05)

    def keys(self, keys):
        os.write(self.terminal, keys)

    def close(self):
        self.run("kill-server", check=False)
        os.close(self.terminal)
        deadline = time.monotonic() + 5
        while True:
            child, _ = os.waitpid(self.child, os.WNOHANG)
            if child:
                return
            if time.monotonic() >= deadline:
                os.kill(self.child, 9)
                os.waitpid(self.child, 0)
                return
            time.sleep(0.05)


def capture_command(path):
    return shlex.join([sys.executable, __file__, "--capture", str(path)])


def wait_input(client, path, expected):
    try:
        client.wait(lambda: path.read_bytes() == expected)
    except AssertionError as error:
        raise AssertionError(("forwarded keys", path.read_bytes(), expected)) from error


def shared_settings(client, key_mode="vi", terminal="tmux-256color", escape_time="10"):
    assert client.text("show-options", "-gv", "mouse") == "on"
    assert client.text("show-options", "-sv", "set-clipboard") == "on"
    assert client.text("show-options", "-gv", "mode-keys") == key_mode
    assert client.text("show-options", "-gv", "default-terminal") == terminal
    assert client.text("show-options", "-sv", "escape-time") == escape_time
    assert "xterm*:RGB:clipboard" in client.text("show-options", "-sv", "terminal-features")
    assert "begin-selection" in client.text("list-keys", "-T", "copy-mode-vi", "v")
    assert "copy-selection-and-cancel" in client.text("list-keys", "-T", "copy-mode-vi", "y")
    assert client.text("show-options", "-gv", "@continuum-save-interval") == "15"
    assert client.text("show-options", "-gv", "@continuum-restore") == "on"
    client.wait(lambda: b"save.sh" in client.run("list-keys", "-T", "prefix", "C-s", check=False).stdout)
    assert "restore.sh" in client.text("list-keys", "-T", "prefix", "C-r")
    assert "continuum_save.sh" in client.text("show-options", "-gv", "status-right")


left_directory = root / "left"
right_directory = root / "right"
left_directory.mkdir()
right_directory.mkdir()
capture = root / "enabled-input"
client = Client("enabled", os.environ["LMX_TMUX_ENABLED"], "layout", left_directory, capture_command(capture))
try:
    shared_settings(client)
    client.wait(capture.exists)
    left = client.text("display-message", "-p", "#{pane_id}")
    right = client.text(
        "split-window", "-h", "-P", "-F", "#{pane_id}", "-c", str(right_directory),
        capture_command(root / "right-input"),
    )
    client.keys(b"\x08")
    client.wait(lambda: client.text("display-message", "-p", "#{pane_id}") == left)
    client.keys(b"\x0c")
    client.wait(lambda: client.text("display-message", "-p", "#{pane_id}") == right)
    client.keys(b"\x08")
    client.wait(lambda: client.text("display-message", "-p", "#{pane_id}") == left)
    width = int(client.text("display-message", "-p", "#{pane_width}"))
    client.keys(b"\x1bl")
    client.wait(lambda: int(client.text("display-message", "-p", "#{pane_width}")) == width + 3)
    client.keys(b"\x1bh")
    client.wait(lambda: int(client.text("display-message", "-p", "#{pane_width}")) == width)
    bottom = client.text("split-window", "-v", "-t", left, "-P", "-F", "#{pane_id}")
    client.keys(b"\x0b")
    client.wait(lambda: client.text("display-message", "-p", "#{pane_id}") == left)
    client.keys(b"\x0a")
    client.wait(lambda: client.text("display-message", "-p", "#{pane_id}") == bottom)
    height = int(client.text("display-message", "-p", "#{pane_height}"))
    client.keys(b"\x1bk")
    client.wait(lambda: int(client.text("display-message", "-p", "#{pane_height}")) != height)
    client.keys(b"\x1bj")
    client.wait(lambda: int(client.text("display-message", "-p", "#{pane_height}")) == height)
    client.run("kill-pane", "-t", bottom)
    client.run("select-pane", "-t", left)
    forwarded = b""
    for key in [b"\x08", b"\x0a", b"\x0b", b"\x0c"]:
        client.keys(b"\x02" + key)
        forwarded += key
        wait_input(client, capture, forwarded)
    client.run("set-option", "-p", "@pane-is-vim", "1")
    client.keys(b"\x08")
    wait_input(client, capture, forwarded + b"\x08")
    client.keys(b"\x1bh")
    wait_input(client, capture, forwarded + b"\x08\x1bh")
    client.run("set-option", "-pu", "@pane-is-vim")

    # Execute the configured copy-mode keys and observe tmux's clipboard output.
    client.run("new-window", "-n", "copy", "printf limanix-copy-line; sleep 60")
    client.wait(lambda: b"limanix-copy-line" in client.run("capture-pane", "-p").stdout)
    client.keys(b"\x02[")
    client.wait(lambda: client.text("display-message", "-p", "#{pane_in_mode}") == "1")
    client.run("send-keys", "-X", "start-of-line")
    client.keys(b"v")
    # Let the attached client process the selection key before moving its cursor.
    time.sleep(0.05)
    client.run("send-keys", "-X", "end-of-line")
    client.keys(b"y")
    client.wait(lambda: client.text("display-message", "-p", "#{pane_in_mode}") == "0")
    copied = client.run("save-buffer", "-").stdout
    assert copied.rstrip(b"\n") == b"limanix-copy-line", repr(copied)
    clipboard = base64.b64encode(copied)
    client.wait(lambda: b"\x1b]52;" in client.output and clipboard in client.output)
    client.run("kill-window")

    # Trigger the installed save and restore bindings, without duplicating plugin setup.
    client.keys(b"\x02\x13")
    snapshot = Path.home() / ".tmux/resurrect/last"
    client.wait(snapshot.exists)
    saved = snapshot.read_text()
    assert "layout" in saved and str(left_directory) in saved and str(right_directory) in saved
    client.run("new-session", "-d", "-s", "bootstrap")
    client.run("switch-client", "-t", "bootstrap")
    client.run("kill-session", "-t", "layout")
    client.keys(b"\x02\x12")
    client.wait(lambda: client.run("has-session", "-t", "layout", check=False).returncode == 0)
    client.wait(lambda: len(client.text("list-panes", "-t", "layout:0", "-F", "#{pane_id}").splitlines()) == 2)
    assert set(client.text("list-panes", "-t", "layout:0", "-F", "#{pane_current_path}").splitlines()) == {
        str(left_directory), str(right_directory),
    }
finally:
    client.close()

client = Client("restored", os.environ["LMX_TMUX_ENABLED"], "bootstrap", root)
try:
    client.wait(lambda: client.run("has-session", "-t", "layout", check=False).returncode == 0)
    client.wait(lambda: len(client.text("list-panes", "-t", "layout:0", "-F", "#{pane_id}").splitlines()) == 2)
    assert set(client.text("list-panes", "-t", "layout:0", "-F", "#{pane_current_path}").splitlines()) == {
        str(left_directory), str(right_directory),
    }
finally:
    client.close()

# A separate HOME prevents automatic restoration from changing these fixtures.
os.environ["HOME"] = str(root / "disabled-home")
Path.home().mkdir()
capture = root / "disabled-input"
client = Client("disabled", os.environ["LMX_TMUX_DISABLED"], "plain", root, capture_command(capture))
try:
    shared_settings(client)
    client.wait(capture.exists)
    for key in "hjkl":
        assert client.run("list-keys", "-T", "root", f"C-{key}", check=False).returncode != 0
        assert client.run("list-keys", "-T", "root", f"M-{key}", check=False).returncode != 0
        assert client.run("list-keys", "-T", "prefix", f"C-{key}", check=False).returncode != 0
    client.keys(b"\x08\x0a\x0b\x0c\x1bh\x1bj\x1bk\x1bl")
    wait_input(client, capture, b"\x08\x0a\x0b\x0c\x1bh\x1bj\x1bk\x1bl")
finally:
    client.close()

client = Client("overridden", os.environ["LMX_TMUX_OVERRIDDEN"], "preferences", root)
try:
    shared_settings(client, "emacs", "screen-256color", "25")
finally:
    client.close()
