"""Actual touch + same-origin page reload; no gameplay state injection."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1]; REPORT=ROOT/'docs/checkpoint';REPORT.mkdir(exist_ok=True)
p=argparse.ArgumentParser();p.add_argument('--directory',default=str(ROOT/'godot/export/lab'));p.add_argument('--entry',default='/');p.add_argument('--label',default='web');args=p.parse_args()
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=args.directory));threading.Thread(target=server.serve_forever,daemon=True).start()
async def main():
 results={}
 async with async_playwright() as pw:
  browser=await pw.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  try:
   for orientation,size in [('landscape',{'width':1180,'height':820}),('portrait',{'width':820,'height':1180})]:
    context=await browser.new_context(viewport=size,has_touch=True,device_scale_factor=1);page=await context.new_page();errors=[];logs=[]
    page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:logs.append(m.text))
    await page.goto(f'http://127.0.0.1:{server.server_port}{args.entry}?debug=1&seed=12032')
    async def ready():await page.wait_for_function('window.SG_LAB_STATE!==undefined',timeout=60000)
    async def state():return await page.evaluate('window.SG_LAB_STATE')
    async def tap(key):
     s=await state();rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport'];assert 0<=x-w/2<x+w/2<=vw+1 and 0<=y-h/2<y+h/2<=vh+1,(key,[x,y,w,h],s['viewport'])
     await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height']);await page.wait_for_timeout(350)
    async def reload():
     await page.wait_for_timeout(1500);await page.reload();await ready();await page.wait_for_timeout(500)
    await ready();await page.wait_for_timeout(1000);assert not (await state())['resume_pending']
    for speed in [2,4,8]:await tap('Speed');assert (await state())['speed']==speed
    await page.wait_for_function('window.SG_LAB_STATE.wave===3&&window.SG_LAB_STATE.reward_pending===1&&window.SG_LAB_STATE.checkpoint_wave===3',timeout=70000)
    await tap('RewardRefresh');saved=await state();assert saved['reward_refreshes']==0 and saved['userfs_persistent']
    await reload();prompt=await state();assert prompt['resume_pending'] and prompt['combat_seconds']==0
    await page.screenshot(path=str(REPORT/f'continue-{args.label}-{orientation}.png'))
    await tap('CheckpointResume');restored=await state()
    assert not restored['resume_pending'] and restored['wave']==3 and restored['reward_pending']==1 and restored['reward_refreshes']==0
    assert restored['reward_offers']==saved['reward_offers'] and restored['kills']==saved['kills'] and restored['growth_levels']==saved['growth_levels'] and restored['wall_hp']==saved['wall_hp']
    pick=next(i for i,v in enumerate(restored['reward_offers']) if v['kind']=='gem');await tap(f'Reward {pick}');owned=await state();assert owned['item_count']==2 and owned['reward_granted']==1 and owned['edit_open']
    await tap('Random');equipped=await state();assert equipped['slots'][1]>=0 and len(equipped['edges'])==1
    await reload();assert (await state())['resume_pending'];await tap('CheckpointResume');second=await state()
    assert second['reward_pending']==0 and second['reward_granted']==1 and second['item_count']==2 and second['edit_open'] and second['slots']==equipped['slots'] and second['edges']==equipped['edges']
    await page.screenshot(path=str(REPORT/f'equipment-{args.label}-{orientation}.png'))
    await reload();await tap('CheckpointNew');await page.wait_for_function('window.SG_LAB_STATE.resume_pending===false&&window.SG_LAB_STATE.item_count===1&&window.SG_LAB_STATE.wave<3',timeout=15000)
    fresh=await state();assert fresh['reward_granted']==0 and fresh['speed']==1
    await reload();assert not (await state())['resume_pending']
    engine=[v for v in logs if 'SCRIPT ERROR' in v or v.startswith('ERROR:')];assert not errors and not engine,(errors,engine)
    results[orientation]={'passed':['real wave-three autosave','spent refresh and exact offers survive page reload','health and growth preserved','earned gem and arranged graph survive second reload','no repeated award','explicit new-run clears checkpoint'],'saved':saved,'restored':restored,'second':second,'pageerrors':errors,'engine_errors':engine,'limits':'Chromium WebGL local storage; not iPad Safari hardware or sudden OS termination. Saves safe intermissions, not active combat.'}
    print(orientation,'CHECKPOINT PASS',flush=True);await context.close()
  finally:await browser.close();server.shutdown()
 (REPORT/f'browser-{args.label}.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
asyncio.run(main())
