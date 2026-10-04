import base64
import os
from pathlib import Path
import shlex
import subprocess
import sys
import time
import tty

from terminal import TerminalError, TerminalProcess


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
        arguments = [
            tmux, "-L", name, "-f", configuration,
            "new-session", "-s", session, "-c", str(directory),
        ]
        if command:
            arguments.append(command)
        self.terminal = TerminalProcess(arguments)
        self.output = self.terminal.output
        try:
            self.wait(lambda: self.run("has-session", "-t", session, check=False).returncode == 0)
        except BaseException:
            self.close()
            raise

    def run(self, *arguments, check=True):
        self.terminal.drain()
        return subprocess.run(
            [tmux, "-L", self.name, *arguments], capture_output=True,
            check=check, timeout=10,
        )

    def text(self, *arguments):
        return self.run(*arguments).stdout.decode().strip()

    def wait(self, condition, seconds=15):
        self.terminal.until(condition, timeout=seconds, label="tmux condition")

    def keys(self, keys):
        self.terminal.send(keys)

    def close(self):
        try:
            self.run("kill-server", check=False)
        finally:
            self.terminal.close()


def capture_command(path):
    return shlex.join([sys.executable, __file__, "--capture", str(path)])


def wait_input(client, path, expected):
    try:
        client.wait(lambda: path.read_bytes() == expected)
    except (AssertionError, TerminalError) as error:
        raise AssertionError(("forwarded keys", path.read_bytes(), expected)) from error


def shared_settings(
    client, key_mode="vi", terminal="tmux-256color", escape_time="10",
    status_style="bg=#181825,fg=#cdd6f4", pane_border="fg=#cba6f7",
    mode_style="bg=#cba6f7,fg=#1e1e2e",
):
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
    for option, expected in [
        ("status-style", status_style),
        ("pane-active-border-style", pane_border),
        ("mode-style", mode_style),
    ]:
        actual = client.text("show-options", "-gv", option)
        assert set(actual.split(",")) == set(expected.split(",")), (option, actual, expected)
    client.wait(
        lambda: b"save.sh" in client.run(
            "list-keys", "-T", "prefix", "C-s", check=False,
        ).stdout
    )
    assert "restore.sh" in client.text("list-keys", "-T", "prefix", "C-r")
    assert "continuum_save.sh" in client.text("show-options", "-gv", "status-right")


left_directory = root / "left"
right_directory = root / "right"
left_directory.mkdir()
right_directory.mkdir()
capture = root / "enabled-input"
client = Client(
    "enabled", os.environ["LMX_TMUX_ENABLED"], "layout", left_directory,
    capture_command(capture),
)
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

finally:
    client.close()

# A separate HOME prevents automatic restoration from changing these fixtures.
os.environ["HOME"] = str(root / "disabled-home")
Path.home().mkdir()
capture = root / "disabled-input"
client = Client(
    "disabled", os.environ["LMX_TMUX_DISABLED"], "plain", root,
    capture_command(capture),
)
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
    shared_settings(
        client, "emacs", "screen-256color", "25",
        "bg=black,fg=white", "fg=blue", "bg=blue,fg=white",
    )
finally:
    client.close()
