"""Exercise the actual static Godot build, including the chunked wasm loader."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading,sys
from playwright.async_api import async_playwright
p=argparse.ArgumentParser();p.add_argument('--directory');p.add_argument('--url');p.add_argument('--report',required=True);p.add_argument('--read-auth',action='store_true');args=p.parse_args()
headers={}
if args.read_auth:
 import termios
 config=termios.tcgetattr(0);config[3]&=~termios.ECHO;termios.tcsetattr(0,termios.TCSANOW,config)
 print('Ready for private QA headers on stdin (input is hidden).',flush=True)
 headers=json.loads(sys.stdin.readline())
if args.directory:
 server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=args.directory));threading.Thread(target=server.serve_forever,daemon=True).start();base=f'http://127.0.0.1:{server.server_port}/'
else:base=args.url
report=pathlib.Path(args.report);report.parent.mkdir(parents=True,exist_ok=True)
async def main():
 result={}
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  for label,size in [('landscape',{'width':1180,'height':820}),('portrait',{'width':820,'height':1180})]:
   page=await browser.new_page(viewport=size,has_touch=True,extra_http_headers=headers)
   errors=[];logs=[];responses=[]
   page.on('pageerror',lambda e:errors.append(str(e)))
   page.on('console',lambda m:logs.append({'type':m.type,'text':m.text}))
   page.on('response',lambda r:responses.append({'path':r.url.split('?')[0].rsplit('/',1)[-1],'status':r.status}))
   await page.goto(base+'?debug=1',timeout=60000)
   await page.wait_for_function('window.SG_M1_STATE?.enemies > 0',timeout=90000)
   async def state():return await page.evaluate('window.SG_M1_STATE')
   async def tap(key):
    s=await state();b=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport']
    await page.touchscreen.tap(b['x']+x/vw*b['width'],b['y']+y/vh*b['height']);await page.wait_for_timeout(500)
   initial=await state()
   await page.screenshot(path=str(report.parent/(label+'-game.png')))
   await tap('Pause');assert (await state())['paused']
   await tap('Pause');assert not (await state())['paused']
   await tap('1x');assert (await state())['speed']==2
   await tap('Ice');assert (await state())['element']=='ice'
   await tap('Chain');assert (await state())['graph_open']
   nodes=(await state())['nodes'];await tap('Add');assert (await state())['nodes']==nodes+1
   await tap('Undo');assert (await state())['nodes']==nodes
   await page.screenshot(path=str(report.parent/(label+'-graph.png')))
   await tap('Done');assert not (await state())['graph_open']
   await tap('Audio: off');await page.wait_for_timeout(1200);await tap('Audio: off')
   await tap('Restart');await page.wait_for_timeout(500)
   final=await state();assert final['speed']==1 and final['element']=='fire' and final['nodes']==nodes
   runtime_errors=[x for x in logs if 'SCRIPT ERROR' in x['text'] or x['text'].startswith('ERROR:')]
   assert not errors and not runtime_errors,(errors,runtime_errors)
   parts=[x for x in responses if x['path'].startswith('index.wasm.part')];assert len(parts)==3 and all(x['status']==200 for x in parts),parts
   result[label]={'initial':initial,'final':final,'wasm_parts':parts,'pageerrors':errors,'engine_errors':runtime_errors,'passed':['split-wasm WebGL boot','enemy spawns','pause/resume','speed','spell selection','graph add/undo','build save/restart','audio toggle without runtime errors'],'limit':'Linux Chromium software WebGL with touch emulation; iPad Safari unverified'}
   await page.close()
  await browser.close()
 report.write_text(json.dumps(result,ensure_ascii=False,indent=2));print(json.dumps({k:v['passed'] for k,v in result.items()},indent=2),flush=True)
asyncio.run(main())
