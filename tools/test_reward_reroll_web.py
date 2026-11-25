"""Actual earned reward refresh and same-origin reload; no gameplay injection."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1];REPORT=ROOT/'docs/reward-reroll';REPORT.mkdir(exist_ok=True)
p=argparse.ArgumentParser();p.add_argument('--directory',default=str(ROOT/'godot/export/lab'));p.add_argument('--entry',default='/');p.add_argument('--label',default='web');args=p.parse_args()
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=args.directory));threading.Thread(target=server.serve_forever,daemon=True).start()
def signature(rows):return sorted((r['kind'],r['key'],int(r['level'])) for r in rows)
async def main():
 results={}
 async with async_playwright() as pw:
  browser=await pw.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  try:
   for name,size in [('landscape',{'width':1180,'height':820}),('portrait',{'width':820,'height':1180})]:
    context=await browser.new_context(viewport=size,has_touch=True,device_scale_factor=1);page=await context.new_page();errors=[];logs=[]
    page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:logs.append(m.text))
    await page.goto(f'http://127.0.0.1:{server.server_port}{args.entry}?debug=1&seed=12032')
    async def state():return await page.evaluate('window.SG_LAB_STATE')
    async def wait(condition,timeout=70000):await page.wait_for_function(condition,timeout=timeout)
    async def tap(key):
     s=await state();rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport'];assert 0<=x-w/2 and x+w/2<=vw+1 and 0<=y-h/2 and y+h/2<=vh+1,(key,s['buttons'][key],s['viewport'])
     assert w/vw*rect['width']>=44 and h/vh*rect['height']>=44,(key,w,h)
     await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height']);await page.wait_for_timeout(350)
    await wait('window.SG_LAB_STATE!==undefined');await page.wait_for_timeout(650)
    for speed in [2,4,8]:await tap('Speed');assert (await state())['speed']==speed
    await wait('window.SG_LAB_STATE.wave===3&&window.SG_LAB_STATE.reward_pending===1&&window.SG_LAB_STATE.checkpoint_wave===3')
    before=await state()
    rect=await page.locator('#canvas').bounding_box();vw,vh=before['viewport']
    for key in ['RewardRefresh','Reward 0']:
     x,y,w,h=before['buttons'][key]
     await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height'])
    await page.wait_for_timeout(350);after=await state()
    assert signature(before['reward_offers'])!=signature(after['reward_offers']) and after['reward_refreshes']==before['reward_refreshes']-1
    assert sorted(x['kind'] for x in after['reward_offers'])==['affix','gem','skill'] and next(x for x in after['reward_offers'] if x['kind']=='gem')['key']=='relay'
    assert after['item_count']==before['item_count']==1 and after['reward_pending']==1 and after['reward_granted']==0 and after['combat_seconds']==before['combat_seconds']
    await tap('RewardRefresh');spent=await state();assert spent['reward_offers']==after['reward_offers'] and spent['reward_refreshes']==0
    await page.screenshot(path=str(REPORT/f'refreshed-{args.label}-{name}.png'))
    await page.reload();await wait('window.SG_LAB_STATE?.resume_pending===true');await tap('CheckpointResume');restored=await state()
    assert restored['reward_offers']==after['reward_offers'] and restored['reward_refreshes']==0 and restored['reward_granted']==0 and restored['reward_pending']==1
    await tap('RewardRefresh');assert (await state())['reward_offers']==restored['reward_offers']
    pick=next(i for i,r in enumerate(restored['reward_offers']) if r['kind']=='gem');await tap(f'Reward {pick}');owned=await state()
    assert owned['item_count']==2 and owned['reward_granted']==1 and owned['reward_pending']==0 and owned['edit_open']
    await page.reload();await wait('window.SG_LAB_STATE?.resume_pending===true');await tap('CheckpointResume');final=await state()
    assert final['item_count']==2 and final['reward_granted']==1 and final['reward_pending']==0
    engine=[x for x in logs if 'SCRIPT ERROR' in x or x.startswith('ERROR:')];assert not errors and not engine,(errors,engine)
    results[name]={'before':before,'refreshed':after,'restored':restored,'final':final,'pageerrors':errors,'engine_errors':engine,'passed':['real third-wave reward changes content with one refresh','three categories and starter relay guarantee retained','no item grant or combat advance during refresh','spent charge cannot roll again','new offers and spent budget survive near-immediate page reload','one earned gem remains single after a second reload','44 CSS pixel controls fit viewport'],'limit':'Seeded normal Chromium touch playthrough per orientation, not iPad Safari hardware or a rarity-upgrade guarantee.'}
    print(name,'REWARD REROLL PASS',flush=True);await context.close()
  finally:await browser.close();server.shutdown()
 (REPORT/f'browser-{args.label}.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
asyncio.run(main())
