import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import urlsplit

import psycopg
from psycopg.rows import dict_row


DATABASE_URL = os.environ["DATABASE_URL"]


def query(sql, parameters=()):
    with psycopg.connect(DATABASE_URL, row_factory=dict_row) as connection:
        return connection.execute(sql, parameters).fetchall()


def serialize_note(row):
    return {**row, "created_at": row["created_at"].isoformat()}


class NotesHandler(BaseHTTPRequestHandler):
    def respond(self, status, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urlsplit(self.path).path
        try:
            if path == "/health":
                query("SELECT 1")
                self.respond(200, {"status": "ok"})
            elif path == "/notes":
                notes = query("SELECT id, text, created_at FROM notes ORDER BY id")
                self.respond(200, [serialize_note(note) for note in notes])
            else:
                self.respond(404, {"error": "not found"})
        except psycopg.Error:
            self.respond(503, {"error": "database unavailable"})

    def do_POST(self):
        if urlsplit(self.path).path != "/notes":
            self.respond(404, {"error": "not found"})
            return
        if self.headers.get_content_type() != "application/json":
            self.respond(415, {"error": "use application/json"})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            self.respond(400, {"error": "invalid content length"})
            return
        if length < 1 or length > 4096:
            self.respond(400, {"error": "body must contain 1 to 4096 bytes"})
            return
        try:
            payload = json.loads(self.rfile.read(length).decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            self.respond(400, {"error": "invalid JSON"})
            return
        if (
            not isinstance(payload, dict)
            or set(payload) != {"text"}
            or not isinstance(payload["text"], str)
        ):
            self.respond(400, {"error": "provide a text string"})
            return
        text = payload["text"].strip()
        if not 1 <= len(text) <= 500:
            self.respond(400, {"error": "text must contain 1 to 500 characters"})
            return
        try:
            note = query(
                "INSERT INTO notes (text) VALUES (%s) RETURNING id, text, created_at",
                (text,),
            )[0]
            self.respond(201, serialize_note(note))
        except psycopg.Error:
            self.respond(503, {"error": "database unavailable"})


if __name__ == "__main__":
    with psycopg.connect(DATABASE_URL) as connection:
        connection.execute(Path(__file__).with_name("schema.sql").read_text())
    address = (os.environ.get("HOST", "0.0.0.0"), int(os.environ.get("PORT", "8000")))
    with HTTPServer(address, NotesHandler) as server:
        server.serve_forever()
