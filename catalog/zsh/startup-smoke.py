import fcntl
import os
import pty
import select
import struct
import termios
import time
from pathlib import Path


root = Path(os.environ["TMPDIR"])
etc = root / "etc"
etc.mkdir()
for entry in Path(os.environ["LMX_ETC"]).iterdir():
    (etc / entry.name).symlink_to(entry)
(etc / "group").write_text("smoke:x:1000:\n")


def run(name, personal=False, custom_directory=False, home=None):
    home = home or root / name
    home.mkdir(exist_ok=True)
    config = home / "configuration" if custom_directory else home
    config.mkdir(exist_ok=True)
    content = "LMX_PERSONAL=yes\nzsh-newuser-install() { print LMX_PERSONAL_NEWUSER; }\n"
    if personal:
        (config / ".zshrc").write_text(content)
    (etc / "passwd").write_text(
        f"smoke:x:1000:1000:Smoke:{home}:{os.environ['LMX_ZSH']}\n"
    )

    child, terminal = pty.fork()
    if child == 0:
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
        os.environ.update({
            "HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
            "XDG_DATA_HOME": str(home / ".local/share"), "TERM": "xterm-256color",
            "LMX_EXPECT_PERSONAL": "yes" if personal else "no",
        })
        os.environ.pop("LMX_PERSONAL", None)
        if custom_directory:
            os.environ["ZDOTDIR"] = str(config)
        else:
            os.environ.pop("ZDOTDIR", None)
        os.execvp("proot", [
            "proot", "-i", "1000:1000", "-b", str(etc) + ":/etc",
            "-b", os.environ["LMX_PROFILE"] + ":/run/current-system/sw",
            os.environ["LMX_ZSH"], "-l", "-i", "-c", "source " + os.environ["LMX_CHECK"],
        ])

    output = bytearray()
    reaped = False
    try:
        deadline = time.monotonic() + 60
        while time.monotonic() < deadline:
            ready, _, _ = select.select([terminal], [], [], 0.05)
            if ready:
                try:
                    output.extend(os.read(terminal, 65536))
                except OSError:
                    pass
            assert b"Z Shell configuration function for new users" not in output, (name, output)
            assert b"zsh-newuser-install:" not in output, (name, output)
            completed, status = os.waitpid(child, os.WNOHANG)
            if completed:
                reaped = True
                while select.select([terminal], [], [], 0)[0]:
                    try:
                        chunk = os.read(terminal, 65536)
                    except OSError:
                        break
                    if not chunk:
                        break
                    output.extend(chunk)
                decoded = output.decode(errors="replace")
                assert os.waitstatus_to_exitcode(status) == 0, (name, status, decoded)
                assert b"LMX_ZSH_STARTUP_OK" in output, (name, decoded)
                assert b"Z Shell configuration function for new users" not in output, (name, decoded)
                break
        else:
            raise AssertionError((name, "Zsh startup timed out", output.decode(errors="replace")))
        if personal:
            assert (config / ".zshrc").read_text() == content, "personal startup file changed"
        else:
            for filename in (".zshenv", ".zprofile", ".zshrc", ".zlogin"):
                assert not (home / filename).exists(), (name, "startup file was created", filename)
    finally:
        os.close(terminal)
        if not reaped:
            os.kill(child, 9)
            os.waitpid(child, 0)
    return home


fresh_home = run("fresh-login")
run("repeat-login", home=fresh_home)
run("personal-login", personal=True)
run("personal-directory", personal=True, custom_directory=True)
