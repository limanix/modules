"""Tests of lsp-smoke.py against fake local servers; no real server needed."""

import importlib.util
import os
from pathlib import Path
import sys
import unittest


path = Path(os.environ.get(
    "LSP_SMOKE_SOURCE", Path(__file__).resolve().parents[1] / "lsp-smoke.py",
))
spec = importlib.util.spec_from_file_location("limanix_lsp_smoke", path)
lsp = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lsp)

SERVER = r"""
import json,sys,time

def receive():
    headers = {}
    while True:
        line = sys.stdin.buffer.readline()
        assert line, 'client closed stdin'
        if line in (b'\r\n', b'\n'):
            break
        key,value = line.decode().split(':',1)
        headers[key.lower()] = value.strip()
    return json.loads(sys.stdin.buffer.read(int(headers['content-length'])))

def send(message, fragmented=False):
    payload = json.dumps(message).encode()
    frame = f'Content-Length: {len(payload)}\r\n\r\n'.encode() + payload
    if fragmented:
        parts = [frame[:1],frame[1:7],frame[7:23],frame[23:31],frame[31:]]
    else:
        parts = [frame]
    for part in parts:
        sys.stdout.buffer.write(part)
        sys.stdout.buffer.flush()
        if fragmented:
            time.sleep(.01)

def lifecycle(fragmented=False):
    send({'jsonrpc':'2.0','id':1,'result':{'capabilities':{}}}, fragmented)
    assert receive()['method'] == 'initialized'
    assert receive()['method'] == 'shutdown'
    send({'jsonrpc':'2.0','id':2,'result':None}, fragmented)
    assert receive()['method'] == 'exit'

assert receive()['method'] == 'initialize'
"""


def command(source):
    return [sys.executable, "-u", "-c", SERVER + source]


class ProtocolTests(unittest.TestCase):
    def test_server_request_with_matching_response_id(self):
        for identity in (1, 44):
            with self.subTest(server_request_id=identity):
                source = f"""
send({{'jsonrpc':'2.0','id':{identity},'method':'window/showMessageRequest','params':{{}}}})
answer = receive()
assert answer['id'] == {identity} and answer['error']['code'] == -32601
assert 'method' not in answer
lifecycle()
"""
                lsp.smoke(command(source), timeout=2)

    def test_fragmented_headers_and_body(self):
        lsp.smoke(command("lifecycle(fragmented=True)"), timeout=2)

    def test_notifications_do_not_replace_the_response(self):
        source = "send({'jsonrpc':'2.0','method':'window/logMessage','params':{}}); lifecycle()"
        lsp.smoke(command(source), timeout=2)

    def test_error_response_is_reported(self):
        source = "send({'jsonrpc':'2.0','id':1,'error':{'code':-32002,'message':'not ready'}})"
        with self.assertRaisesRegex(lsp.LspError, "not ready"):
            lsp.smoke(command(source), timeout=2)

    def test_eof_during_a_fragment_is_reported(self):
        source = (
            "sys.stdout.buffer.write(b'Content-Length: 100\\r\\n\\r\\n{}'); "
            "sys.stdout.buffer.flush()"
        )
        with self.assertRaisesRegex(lsp.LspError, "closed stdout"):
            lsp.smoke(command(source), timeout=2)

    def test_missing_result_is_reported(self):
        with self.assertRaisesRegex(lsp.LspError, "neither result nor error"):
            lsp.smoke(command("send({'jsonrpc':'2.0','id':1})"), timeout=2)

    def test_silent_server_times_out_and_is_reaped(self):
        with lsp.LspProcess(command("time.sleep(30)"), timeout=0.05) as server:
            with self.assertRaises(lsp.LspTimeout):
                server.request(1, "initialize", {})
        self.assertIsNotNone(server.process.poll())
        self.assertTrue(server.closed)


if __name__ == "__main__":
    unittest.main()
