"""Trusted-touch battle interruption acceptance; simulate focus, never combat state."""
import argparse, asyncio, functools, http.server, json, os, pathlib, threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--directory',default=str(ROOT/'godot/export/lab'));p.add_argument('--report-dir',type=pathlib.Path,default=ROOT/'docs/playtest-r1/focus-browser');args=p.parse_args();args.report_dir.mkdir(parents=True,exist_ok=True)
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=args.directory));threading.Thread(target=server.serve_forever,daemon=True).start()
async def main():
 results={}
 async with async_playwright() as pw:
  browser=await pw.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  try:
   for direction,size in [('landscape',{'width':1180,'height':820}),('portrait',{'width':820,'height':1180})]:
    context=await browser.new_context(viewport=size,has_touch=True,device_scale_factor=1);page=await context.new_page();errors=[];logs=[]
    page.on('pageerror',lambda error:errors.append(str(error)));page.on('console',lambda message:logs.append(message.text))
    await page.goto(f'http://127.0.0.1:{server.server_port}/index.html?debug=1&seed=12032')
    await page.wait_for_function('window.SG_LAB_STATE?.enemies>0 && window.SG_LAB_STATE.casts>0',timeout=60000)
    async def state():return await page.evaluate('window.SG_LAB_STATE')
    async def tap(key):
     s=await state();x,y,w,h=s['buttons'][key];vw,vh=s['viewport'];rect=await page.locator('#canvas').bounding_box()
     assert 0<=x-w/2<x+w/2<=vw+1 and 0<=y-h/2<y+h/2<=vh+1
     assert w/vw*rect['width']>=44 and h/vh*rect['height']>=44
     await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height']);await page.wait_for_timeout(350)
    async def blur():
     await page.evaluate("document.getElementById('canvas').blur();window.dispatchEvent(new Event('blur'))")
     await page.wait_for_timeout(350)
    async def focus():
     await page.locator('#canvas').focus();await page.evaluate("window.dispatchEvent(new Event('focus'))");await page.wait_for_timeout(350)
    await blur();await page.wait_for_function('window.SG_LAB_STATE.paused')
    paused=await state();await focus();await page.wait_for_timeout(700);held=await state()
    assert held['paused'] and all(held[k]==paused[k] for k in ['combat_seconds','hp','wall_hp','casts','kills','slots','edges'])
    await page.screenshot(path=str(args.report_dir/f'paused-{direction}.png'))
    await tap('Pause');await page.wait_for_function('clock => !window.SG_LAB_STATE.paused && window.SG_LAB_STATE.combat_seconds>clock+0.5',arg=held['combat_seconds'],timeout=10000)
    resumed=await state()
    await tap('Configure');editing=await state();assert editing['edit_open'] and not editing['paused']
    await blur();await focus();modal=await state();assert modal['edit_open'] and not modal['paused'] and modal['slots']==editing['slots'] and modal['edges']==editing['edges']
    await tap('Done');await tap('Pause');await blur();await focus();assert (await state())['paused']
    await tap('Pause');assert not (await state())['paused']
    engine=[line for line in logs if 'SCRIPT ERROR' in line or line.startswith('ERROR:')];assert not errors and not engine,(errors,engine)
    results[direction]={'paused':paused,'held':held,'resumed':resumed,'modal':modal,'pageerrors':errors,'engine_errors':engine,'passed':['real live battle pauses on focus loss','focus return never resumes clock, damage or casting','trusted continue resumes existing battle','editor interruption preserves manual pause state and graph','manual pause survives focus round trip','44 CSS pixel controls'],'limit':'Chromium simulated blur/focus, not iPad App switching or OS suspension.'}
    print(direction,'FOCUS PAUSE PASS',flush=True);await context.close()
  finally:await browser.close();server.shutdown()
 (args.report_dir/'focus-pause-web.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
asyncio.run(main())
