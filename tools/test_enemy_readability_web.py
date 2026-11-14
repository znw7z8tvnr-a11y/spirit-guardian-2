"""Real touch selection and direct-modifier trace acceptance; no gameplay state injection."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1];REPORT=ROOT/'docs/enemy-readability';REPORT.mkdir(exist_ok=True)
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
    await tap('Configure');await tap('CrowdDrill',0)
    await page.wait_for_function("window.SG_LAB_STATE.enemy_units.length===40 && window.SG_LAB_STATE.enemy_units.some(e=>e.ranged_warning>0.3)",timeout=15000)
    await page.touchscreen.tap(*pause_point);await page.wait_for_timeout(400);held=await state()
    def validate(s):
     m=s['enemy_labels'];assert m['allocated']==6 and 0<m['visible']<=6 and m['shown'] and m['trials']<=40*9,m
     assert len({r['id'] for r in m['rects']})==len(m['rects'])
     for key in {r['key'] for r in m['rects']} - {''}:assert sum(r['key']==key for r in m['rects'])<=2
     for i,r in enumerate(m['rects']):
      x,y,w,h=r['rect'];assert 0<=x and 0<=y and x+w<=s['viewport'][0]+.1 and y+h<=s['viewport'][1]+.1,r
      for q in m['rects'][i+1:]:
       a,b,c,d=q['rect'];assert x+w<=a or a+c<=x or y+h<=b or b+d<=y,(r,q)
    validate(held);assert held['paused'] and len(held['enemy_units'])==40 and any(e['ranged_warning']>0 for e in held['enemy_units'])
    assert '靈彈 ×8' in held['enemy_warning'] and '0.0 秒' not in held['enemy_warning'],held['enemy_warning']
    clock=held['combat_seconds'];await page.wait_for_timeout(1000);frozen=await state();assert frozen['combat_seconds']==clock
    assert frozen['enemy_labels']['text_writes']==held['enemy_labels']['text_writes']
    await page.screenshot(path=str(REPORT/f'forty-warning-{args.label}-{orientation}.png'))
    await tap('Configure');assert not (await state())['enemy_labels']['shown'];await tap('Done');await tap('Pause')
    samples=[]
    for i in range(6):
     await page.wait_for_timeout(500);sample=await state();validate(sample);samples.append({'fps':sample['fps'],'enemies':len(sample['enemy_units']),'labels':sample['enemy_labels']})
    await tap('Pause');final=await state();validate(final)
    assert final['combat_seconds']>clock and final['wall_hp']<held['wall_max'] and final['casts']>0 and final['reward_pending']==0
    assert final['enemy_tactic_counts'].get('治療蓄力',0)>0 and final['enemy_tactic_counts'].get('護盾蓄力',0)>0 and final['enemy_tactic_counts'].get('鼓舞蓄力',0)>0
    engine_errors=[v for v in logs if 'SCRIPT ERROR' in v or v.startswith('ERROR:')];assert not errors and not engine_errors,(errors,engine_errors)
    await page.screenshot(path=str(REPORT/f'forty-combat-{args.label}-{orientation}.png'))
    results[orientation]={'initial':initial,'held':held,'final':final,'samples':samples,'pageerrors':errors,'engine_errors':engine_errors,'passed':['forty real animated combat actors','six reusable labels maximum','visible label rectangles do not overlap and remain in viewport','active ranged warning groups all eight shamans and never displays zero','pause does not rewrite identical label text','editor hides battlefield labels and remains touch-operable','actual combat, damage and support continue without wave rewards'],'limit':'Linux Chromium software WebGL touch emulation. FPS samples are observations of this environment, not a before/after benchmark, iPad performance target or full twenty-wave balance.'}
    print(orientation,'FORTY ENEMIES PASS',[v['fps'] for v in samples],flush=True);await page.close()
  finally:await browser.close()
 (REPORT/f'enemy-readability-{args.label}.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
try:asyncio.run(main())
finally:server.shutdown();server.server_close()
