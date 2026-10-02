import fcntl
import os
from pathlib import Path
import pty
import select
import struct
import termios
import time


root = Path.cwd()


def run(name, shell, init, profile, color, personal=None, explicit=None, exit_key=b"q", project_name="project with spaces", non_theme=False):
    work = root / name
    work.mkdir()
    project = work / project_name
    project.mkdir()
    home = root / f"{name}-home"
    home.mkdir()
    config = home / "xdg"
    config.mkdir()
    if personal:
        (config / "yazi").mkdir()
        (config / "yazi" / "theme.toml").write_text(f'[mgr]\ncwd = {{ fg = "{personal}" }}\n')
    if explicit:
        explicit_config = home / "explicit-yazi"
        explicit_config.mkdir()
        (explicit_config / "theme.toml").write_text(f'[mgr]\ncwd = {{ fg = "{explicit}" }}\n')
    if non_theme:
        (config / "yazi").mkdir()
        (config / "yazi" / "keymap.toml").write_text(
            '[mgr]\nprepend_keymap = [{ on = "e", run = "enter" }]\n'
        )
        (config / "yazi" / ".personal-marker").write_text("retain me\n")
    personal_files = {
        path.name: path.read_bytes() for path in (config / "yazi").glob("*") if path.is_file()
    }
    temporary = work / "temporary"
    temporary.mkdir()
    result = home / "cwd"
    child, terminal = pty.fork()
    if child == 0:
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
        os.environ.update({
            "HOME": str(home), "XDG_CONFIG_HOME": str(config),
            "XDG_CACHE_HOME": str(home / "cache"), "XDG_STATE_HOME": str(home / "state"),
            "TERM": "xterm-256color", "COLORTERM": "truecolor", "TMPDIR": str(temporary),
            "PATH": profile + "/bin:" + os.environ["PATH"],
            "LMX_INIT": init, "LMX_START": str(work), "LMX_RESULT": str(result),
        })
        if explicit:
            os.environ["YAZI_CONFIG_HOME"] = str(explicit_config)
        else:
            os.environ.pop("YAZI_CONFIG_HOME", None)
        arguments = [shell, "-c", 'source "$LMX_INIT"; cd -- "$LMX_START"; y; printf %s "$PWD" > "$LMX_RESULT"']
        os.execv(shell, arguments)

    output = bytearray()
    reaped = False

    def drain():
        if select.select([terminal], [], [], 0.05)[0]:
            try:
                data = os.read(terminal, 65536)
            except OSError:
                return
            output.extend(data)
            if b"\x1b[6n" in data:
                os.write(terminal, b"\x1b[1;1R")
            if b"\x1b]11;?" in data:
                os.write(terminal, b"\x1b]11;rgb:1e1e/1e1e/2e2e\x1b\\")

    def wait(condition):
        deadline = time.monotonic() + 15
        while not condition():
            drain()
            assert time.monotonic() < deadline, (name, "Yazi condition timed out", output[-4096:])

    try:
        wait(lambda: color in output and b"project with spaces" in output)
        assert b"Failed to" not in output, (name, output)
        rendered = len(output)
        os.write(terminal, b"e" if non_theme else b"l")
        wait(lambda: b"project with spaces" in output[rendered:])
        os.write(terminal, exit_key)
        deadline = time.monotonic() + 15
        while True:
            drain()
            completed, status = os.waitpid(child, os.WNOHANG)
            if completed:
                reaped = True
                assert os.waitstatus_to_exitcode(status) == 0, (name, status, output)
                break
            assert time.monotonic() < deadline, (name, "Yazi did not exit", output[-4096:])
        expected = work if exit_key == b"Q" else project
        assert result.read_bytes() == os.fsencode(expected), (name, result.read_bytes(), expected)
        assert not list(temporary.glob("limanix-yazi.*")), (name, "theme overlay was not cleaned")
        assert not list(temporary.glob("yazi-cwd.*")), (name, "cwd handoff was not cleaned")
        remaining = {
            path.name: path.read_bytes() for path in (config / "yazi").glob("*") if path.is_file()
        }
        assert remaining == personal_files, (name, "personal configuration changed")
    finally:
        os.close(terminal)
        if not reaped:
            os.kill(child, 9)
            os.waitpid(child, 0)


profile = os.environ["LMX_YAZI_PROFILE"]
run("bash-default", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], profile, b"38;2;137;220;235")
run("zsh-default", os.environ["LMX_ZSH"], os.environ["LMX_ZSH_INIT"], profile, b"38;2;137;220;235")
run("personal", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], profile, b"38;2;255;0;0", personal="#ff0000")
run("explicit", os.environ["LMX_ZSH"], os.environ["LMX_ZSH_INIT"], profile, b"38;2;0;255;0", explicit="#00ff00")
run("managed", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], os.environ["LMX_YAZI_MANAGED_PROFILE"], b"38;2;18;52;86")
run("retain-cwd", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], profile, b"38;2;137;220;235", exit_key=b"Q")
run("newline-cwd", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], profile, b"38;2;137;220;235", project_name="project with spaces\n")

run("personal-keymap", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], profile, b"38;2;137;220;235", non_theme=True)
run("managed-explicit", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], os.environ["LMX_YAZI_MANAGED_PROFILE"], b"38;2;18;52;86", explicit="#00ff00")
run("managed-flavor", os.environ["LMX_BASH"], os.environ["LMX_BASH_INIT"], os.environ["LMX_YAZI_FLAVOR_PROFILE"], b"38;2;171;205;239")
