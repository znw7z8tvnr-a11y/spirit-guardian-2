"""Prepare unchanged CI Godot game for a static host with per-file size limits."""
import argparse,hashlib,io,json,pathlib,zipfile
p=argparse.ArgumentParser();p.add_argument('artifact');p.add_argument('site_directory');p.add_argument('--source-commit', required=True);p.add_argument('--web-zip',action='store_true');p.add_argument('--subdir',default='');args=p.parse_args()
if args.subdir not in ['', 'lab']:raise ValueError('Unsupported subdirectory')
root=pathlib.Path(args.site_directory);out=root/'dist'/args.subdir;out.mkdir(parents=True,exist_ok=True)
if args.web_zip:
 web=pathlib.Path(args.artifact).read_bytes()
else:
 with zipfile.ZipFile(args.artifact) as z:
  web=z.read('dist/SpiritGuardian-Web-M2.1-zh-Hant.zip')
with zipfile.ZipFile(io.BytesIO(web)) as z:
 for name in z.namelist():
  if pathlib.PurePosixPath(name).name!=name:raise ValueError('Unexpected export path')
  (out/name).write_bytes(z.read(name))
wasm=out/'index.wasm';data=wasm.read_bytes();chunks=[]
for i,start in enumerate(range(0,len(data),12*1024*1024)):
 name=f'index.wasm.part{i:02d}.bin';part=data[start:start+12*1024*1024];(out/name).write_bytes(part);chunks.append({'file':name,'bytes':len(part),'sha256':hashlib.sha256(part).hexdigest()})
# The lab may reuse byte-identical existing engine chunks without changing M2.1.
if args.subdir=='lab' and (root/'dist/build-info.json').exists():
 stable=json.loads((root/'dist/build-info.json').read_text())
 if stable['wasm_sha256']==hashlib.sha256(data).hexdigest():
  for part in chunks:
   shared=root/'dist'/part['file']
   if hashlib.sha256(shared.read_bytes()).hexdigest()!=part['sha256']:raise ValueError('Stable engine digest mismatch')
   (out/part['file']).unlink();part['file']='../'+part['file']
manifest={'source_repository':'znw7z8tvnr-a11y/spirit-guardian-2','source_commit':args.source_commit,'build_origin':'locally exported with Godot 4.6.3; native and browser tests recorded in docs/m2-1','entrypoint':args.subdir or '/', 'web_zip_sha256':hashlib.sha256(web).hexdigest(),'wasm_bytes':len(data),'wasm_sha256':hashlib.sha256(data).hexdigest(),'chunks':chunks}
if args.subdir=='lab':manifest['build_origin']='Godot 4.6.3 Chain Lab export; checks in docs/chain-tree'
(out/'build-info.json').write_text(json.dumps(manifest,indent=2))
# Reconstruct a streaming Response so Godot can keep its original wasm filename,
# progress handling and instantiateStreaming. No game GDScript/PCK changes.
loader='''(() => {\n  const nativeFetch = window.fetch.bind(window);\n  const base = new URL('.', document.currentScript.src);\n  const names = CHUNKS;\n  const size = TOTAL;\n  window.fetch = async function(input, init) {\n    const url = new URL(input instanceof Request ? input.url : String(input), location.href);\n    if (url.href !== new URL('index.wasm', base).href) return nativeFetch(input, init);\n    let cancelled = false;\n    let reader = null;\n    const body = new ReadableStream({\n      async start(controller) {\n        try {\n          for (const name of names) {\n            if (cancelled) return;\n            const response = await nativeFetch(new URL(name, base), init);\n            if (!response.ok) throw new Error('Game download failed: ' + response.status);\n            reader = response.body.getReader();\n            while (!cancelled) {\n              const {done, value} = await reader.read();\n              if (done) break;\n              controller.enqueue(value);\n            }\n          }\n          if (!cancelled) controller.close();\n        } catch (error) { if (!cancelled) controller.error(error); }\n      },\n      cancel() { cancelled = true; if (reader) return reader.cancel(); }\n    });\n    return new Response(body, {status: 200, headers: {'Content-Type':'application/wasm', 'Content-Length':String(size)}});\n  };\n})();\n'''.replace('CHUNKS',json.dumps([x['file'] for x in chunks])).replace('TOTAL',str(len(data)))
(out/'wasm-stream.js').write_text(loader)
html=(out/'index.html').read_text();needle='<script src="index.js"></script>'
if html.count(needle)!=1:raise ValueError('Unexpected Godot loader layout')
html=html.replace(needle,'<script src="wasm-stream.js"></script>\n'+needle).replace('<html lang="en">','<html lang="zh-Hant">').replace('<title>Spirit Guardian — Modules M2</title>','<title>靈境守衛 Spirit Guardian｜M2.1 觸控試玩</title>')
if args.subdir=='lab':html=html.replace('M2.1 觸控試玩','連鎖戰鬥試驗室')
(out/'index.html').write_text(html);wasm.unlink()
assert hashlib.sha256(b''.join((out/x['file']).read_bytes() for x in chunks)).hexdigest()==manifest['wasm_sha256']
assert max(p.stat().st_size for p in out.iterdir())<25*1024*1024
(root/('LAB.md' if args.subdir else 'README.md')).write_text('# Spirit Guardian M2 playtest\n\nTraditional Chinese build. Source commit is recorded in dist/build-info.json; local export and test evidence are recorded in the GitHub source repository docs/m2-1/.\nOriginal site remains at https://znw7z8tvnr-a11y.github.io/spirit-guardian-2/ .\nGame art is temporary. Only chain builds are saved; full run save and complete module parity remain pending.\nThe wasm file is streamed from size-limited chunks without modifying its bytes or the game PCK.\n')
print(json.dumps({'directory':str(out),'wasm_bytes':len(data),'parts':len(chunks),'wasm_sha256':manifest['wasm_sha256']},indent=2))
