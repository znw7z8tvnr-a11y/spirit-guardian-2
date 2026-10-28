"""Actual exported Godot WebGL smoke; Chromium touch emulation is not Safari."""
import asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1]
REPORT=ROOT/'docs/m2'
REPORT.mkdir(parents=True,exist_ok=True)
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(ROOT/'godot/export/web')))
threading.Thread(target=server.serve_forever,daemon=True).start()
async def main():
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  results={}
  for label,size in [('landscape',{'width':1180,'height':820}),('portrait',{'width':820,'height':1180})]:
   page=await browser.new_page(viewport=size,has_touch=True,device_scale_factor=1)
   errors=[]; logs=[]
   page.on('pageerror',lambda e:errors.append(str(e)))
   page.on('console',lambda m:(logs.append({'type':m.type,'text':m.text}),print(m.type,m.text,flush=True)))
   await page.goto(f'http://127.0.0.1:{server.server_port}/index.html?debug=1')
   await page.wait_for_function('window.SG_M1_STATE !== undefined',timeout=45000)
   print('BOOT_STATE',await page.evaluate('window.SG_M1_STATE'),flush=True)
   await page.wait_for_timeout(5000)
   async def state():return await page.evaluate('window.SG_M1_STATE')
   async def tap(key):
    s=await state();rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport']
    await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height'])
    await page.wait_for_timeout(500)
   if (await state())['paused']:
    await tap('Pause')
   await page.wait_for_function('window.SG_M1_STATE?.enemies > 0',timeout=30000)
   initial=await state()
   await tap('Pause');paused=await state();assert paused['paused'],paused
   await tap('Pause');assert not (await state())['paused']
   await tap('1x');assert (await state())['speed']==2
   await tap('Chain');assert (await state())['graph_open']
   before=(await state())['nodes']
   await page.screenshot(path=str(REPORT/('graph-before-'+label+'.png')))
   print('GRAPH_STATE',await state(),flush=True)
   await tap('Add');assert (await state())['nodes']==before+1
   await tap('Undo');assert (await state())['nodes']==before
   await tap('Redo');assert (await state())['nodes']==before+1
   await page.screenshot(path=str(REPORT/('graph-'+label+'.png')))
   await tap('Done');assert not (await state())['graph_open']
   await tap('Ice');assert (await state())['element']=='ice'
   await tap('Arcane');assert (await state())['element']=='arcane'
   await page.screenshot(path=str(REPORT/('godot-web-'+label+'.png')))
   await tap('Restart');await page.wait_for_timeout(800);restarted=await state();assert restarted['speed']==1 and restarted['element']=='fire' and restarted['hp']==100 and restarted['nodes']==before+1
   assert not errors,errors
   engine_errors=[v for v in logs if 'SCRIPT ERROR' in v['text'] or v['text'].startswith('ERROR:')]
   assert not engine_errors,engine_errors
   results[label]={'viewport':size,'initial':initial,'restart':restarted,'pageerrors':errors,'console':logs,'passed':['WebGL boot','spawns','touch pause/resume','touch speed','touch ice/arcane selection','touch restart','graph modal','touch add/undo/redo','build save and scene reload'],'limitations':'Software WebGL on Linux Chromium; no Safari/device performance claim'}
   await page.close()
  await browser.close()
  (REPORT/'web-smoke.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print(json.dumps({k:v['passed'] for k,v in results.items()},indent=2))
asyncio.run(main())
