import errno
import fcntl
import os
import pathlib
import pty
import select
import struct
import subprocess
import termios
import time


def inspect(color):
    master, slave = pty.openpty()
    fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 35, 120, 0, 0))
    def terminal_session():
        os.setsid()
        fcntl.ioctl(0, termios.TIOCSCTTY, 0)

    process = subprocess.Popen(
        [os.environ["LMX_LAZYGIT"]], stdin=slave, stdout=slave, stderr=slave,
        preexec_fn=terminal_session,
    )
    os.close(slave)
    output = bytearray()
    try:
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline and color not in output:
            if select.select([master], [], [], 0.1)[0]:
                try:
                    data = os.read(master, 65536)
                    output.extend(data)
                    if b"\x1b[6n" in data:
                        os.write(master, b"\x1b[1;1R")
                    if b"\x1b]11;?" in data:
                        os.write(master, b"\x1b]11;rgb:1e1e/1e1e/2e2e\x1b\\")
                except OSError as error:
                    if error.errno == errno.EIO:
                        break
                    raise
            if process.poll() is not None:
                break
        assert color in output, (process.poll(), bytes(output[-8192:]))
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
        os.close(master)


inspect(b"38;2;137;180;250")
personal = pathlib.Path(os.environ["XDG_CONFIG_HOME"]) / "lazygit/config.yml"
personal.write_text("gui:\n  theme:\n    activeBorderColor: ['#123456', bold]\n")
inspect(b"38;2;18;52;86")
