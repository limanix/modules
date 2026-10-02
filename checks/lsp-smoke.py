import json
import os
import subprocess
import sys
from pathlib import Path

process = subprocess.Popen(sys.argv[1:], stdin=subprocess.PIPE, stdout=subprocess.PIPE)


def send(message):
    payload = json.dumps(message).encode()
    process.stdin.write(f"Content-Length: {len(payload)}\r\n\r\n".encode() + payload)
    process.stdin.flush()


def response(identity):
    while True:
        headers = {}
        while True:
            line = process.stdout.readline()
            assert line, "language server closed stdout before responding"
            if line in (b"\r\n", b"\n"):
                break
            key, value = line.decode().split(":", 1)
            headers[key.lower()] = value.strip()
        message = json.loads(process.stdout.read(int(headers["content-length"])))
        if message.get("id") == identity:
            assert "error" not in message, message
            return message["result"]


try:
    send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {
        "processId": os.getpid(),
        "rootUri": Path.cwd().as_uri(),
        "capabilities": {},
    }})
    assert isinstance(response(1)["capabilities"], dict)
    send({"jsonrpc": "2.0", "method": "initialized", "params": {}})
    send({"jsonrpc": "2.0", "id": 2, "method": "shutdown", "params": None})
    assert response(2) is None
    send({"jsonrpc": "2.0", "method": "exit", "params": None})
    assert process.wait(timeout=5) == 0
finally:
    if process.poll() is None:
        process.kill()
        process.wait()
