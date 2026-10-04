"""Bounded terminal transport for module-owned interactive checks.

This helper knows only processes and terminals. Callers own fixtures, terminal
query replies, application commands, conditions, and assertions.
"""

from __future__ import annotations

import errno
import fcntl
import os
from pathlib import Path
import pty
import select
import signal
import struct
import termios
import time
from collections.abc import Callable, Mapping, Sequence


class TerminalError(RuntimeError):
    """The terminal closed or its child exited before the requested condition."""


class TerminalTimeout(TerminalError, TimeoutError):
    """A terminal operation exceeded its monotonic deadline."""


class TerminalProcess:
    """Run argv in its own controlling terminal and own its bounded lifecycle."""

    def __init__(
        self,
        argv: Sequence[str],
        *,
        env: Mapping[str, str] | None = None,
        cwd: str | Path | None = None,
        rows: int = 40,
        columns: int = 120,
        output_limit: int = 65536,
    ) -> None:
        if not argv or rows < 1 or columns < 1 or output_limit < 1:
            raise ValueError("argv, terminal dimensions and output_limit must be nonempty")
        self.output = bytearray()
        self.output_limit = output_limit
        self.returncode: int | None = None
        self.closed = False
        self.eof = False
        self.pid, self.fd = pty.fork()
        if self.pid == 0:
            try:
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", rows, columns, 0, 0))
                if cwd is not None:
                    os.chdir(cwd)
                os.execvpe(argv[0], list(argv), dict(env) if env is not None else os.environ)
            except (OSError, ValueError) as error:
                os.write(2, f"terminal command failed: {error}\n".encode())
                os._exit(127)
        os.set_blocking(self.fd, False)

    def __enter__(self) -> TerminalProcess:
        return self

    def __exit__(self, *_: object) -> None:
        self.close()

    def diagnostic(self) -> str:
        return self.output.decode(errors="replace")

    def poll(self) -> int | None:
        if self.returncode is None:
            child, status = os.waitpid(self.pid, os.WNOHANG)
            if child:
                self.returncode = os.waitstatus_to_exitcode(status)
        return self.returncode

    def read(self, timeout: float = 0) -> bytes:
        if self.closed or self.eof:
            return b""
        if not select.select([self.fd], [], [], max(0, timeout))[0]:
            return b""
        try:
            chunk = os.read(self.fd, 65536)
        except BlockingIOError:
            return b""
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            chunk = b""
        if not chunk:
            self.eof = True
            return b""
        self.output.extend(chunk)
        del self.output[:-self.output_limit]
        return chunk

    def drain(self) -> bytes:
        # Bound each call even when a child continuously writes to the terminal.
        chunks = []
        size = 0
        while size < self.output_limit:
            chunk = self.read()
            if not chunk:
                break
            chunks.append(chunk)
            size += len(chunk)
        return b"".join(chunks)

    def send(self, data: bytes, timeout: float = 5) -> None:
        deadline = time.monotonic() + timeout
        pending = memoryview(data)
        while pending:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TerminalTimeout(f"terminal send timed out: {self.diagnostic()}")
            if self.closed or self.eof or self.poll() is not None:
                raise TerminalError(f"terminal closed before send: {self.diagnostic()}")
            if not select.select([], [self.fd], [], min(0.05, remaining))[1]:
                self.drain()
                continue
            try:
                count = os.write(self.fd, pending)
            except BlockingIOError:
                continue
            except OSError as error:
                if error.errno != errno.EIO:
                    raise
                raise TerminalError(f"terminal closed before send: {self.diagnostic()}") from error
            pending = pending[count:]

    def until(
        self,
        predicate: Callable[[], bool],
        timeout: float = 15,
        label: str = "condition",
    ) -> None:
        deadline = time.monotonic() + timeout
        while not predicate():
            self.drain()
            # Recheck before treating a completed child as an early exit.
            if predicate():
                return
            status = self.poll()
            if status is not None:
                self.drain()
                if predicate():
                    return
                raise TerminalError(f"{label}: child exited {status}: {self.diagnostic()}")
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TerminalTimeout(f"{label} timed out: {self.diagnostic()}")
            self.read(min(0.05, remaining))

    def wait(self, timeout: float = 10) -> int:
        self.until(lambda: self.poll() is not None, timeout, "process exit")
        self.drain()
        assert self.returncode is not None
        return self.returncode

    def _signal(self, number: int) -> None:
        try:
            if os.getpgid(self.pid) == self.pid:
                os.killpg(self.pid, number)
            else:
                os.kill(self.pid, number)
        except ProcessLookupError:
            pass

    def close(self) -> None:
        if self.closed:
            return
        try:
            if self.poll() is None:
                self._signal(signal.SIGTERM)
                try:
                    self.wait(timeout=0.5)
                except TerminalTimeout:
                    self._signal(signal.SIGKILL)
                    self.wait(timeout=2)
        finally:
            os.close(self.fd)
            self.closed = True
