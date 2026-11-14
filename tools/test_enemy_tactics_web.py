"""Real touch selection and direct-modifier trace acceptance; no gameplay state injection."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1];REPORT=ROOT/'docs/enemy-tactics';REPORT.mkdir(exist_ok=True)
p=argparse.ArgumentParser();p.add_argument('--directory',default=str(ROOT/'godot/export/lab'));p.add_argument('--entry',default='/');p.add_argument('--label',default='web');args=p.parse_args()
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=args.directory));threading.Thread(target=server.serve_forever,daemon=True).start()
NAMES={'blast':'爆破攻擊','bolt':'雷擊攻擊','venom':'毒蝕攻擊','frostatk':'寒霜攻擊','critical':'致命攻擊','piercing':'穿刺攻擊','range':'廣域攻擊','multi':'多重攻擊'}
async def main():
 results={}
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  try:
   for orientation,size in [('landscape',{'width':1180,'height':820}),('portrait',{'width':820,'height':1180})]:
    page=await browser.new_page(viewport=size,has_touch=True,device_scale_factor=1);errors=[];logs=[]
    page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:logs.append(m.text))
    await page.goto(f'http://127.0.0.1:{server.server_port}{args.entry}?debug=1&seed=6110');await page.wait_for_function('window.SG_LAB_STATE!==undefined',timeout=60000)
    async def state():return await page.evaluate('window.SG_LAB_STATE')
    async def tap(key,settle=500):
     s=await state()
     if key.startswith('Item '):
      target=(int(key.split()[1])+1)//15
      for attempt in range(4):
       if s['inventory_page']==target:break
       await tap('InventoryNext' if target>s['inventory_page'] else 'InventoryPrev');s=await state()
      assert s['inventory_page']==target,(key,s['inventory_page'],target)
     rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport'];assert 0<=x<=vw and 0<=y<=vh,(key,[x,y],s['viewport'])
     await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height']);await page.wait_for_timeout(settle)
    initial=await state();assert initial['item_count']==1 and not initial['enemy_drill']
    canvas=await page.locator('#canvas').bounding_box();x,y,_,_=initial['buttons']['Pause'];vw,vh=initial['viewport'];pause_point=(canvas['x']+x/vw*canvas['width'],canvas['y']+y/vh*canvas['height'])
    await tap('Configure');await tap('EnemyDrill',0)
    await page.wait_for_function("window.SG_LAB_STATE.enemy_units.some(e=>e.ranged_warning>0.3)",timeout=15000)
    await page.touchscreen.tap(*pause_point);await page.wait_for_timeout(350);held=await state();assert any(e['ranged_warning']>0 for e in held['enemy_units']) and '靈彈' in held['enemy_warning'],held
    assert held['paused'] and held['enemy_drill'] and held['wave']==6 and held['item_count']==1
    assert sorted(int(k) for k in held['enemy_spawn_counts'])==[0,1,2,3,4]
    clock=held['combat_seconds'];warnings=[e['ranged_warning'] for e in held['enemy_units']]
    await page.wait_for_timeout(1000);frozen=await state();assert frozen['combat_seconds']==clock and [e['ranged_warning'] for e in frozen['enemy_units']]==warnings
    await page.screenshot(path=str(REPORT/f'enemy-warning-{args.label}-{orientation}.png'));await tap('Pause')
    await page.wait_for_function("['護盾蓄力','治療蓄力','鼓舞蓄力','靈彈'].every(k=>(window.SG_LAB_STATE.enemy_tactic_counts[k]||0)>0) && window.SG_LAB_STATE.enemy_units.some(e=>e.kind===3&&e.support_targets>0)",timeout=30000)
    await tap('Pause');final=await state();assert final['paused'] and final['wall_hp']<held['wall_max'] and final['reward_pending']==0 and final['wave']==6
    assert final['enemy_units'] and any(e['shield']>0 for e in final['enemy_units']),final['enemy_units']
    engine_errors=[v for v in logs if 'SCRIPT ERROR' in v or v.startswith('ERROR:')];assert not errors and not engine_errors,(errors,engine_errors)
    await page.screenshot(path=str(REPORT/f'enemy-tactics-{args.label}-{orientation}.png'))
    results[orientation]={'initial':initial,'paused_warning':held,'final':final,'pageerrors':errors,'engine_errors':engine_errors,'passed':['arcane-only normal start','five real enemy roles from touch drill','ranged warning freezes on pause','real shield, healing and rally casts','real flesh-wall damage after ranged windup','no wave reward granted by drill'],'limit':'Explicit wave-six drill, Linux Chromium touch emulation. Not a normal twenty-wave clear, final balance or iPad Safari hardware test.'}
    print(orientation,'ENEMY TACTICS PASS',final['enemy_tactic_counts'],flush=True);await page.close()
  finally:await browser.close()
 (REPORT/f'enemy-tactics-{args.label}.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
try:asyncio.run(main())
finally:server.shutdown();server.server_close()
