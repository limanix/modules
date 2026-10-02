import json
import os
import socket
import subprocess
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

import psycopg


with socket.socket() as socket_:
    socket_.bind(("127.0.0.1", 0))
    port = socket_.getsockname()[1]

base_url = f"http://127.0.0.1:{port}"
environment = {**os.environ, "HOST": "127.0.0.1", "PORT": str(port)}


def request(path, payload=None):
    body = None if payload is None else json.dumps(payload).encode("utf-8")
    message = Request(
        base_url + path,
        data=body,
        headers={"Content-Type": "application/json"},
    )
    try:
        response = urlopen(message, timeout=2)
    except HTTPError as error:
        response = error
    with response:
        return response.status, json.load(response)


def start_api():
    process = subprocess.Popen([sys.executable, sys.argv[1]], env=environment)
    for _ in range(100):
        assert process.poll() is None, "API exited before readiness"
        try:
            if request("/health") == (200, {"status": "ok"}):
                return process
        except URLError:
            pass
        time.sleep(0.05)
    process.terminate()
    process.wait(timeout=5)
    raise AssertionError("API did not become ready")


process = start_api()
try:
    assert request("/notes") == (200, [])
    status, first = request("/notes", {"text": "  A cozy note  "})
    assert status == 201 and first["text"] == "A cozy note", (status, first)
    assert isinstance(first["id"], int) and first["created_at"]
    quoted = "quote'); DROP TABLE notes; --"
    status, second = request("/notes", {"text": quoted})
    assert status == 201 and second["text"] == quoted, (status, second)
    assert second["id"] > first["id"]
    assert request("/notes") == (200, [first, second])
    for invalid in ({"text": "  "}, {"text": 12}, {"text": "x" * 501}):
        assert request("/notes", invalid)[0] == 400, invalid
    with psycopg.connect(os.environ["DATABASE_URL"]) as connection:
        saved = connection.execute("SELECT text FROM notes ORDER BY id").fetchall()
        assert saved == [("A cozy note",), (quoted,)], saved
finally:
    process.terminate()
    process.wait(timeout=5)

process = start_api()
try:
    assert request("/notes") == (200, [first, second])
finally:
    process.terminate()
    process.wait(timeout=5)
