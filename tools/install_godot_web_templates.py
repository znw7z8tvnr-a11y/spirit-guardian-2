"""Install only official single-thread Web templates using validated ZIP ranges.

The upstream TPZ is over 1 GB. zipfile seeks its directory and the two selected
entries through this read-only adapter; no full-archive fallback is performed.
"""
import argparse
from collections import OrderedDict
import hashlib
import io
import json
import pathlib
import re
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile

NAMES = ('web_nothreads_debug.zip', 'web_nothreads_release.zip')


class RangeReader(io.RawIOBase):
    def __init__(self, url, attempts=3, retry_delay=1, progress=False):
        super().__init__()
        self.url = url
        self.attempts = attempts
        self.retry_delay = retry_delay
        self.progress = progress
        self.blocks = OrderedDict()
        self.position = 0
        self.transferred = 0
        self.size = None
        self._range(0, 0)

    def _range(self, start, end):
        for attempt in range(self.attempts):
            # A fresh official redirect avoids caching an upstream 504 or a
            # different Range response. Signed redirect URLs are never logged.
            separator = '&' if '?' in self.url else '?'
            url = self.url + separator + urllib.parse.urlencode(
                {'sg_range': f'{start}-{end}-{time.time_ns()}'})
            request = urllib.request.Request(url, headers={
                'Range': f'bytes={start}-{end}', 'Accept-Encoding': 'identity',
                'User-Agent': 'SpiritGuardian-WebTemplateInstaller/1'})
            try:
                if self.progress:
                    print(f'Reading official ZIP bytes {start}-{end} (attempt {attempt+1})', file=sys.stderr, flush=True)
                with urllib.request.urlopen(request, timeout=60) as response:
                    if response.status != 206:
                        raise ValueError('Server must support partial responses')
                    match = re.fullmatch(r'bytes (\d+)-(\d+)/(\d+)',
                                         response.headers.get('Content-Range', ''))
                    if not match:
                        raise ValueError('Missing or invalid Content-Range')
                    first, last, total = map(int, match.groups())
                    if (first, last) != (start, end) or total <= end:
                        raise ValueError('Content-Range does not match request')
                    if self.size is not None and total != self.size:
                        raise ValueError('Archive size changed during download')
                    self.size = total
                    expected = end - start + 1
                    data = response.read(expected + 1)
                    if len(data) != expected:
                        raise ValueError('Partial response length mismatch')
                    self.transferred += len(data)
                    return data
            except urllib.error.HTTPError as error:
                if error.code not in {408,425,429,500,502,503,504}:
                    raise
                if attempt + 1 == self.attempts:
                    raise
                retry_after = error.headers.get('Retry-After', '')
                delay = float(retry_after) if retry_after.isdigit() else self.retry_delay * 2**attempt
                time.sleep(min(30, delay))
            except (urllib.error.URLError, TimeoutError, ConnectionError, ValueError):
                if attempt + 1 == self.attempts:
                    raise
                time.sleep(self.retry_delay * 2**attempt)

    def readable(self):
        return True

    def seekable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=0):
        target = offset if whence == 0 else self.position + offset if whence == 1 else self.size + offset
        if target < 0:
            raise ValueError('Negative archive offset')
        self.position = target
        return target

    def read(self, size=-1):
        length = max(0, self.size-self.position) if size < 0 else min(size, max(0, self.size-self.position))
        if length > 64*1024*1024:
            raise ValueError('Unexpected large ZIP read; refusing full archive')
        parts = []
        while length:
            block_size = 4*1024*1024
            start = self.position//block_size*block_size
            if start not in self.blocks:
                self.blocks[start] = self._range(start, min(self.size-1, start+block_size-1))
                if len(self.blocks) > 4:
                    self.blocks.popitem(last=False)
            self.blocks.move_to_end(start)
            block = self.blocks[start]
            offset = self.position-start
            count = min(length, len(block)-offset)
            if count <= 0:
                raise ValueError('Invalid cached ZIP block')
            parts.append(block[offset:offset+count])
            self.position += count
            length -= count
        return b''.join(parts)


def install(url, destination, **reader_options):
    destination = pathlib.Path(destination)
    destination.mkdir(parents=True, exist_ok=True)
    results = []
    with RangeReader(url, **reader_options) as remote, zipfile.ZipFile(remote) as archive:
        # Validate both files before replacing any existing installation.
        with tempfile.TemporaryDirectory(prefix='.web-templates-', dir=destination) as temporary:
            for name in NAMES:
                info = archive.getinfo('templates/'+name)
                if info.file_size > 64*1024*1024 or info.compress_size > 64*1024*1024:
                    raise ValueError('Unexpected Web template entry size')
                data = archive.read(info)  # zipfile validates the entry CRC.
                with zipfile.ZipFile(io.BytesIO(data)) as inner:
                    if inner.testzip() is not None:
                        raise ValueError('Corrupt inner Web template ZIP')
                pathlib.Path(temporary, name).write_bytes(data)
                results.append({'name': name, 'bytes': len(data),
                                'sha256': hashlib.sha256(data).hexdigest()})
            for name in NAMES:
                pathlib.Path(temporary, name).replace(destination/name)
        return {'archive_bytes': remote.size, 'downloaded_bytes': remote.transferred,
                'files': results, 'source': 'official Godot release TPZ, selected entry CRCs validated'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', required=True)
    parser.add_argument('--directory', required=True)
    args = parser.parse_args()
    if not re.fullmatch(r'\d+\.\d+\.\d+', args.version):
        parser.error('Expected pinned x.y.z Godot version')
    source = ('https://github.com/godotengine/godot-builds/releases/download/'
              f'{args.version}-stable/Godot_v{args.version}-stable_export_templates.tpz')
    print(json.dumps(install(source, args.directory, progress=True), indent=2))
