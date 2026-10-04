"""Verify generic terminal framing, deadlines and resource ownership."""

import json
import os
from pathlib import Path
import signal
import sys
import tempfile
import time
import unittest

from terminal import TerminalProcess, TerminalError, TerminalTimeout


def command(source):
    return [sys.executable, "-u", "-c", source]


class TerminalTests(unittest.TestCase):
    def test_child_environment_directory_and_terminal_size(self):
        source = (
            "import fcntl,json,os,struct,termios; "
            "size=struct.unpack('HHHH',fcntl.ioctl(0,termios.TIOCGWINSZ,b'\\0'*8)); "
            "print(json.dumps([os.getcwd(),os.environ['TERMINAL_FIXTURE'],size[:2]]))"
        )
        with tempfile.TemporaryDirectory() as directory:
            with TerminalProcess(
                command(source), cwd=directory,
                env={**os.environ, "TERMINAL_FIXTURE": "isolated"}, rows=17, columns=53,
            ) as terminal:
                self.assertEqual(terminal.wait(), 0)
                result = json.loads(terminal.output.decode())
                self.assertEqual(Path(result[0]).resolve(), Path(directory).resolve())
                self.assertEqual(result[1:], ["isolated", [17, 53]])

    def test_raw_bytes_and_fragmented_output(self):
        source = (
            "import os,time,tty; tty.setraw(0); "
            "os.write(1,b're'); time.sleep(.03); os.write(1,b'ady'); "
            "value=os.read(0,3); os.write(1,value.hex().encode())"
        )
        with TerminalProcess(command(source)) as terminal:
            terminal.until(lambda: b"ready" in terminal.output)
            terminal.send(b"A\x00B")
            self.assertEqual(terminal.wait(), 0)
            self.assertIn(b"410042", terminal.output)
            self.assertEqual(terminal.read(timeout=0.01), b"")
            self.assertTrue(terminal.eof)

    def test_output_keeps_a_bounded_diagnostic_tail(self):
        with TerminalProcess(
            command("import os; os.write(1,b'x'*20000+b'end')"), output_limit=128,
        ) as terminal:
            self.assertEqual(terminal.wait(), 0)
            self.assertLessEqual(len(terminal.output), 128)
            self.assertTrue(terminal.output.endswith(b"end"))

    def test_early_exit_reports_status_and_output(self):
        with TerminalProcess(command("print('failure'); raise SystemExit(9)")) as terminal:
            with self.assertRaisesRegex(TerminalError, "child exited 9.*failure"):
                terminal.until(lambda: False, label="readiness")

    def test_deadline_and_context_cleanup(self):
        with self.assertRaises(TerminalTimeout):
            with TerminalProcess(command("import time; time.sleep(30)")) as terminal:
                terminal.until(lambda: False, timeout=0.05)
        self.assertTrue(terminal.closed)
        self.assertIsNotNone(terminal.poll())
        with self.assertRaises(OSError):
            os.fstat(terminal.fd)

    def test_cleanup_kills_a_child_ignoring_termination(self):
        source = (
            "import os,signal,time; signal.signal(signal.SIGTERM,signal.SIG_IGN); "
            "os.write(1,b'ready'); time.sleep(30)"
        )
        start = time.monotonic()
        with TerminalProcess(command(source)) as terminal:
            terminal.until(lambda: b"ready" in terminal.output)
        self.assertEqual(terminal.poll(), -signal.SIGKILL)
        self.assertLess(time.monotonic() - start, 5)
        terminal.close()  # Closing an already closed transport is safe.


if __name__ == "__main__":
    unittest.main()
