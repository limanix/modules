import os
import pty
import select
import time
from pathlib import Path

etc = Path(os.environ["TMPDIR"]) / "etc"
etc.mkdir()
for entry in Path(os.environ["LMX_ETC"]).iterdir():
    (etc / entry.name).symlink_to(entry)
(etc / "passwd").write_text(
    f"smoke:x:1000:1000:Smoke:{os.environ['HOME']}:{os.environ['LMX_ZSH']}\n"
)
(etc / "group").write_text("smoke:x:1000:\n")

child, terminal = pty.fork()
if child == 0:
    os.execvp("proot", [
        "proot", "-i", "1000:1000", "-b", str(etc) + ":/etc",
        "-b", os.environ["LMX_PROFILE"] + ":/run/current-system/sw",
        os.environ["LMX_ZSH"], "-i", "-c", "source " + os.environ["LMX_CHECK"],
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
            assert os.waitstatus_to_exitcode(status) == 0, (os.waitstatus_to_exitcode(status), output.decode(errors="replace"))
            assert b"LMX_ZSH_STARTUP_OK" in output, output.decode(errors="replace")
            break
    else:
        raise AssertionError("Zsh startup timed out: " + output.decode(errors="replace"))
finally:
    os.close(terminal)
    if not reaped:
        os.kill(child, 9)
        os.waitpid(child, 0)
