"""TLS-verified asset check for the existing private Site; header only via stdin."""
import hashlib,json,pathlib,sys,termios,time,urllib.parse,urllib.request
settings=termios.tcgetattr(0);settings[3]&=~termios.ECHO;termios.tcsetattr(0,termios.TCSANOW,settings)
print('Ready for private verification headers on stdin (input is hidden).',flush=True)
headers=json.loads(sys.stdin.readline());origin='https://spirit-guardian-m2-play.trylook.chatgpt.site/'
root=pathlib.Path('/workspace/sites/spirit-guardian-m2-play/dist');cache={};verification_stamp=str(time.time_ns())
def get(url):
 if url not in cache:
  with urllib.request.urlopen(urllib.request.Request(url+("&" if "?" in url else "?")+"verify="+verification_stamp,headers=headers),timeout=60) as response:
   assert response.status==200;cache[url]=response.read()
 return cache[url]
results={}
for entry in ['', 'lab/']:
 base=urllib.parse.urljoin(origin,entry);assert b'wasm-stream.js' in get(base)
 assert get(base)==(root/entry/'index.html').read_bytes()
 assert get(urllib.parse.urljoin(base,'wasm-stream.js'))==(root/entry/'wasm-stream.js').read_bytes()
 info=json.loads(get(urllib.parse.urljoin(base,'build-info.json')))
 local=json.loads((root/entry/'build-info.json').read_text());assert info==local
 digest=hashlib.sha256()
 for part in info['chunks']:
  raw=get(urllib.parse.urljoin(base,part['file']));assert hashlib.sha256(raw).hexdigest()==part['sha256'];digest.update(raw)
 assert digest.hexdigest()==info['wasm_sha256']
 assert hashlib.sha256(get(urllib.parse.urljoin(base,'index.pck'))).digest()==hashlib.sha256((root/entry/'index.pck').read_bytes()).digest()
 results[entry or '/']={'html_status':200,'source_commit':info['source_commit'],'wasm_verified':True,'pck_matches_local':True}
assert results['/']['source_commit']=='b8d77143c0815fe79eeea26e542abbe7b23460a2'
report={'url':origin+'lab/','entries':results,'tls_verified':True,'limit':'HTTP integrity, not remote browser interaction. Local WebGL touch tests are separate; no iPad/Safari claim.'}
(pathlib.Path(__file__).resolve().parents[2]/'docs/timing-gem/live-assets.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report),flush=True)
