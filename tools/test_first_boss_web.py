"""Real touch playthrough: earned gear, first Boss, summons, loadout and next wave."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1];REPORT=ROOT/'docs/eight-spells';REPORT.mkdir(exist_ok=True,parents=True)
p=argparse.ArgumentParser();p.add_argument('--directory',default=str(ROOT/'godot/export/lab'));p.add_argument('--entry',default='/');args=p.parse_args()
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=args.directory));threading.Thread(target=server.serve_forever,daemon=True).start()
async def main():
 results={}
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  for name,size in [('landscape',{'width':1180,'height':820}),('portrait',{'width':820,'height':1180})]:
   page=await browser.new_page(viewport=size,has_touch=True,device_scale_factor=1);errors=[];logs=[]
   page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:logs.append(m.text))
   await page.goto(f'http://127.0.0.1:{server.server_port}{args.entry}?debug=1&seed=12032');await page.wait_for_function('window.SG_LAB_STATE!==undefined',timeout=60000)
   async def state():return await page.evaluate('window.SG_LAB_STATE')
   async def tap(key):
    s=await state();rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport']
    assert 0<=x<=vw and 0<=y<=vh,(key,[x,y],s['viewport'])
    await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height']);await page.wait_for_timeout(500)
   async def equip(slot,item):
    await tap(f'Slot {slot}');await tap('Inventory');await tap(f'Item {item}');await tap('InventoryApply');assert (await state())['slots'][slot]==item
   async def connect(source,target):
    await tap(f'Slot {source}');await tap('Source');await tap(f'Slot {target}');await tap('Connect')
   for speed in [2,4,8]:
    await tap('Speed');await page.wait_for_function('(v)=>window.SG_LAB_STATE.speed===v',arg=speed,timeout=10000)
   await page.wait_for_function('window.SG_LAB_STATE.reward_pending>0',timeout=120000)
   s=await state();assert s['wave']==3 and not s['kit']
   gem=next(i for i,item in enumerate(s['reward_offers']) if item['kind']=='gem');await tap(f'Reward {gem}')
   s=await state();assert s['edit_open'] and s['reward_loadout'] and s['item_count']==2
   clock=s['combat_seconds'];await page.wait_for_timeout(1000);assert (await state())['combat_seconds']==clock
   await equip(1,1);await connect(0,1);assert (await state())['attack_period']==1.1
   await tap('Done');assert not (await state())['edit_open'];print(name,'wave-three gear equipped',flush=True)
   await page.wait_for_function('window.SG_LAB_STATE.boss?.warning>0 || window.SG_LAB_STATE.boss?.phase>=2',timeout=120000)
   await tap('Pause');boss=await state();assert boss['paused'] and boss['wave']==5 and boss['boss']['hp']>0
   await page.screenshot(path=str(REPORT/f'first-boss-warning-{name}.png'));await tap('Pause')
   await page.wait_for_function('window.SG_LAB_STATE.wave===5 && window.SG_LAB_STATE.reward_pending>0',timeout=120000)
   boss_clear=await state();count=boss_clear['reward_pending'];assert 1<=count<=5 and boss_clear['boss_kills']==1 and boss_clear['summoned_minions']>=3
   for remaining in range(count,0,-1):
    s=await state();assert s['reward_pending']==remaining
    skill=next(i for i,item in enumerate(s['reward_offers']) if item['kind']=='skill');await tap(f'Reward {skill}')
   s=await state();assert s['edit_open'] and s['reward_loadout'] and s['item_count']==2+count
   clock=s['combat_seconds'];await page.wait_for_timeout(1000);assert (await state())['combat_seconds']==clock
   await equip(2,2);await connect(1,2);loadout=await state();assert loadout['attack_period']==1.8 and len(loadout['edges'])==2
   await page.screenshot(path=str(REPORT/f'earned-chain-{name}.png'));await tap('Done')
   await page.wait_for_function('window.SG_LAB_STATE.wave>=6 && window.SG_LAB_STATE.jumps>0 && window.SG_LAB_STATE.hp>0',timeout=120000)
   await tap('Pause');battle=await state();assert not battle['kit'] and battle['boss_kills']==1 and battle['reward_granted']==1+count
   await page.screenshot(path=str(REPORT/f'first-boss-cleared-{name}.png'))
   engine_errors=[s for s in logs if 'SCRIPT ERROR' in s or s.startswith('ERROR:')];assert not errors and not engine_errors,(errors,engine_errors)
   results[name]={'viewport':size,'boss':boss,'boss_clear':boss_clear,'loadout':loadout,'battle':battle,'pageerrors':errors,'engine_errors':engine_errors,'passed':['actual first five waves without training kit','third-wave gem through touch inventory and legal link','reward loadout freezes combat until confirmation','Boss HUD and actual warning','real Boss kill and phase summons','one-to-five earned Boss selections','earned skill replacement and second link','real living-target jump in following wave'],'limit':'Linux Chromium software WebGL touch emulation; no iPad Safari or full twenty-wave balance claim'}
   print(name,'FIRST BOSS PASS',{'wave':battle['wave'],'boss_rewards':count,'summons':battle['summoned_minions'],'jumps':battle['jumps']},flush=True);await page.close()
  await browser.close()
 (REPORT/'first-boss-web.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
asyncio.run(main())
