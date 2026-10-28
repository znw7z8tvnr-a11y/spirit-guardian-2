"""Prepare unchanged CI Godot game for a static host with per-file size limits."""
import argparse,hashlib,io,json,pathlib,zipfile
p=argparse.ArgumentParser();p.add_argument('artifact');p.add_argument('site_directory');args=p.parse_args()
root=pathlib.Path(args.site_directory);out=root/'dist';out.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(args.artifact) as z:
 web=z.read('dist/SpiritGuardian-Web-M2.zip')
with zipfile.ZipFile(io.BytesIO(web)) as z:
 for name in z.namelist():
  if pathlib.PurePosixPath(name).name!=name:raise ValueError('Unexpected export path')
  (out/name).write_bytes(z.read(name))
wasm=out/'index.wasm';data=wasm.read_bytes();chunks=[]
for i,start in enumerate(range(0,len(data),12*1024*1024)):
 name=f'index.wasm.part{i:02d}.bin';part=data[start:start+12*1024*1024];(out/name).write_bytes(part);chunks.append({'file':name,'bytes':len(part),'sha256':hashlib.sha256(part).hexdigest()})
manifest={'source_repository':'znw7z8tvnr-a11y/spirit-guardian-2','source_commit':'831d14318f02e526d3bb174fa83abfc8b01ed2a3','workflow_run':40721247540,'artifact_id':12830312750,'web_zip_sha256':hashlib.sha256(web).hexdigest(),'wasm_bytes':len(data),'wasm_sha256':hashlib.sha256(data).hexdigest(),'chunks':chunks}
(out/'build-info.json').write_text(json.dumps(manifest,indent=2))
# Reconstruct a streaming Response so Godot can keep its original wasm filename,
# progress handling and instantiateStreaming. No game GDScript/PCK changes.
loader='''(() => {\n  const nativeFetch = window.fetch.bind(window);\n  const base = new URL('.', document.currentScript.src);\n  const names = CHUNKS;\n  const size = TOTAL;\n  window.fetch = async function(input, init) {\n    const url = new URL(input instanceof Request ? input.url : String(input), location.href);\n    if (url.href !== new URL('index.wasm', base).href) return nativeFetch(input, init);\n    let cancelled = false;\n    let reader = null;\n    const body = new ReadableStream({\n      async start(controller) {\n        try {\n          for (const name of names) {\n            if (cancelled) return;\n            const response = await nativeFetch(new URL(name, base), init);\n            if (!response.ok) throw new Error('Game download failed: ' + response.status);\n            reader = response.body.getReader();\n            while (!cancelled) {\n              const {done, value} = await reader.read();\n              if (done) break;\n              controller.enqueue(value);\n            }\n          }\n          if (!cancelled) controller.close();\n        } catch (error) { if (!cancelled) controller.error(error); }\n      },\n      cancel() { cancelled = true; if (reader) return reader.cancel(); }\n    });\n    return new Response(body, {status: 200, headers: {'Content-Type':'application/wasm', 'Content-Length':String(size)}});\n  };\n})();\n'''.replace('CHUNKS',json.dumps([x['file'] for x in chunks])).replace('TOTAL',str(len(data)))
(out/'wasm-stream.js').write_text(loader)
html=(out/'index.html').read_text();needle='<script src="index.js"></script>'
if html.count(needle)!=1:raise ValueError('Unexpected Godot loader layout')
html=html.replace(needle,'<script src="wasm-stream.js"></script>\n'+needle).replace('<html lang="en">','<html lang="zh-Hant">').replace('<title>Spirit Guardian — Modules M2</title>','<title>靈境守衛 Spirit Guardian｜M2 試玩</title>')
(out/'index.html').write_text(html);wasm.unlink()
assert hashlib.sha256(b''.join((out/x['file']).read_bytes() for x in chunks)).hexdigest()==manifest['wasm_sha256']
assert max(p.stat().st_size for p in out.iterdir())<25*1024*1024
(root/'README.md').write_text('# Spirit Guardian M2 playtest\n\nStatic deployment of validated GitHub Actions run 40721247540, commit 831d143.\nOriginal site remains at https://znw7z8tvnr-a11y.github.io/spirit-guardian-2/ .\nGame art is temporary. Only chain builds are saved; full run save and complete module parity remain pending.\nThe wasm file is streamed from size-limited chunks without modifying its bytes or the game PCK.\n')
print(json.dumps({'directory':str(out),'wasm_bytes':len(data),'parts':len(chunks),'wasm_sha256':manifest['wasm_sha256']},indent=2))
