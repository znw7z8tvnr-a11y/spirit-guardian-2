"""Exercise range downloads, transient 504, and CRC failure on a local server."""
import io
import pathlib
import re
import tempfile
import threading
import unittest
import zipfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from install_godot_web_templates import NAMES, install


def fixture():
    inner = io.BytesIO()
    with zipfile.ZipFile(inner, 'w') as z:
        z.writestr('godot.wasm', b'example wasm fixture')
    outer = io.BytesIO()
    with zipfile.ZipFile(outer, 'w', zipfile.ZIP_STORED) as z:
        z.writestr('templates/not_requested.bin', b'x'*(8*1024*1024))
        for name in NAMES:
            z.writestr('templates/'+name, inner.getvalue())
    return outer.getvalue(), inner.getvalue()


class Handler(BaseHTTPRequestHandler):
    data, template = fixture()
    served = 0
    fail_once = False
    ignore_range = False

    def log_message(self, *_):
        pass

    def do_GET(self):
        cls = type(self)
        if cls.fail_once:
            cls.fail_once = False
            self.send_response(504);self.end_headers();return
        if cls.ignore_range:
            self.send_response(200);self.send_header('Content-Length', '0');self.end_headers();return
        first, last = map(int, re.fullmatch(r'bytes=(\d+)-(\d+)', self.headers['Range']).groups())
        payload = cls.data[first:last+1]
        self.send_response(206)
        self.send_header('Content-Range', f'bytes {first}-{last}/{len(cls.data)}')
        self.send_header('Content-Length', str(len(payload)))
        self.end_headers();self.wfile.write(payload);cls.served += len(payload)


class RangeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()
        cls.url = f'http://127.0.0.1:{cls.server.server_port}/official-fixture.tpz'

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown();cls.server.server_close()

    def setUp(self):
        Handler.data, Handler.template = fixture()
        Handler.served = 0;Handler.fail_once = False;Handler.ignore_range = False

    def test_selected_entries_only(self):
        with tempfile.TemporaryDirectory() as d:
            report = install(self.url, d)
            self.assertEqual(sorted(p.name for p in pathlib.Path(d).iterdir()), sorted(NAMES))
            for name in NAMES:self.assertEqual(pathlib.Path(d,name).read_bytes(), Handler.template)
            self.assertLess(report['downloaded_bytes'], len(Handler.data)//4)

    def test_transient_504_retries(self):
        Handler.fail_once = True
        with tempfile.TemporaryDirectory() as d:
            report = install(self.url, d, retry_delay=0)
            self.assertEqual(len(report['files']), 2)

    def test_full_body_response_rejected(self):
        Handler.ignore_range = True
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaises(ValueError):install(self.url, d, attempts=1)
            self.assertEqual(list(pathlib.Path(d).iterdir()), [])

    def test_crc_error_preserves_existing_files(self):
        with zipfile.ZipFile(io.BytesIO(Handler.data)) as z:
            info = z.getinfo('templates/'+NAMES[1])
            offset = info.header_offset+30+len(info.filename.encode())+len(info.extra)
        corrupt = bytearray(Handler.data);corrupt[offset] ^= 1;Handler.data = bytes(corrupt)
        with tempfile.TemporaryDirectory() as d:
            for name in NAMES:pathlib.Path(d,name).write_bytes(b'existing')
            with self.assertRaises(zipfile.BadZipFile):install(self.url, d)
            for name in NAMES:self.assertEqual(pathlib.Path(d,name).read_bytes(), b'existing')


if __name__ == '__main__':unittest.main()
