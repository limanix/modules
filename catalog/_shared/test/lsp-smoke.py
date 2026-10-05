"""Check that a language server starts and stops cleanly, without an editor."""

from __future__ import annotations

import argparse
from collections.abc import Sequence
import json
import math
import os
from pathlib import Path
import select
import selectors
import signal
import subprocess
import sys
import time


class LspError(RuntimeError):
    """The server sent an invalid message or broke the start/stop order."""


class LspTimeout(LspError, TimeoutError):
    """The server did not reply before the deadline."""


class LspProcess:
    def __init__(self, argv: Sequence[str], *, timeout: float = 10) -> None:
        if not math.isfinite(timeout) or timeout <= 0:
            raise ValueError("timeout must be finite and positive")
        self.timeout = timeout
        self.process = subprocess.Popen(
            argv, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, start_new_session=True,
        )
        assert self.process.stdin and self.process.stdout and self.process.stderr
        os.set_blocking(self.process.stdin.fileno(), False)
        self.selector = selectors.DefaultSelector()
        self.selector.register(self.process.stdout, selectors.EVENT_READ, "stdout")
        self.selector.register(self.process.stderr, selectors.EVENT_READ, "stderr")
        self.buffer = bytearray()
        self.stderr = bytearray()
        self.stdout_eof = False
        self.closed = False
        self.max_message_bytes = 4 * 1024 * 1024

    def __enter__(self) -> LspProcess:
        return self

    def __exit__(self, *_: object) -> None:
        self.close()

    def deadline(self) -> float:
        return time.monotonic() + self.timeout

    def send(self, message: dict, deadline: float | None = None) -> None:
        deadline = self.deadline() if deadline is None else deadline
        payload = json.dumps(message).encode()
        pending = memoryview(f"Content-Length: {len(payload)}\r\n\r\n".encode() + payload)
        stream = self.process.stdin
        assert stream is not None
        while pending:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise LspTimeout("language server stdin timed out")
            if not select.select([], [stream], [], min(remaining, 0.05))[1]:
                self.read_available(deadline)
                continue
            try:
                pending = pending[os.write(stream.fileno(), pending):]
            except BlockingIOError:
                continue
            except BrokenPipeError as error:
                raise LspError("language server closed stdin") from error

    def read_available(self, deadline: float) -> None:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise LspTimeout("language server response timed out")
        events = self.selector.select(min(remaining, 0.05))
        for key, _ in events:
            chunk = os.read(key.fileobj.fileno(), 65536)
            if not chunk:
                self.selector.unregister(key.fileobj)
                if key.data == "stdout":
                    self.stdout_eof = True
            elif key.data == "stdout":
                self.buffer.extend(chunk)
                if len(self.buffer) > self.max_message_bytes + 32768:
                    raise LspError("language server frame exceeds the size limit")
            else:
                self.stderr.extend(chunk)
                del self.stderr[:-65536]

    def receive(self, deadline: float) -> dict:
        while True:
            separators = [(self.buffer.find(marker), marker) for marker in (b"\r\n\r\n", b"\n\n")]
            separators = [(position, marker) for position, marker in separators if position >= 0]
            if separators:
                position, marker = min(separators, key=lambda pair: pair[0])
                if position > 32768:
                    raise LspError("language server headers exceed the size limit")
                headers = {}
                try:
                    for line in bytes(self.buffer[:position]).decode("ascii").splitlines():
                        key, value = line.split(":", 1)
                        key = key.strip().lower()
                        if key in headers:
                            raise ValueError(f"duplicate header {key}")
                        headers[key] = value.strip()
                    length = int(headers["content-length"])
                except (KeyError, ValueError, UnicodeError) as error:
                    raise LspError(f"invalid language server headers: {error}") from error
                if length < 0 or length > self.max_message_bytes:
                    raise LspError("invalid language server Content-Length")
                start = position + len(marker)
                end = start + length
                if len(self.buffer) >= end:
                    payload = bytes(self.buffer[start:end])
                    del self.buffer[:end]
                    try:
                        message = json.loads(payload)
                    except (ValueError, UnicodeError) as error:
                        raise LspError(f"invalid language server JSON: {error}") from error
                    if not isinstance(message, dict) or message.get("jsonrpc") != "2.0":
                        raise LspError("language server message is not a JSON-RPC 2.0 object")
                    return message
            elif len(self.buffer) > 32768:
                raise LspError("language server headers exceed the size limit")
            if self.stdout_eof:
                raise LspError("language server closed stdout before a complete response")
            self.read_available(deadline)

    def response(self, identity: int, deadline: float | None = None):
        deadline = self.deadline() if deadline is None else deadline
        while True:
            message = self.receive(deadline)
            if "method" in message:
                if "id" in message:
                    self.send({
                        "jsonrpc": "2.0", "id": message["id"],
                        "error": {"code": -32601, "message": "Unsupported server request"},
                    }, deadline)
                continue
            if message.get("id") != identity:
                continue
            if "error" in message:
                raise LspError(f"language server returned an error: {message['error']}")
            if "result" not in message:
                raise LspError("language server response has neither result nor error")
            return message["result"]

    def request(self, identity: int, method: str, params):
        deadline = self.deadline()
        self.send({"jsonrpc": "2.0", "id": identity, "method": method, "params": params}, deadline)
        return self.response(identity, deadline)

    def wait(self, timeout: float = 5) -> int:
        deadline = time.monotonic() + timeout
        while self.process.poll() is None:
            self.read_available(deadline)
            self.buffer.clear()
        return self.process.returncode

    def close(self) -> None:
        if self.closed:
            return
        try:
            if self.process.poll() is None:
                os.killpg(self.process.pid, signal.SIGTERM)
                try:
                    self.process.wait(timeout=0.5)
                except subprocess.TimeoutExpired:
                    os.killpg(self.process.pid, signal.SIGKILL)
                    self.process.wait(timeout=2)
        except ProcessLookupError:
            self.process.wait(timeout=2)
        finally:
            self.selector.close()
            for stream in (self.process.stdin, self.process.stdout, self.process.stderr):
                assert stream is not None
                stream.close()
            self.closed = True


def smoke(argv: Sequence[str], *, timeout: float = 10) -> None:
    with LspProcess(argv, timeout=timeout) as server:
        initialized = server.request(1, "initialize", {
            "processId": os.getpid(), "rootUri": Path.cwd().as_uri(), "capabilities": {},
        })
        if not isinstance(initialized, dict) or not isinstance(
            initialized.get("capabilities"), dict
        ):
            raise LspError("language server initialize response has no capabilities object")
        server.send({"jsonrpc": "2.0", "method": "initialized", "params": {}})
        if server.request(2, "shutdown", None) is not None:
            raise LspError("language server shutdown result must be null")
        server.send({"jsonrpc": "2.0", "method": "exit", "params": None})
        status = server.wait()
        if status != 0:
            diagnostic = server.stderr.decode(errors="replace")
            raise LspError(f"language server exited {status}: {diagnostic}")


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--timeout", type=float, default=10, help="seconds allowed per request")
    parser.add_argument("command", nargs=argparse.REMAINDER)
    arguments = parser.parse_args(argv)
    command = arguments.command
    if command[:1] == ["--"]:
        command = command[1:]
    if not command or not math.isfinite(arguments.timeout) or arguments.timeout <= 0:
        parser.error("a server command and a positive timeout are required")
    try:
        smoke(command, timeout=arguments.timeout)
    except (LspError, OSError, subprocess.TimeoutExpired) as error:
        print(f"LSP check failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
