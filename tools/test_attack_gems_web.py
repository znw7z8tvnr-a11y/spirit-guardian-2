"""Real touch selection and direct-modifier trace acceptance; no gameplay state injection."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1];REPORT=ROOT/'docs/final-gems';REPORT.mkdir(exist_ok=True)
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
    await page.goto(f'http://127.0.0.1:{server.server_port}{args.entry}?debug=1&seed=12032');await page.wait_for_function('window.SG_LAB_STATE!==undefined',timeout=60000)
    async def state():return await page.evaluate('window.SG_LAB_STATE')
    async def tap(key):
     s=await state()
     if key.startswith('Item '):
      target=(int(key.split()[1])+1)//15
      for attempt in range(4):
       if s['inventory_page']==target:break
       await tap('InventoryNext' if target>s['inventory_page'] else 'InventoryPrev');s=await state()
      assert s['inventory_page']==target,(key,s['inventory_page'],target)
     rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport'];assert 0<=x<=vw and 0<=y<=vh,(key,[x,y],s['viewport'])
     await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height']);await page.wait_for_timeout(500)
    initial=await state();assert initial['item_count']==1 and initial['slots']==[0]+[-1]*9 and not initial['attack_kit']
    await tap('Configure');await tap('AttackKit');s=await state();assert s['attack_kit'] and s['item_count']==40 and s['slots'].count(-1)==1
    await tap('AttackKit');assert (await state())['item_count']==40
    await page.screenshot(path=str(REPORT/f'attack-gems-tree-{args.label}-{orientation}.png'))
    await tap('Slot 0');await tap('Inventory');assert '70%' in (await state())['inventory_detail'] and '目前直擊傷害' in (await state())['inventory_detail'];await tap('InventoryClose')
    await tap('Slot 1');await tap('Inventory')
    for key,name in NAMES.items():
     await tap(f"Item {s['gem_kit_ids'][key]}");selected=await state();assert selected['candidate']==s['gem_kit_ids'][key]
     assert name in selected['inventory_detail'] and '前一個技能' in selected['inventory_detail'] and '固定 1 條線' in selected['inventory_detail'],selected['inventory_detail']
    await page.screenshot(path=str(REPORT/f'attack-gems-inventory-{args.label}-{orientation}.png'));await tap('InventoryApply')
    equipped=await state();assert equipped['slots'][1]==s['gem_kit_ids']['multi']
    controls=await state();canvas=await page.locator('#canvas').bounding_box();x,y,_,_=controls['buttons']['Pause'];vw,vh=controls['viewport'];pause_point=(canvas['x']+x/vw*canvas['width'],canvas['y']+y/vh*canvas['height'])
    await tap('Done')
    await page.wait_for_function("window.SG_LAB_STATE.trace.some(e=>e.kind==='cast'&&e.slot===8&&e.own_damage_scale===1) && window.SG_LAB_STATE.hits>=2",timeout=90000)
    await page.touchscreen.tap(*pause_point);await page.wait_for_timeout(500);final=await state();assert final['paused']
    root_cast=next(e for e in final['trace'] if e['kind']=='cast' and e['slot']==0 and e['own_damage_scale']==1.5)
    casts=[e for e in final['trace'] if e['kind']=='cast' and e['run']==root_cast['run']]
    assert [e['slot'] for e in casts]==[0,2,4,6,8],casts
    assert [e['own_damage_scale'] for e in casts]==[1.5,1.5,1.35,1.45,1.0],casts
    assert all(e['damage_scale']==1 for e in casts),casts
    clock=final['combat_seconds'];await page.wait_for_timeout(1000);assert (await state())['combat_seconds']==clock
    engine_errors=[v for v in logs if 'SCRIPT ERROR' in v or v.startswith('ERROR:')];assert not errors and not engine_errors,(errors,engine_errors)
    await page.screenshot(path=str(REPORT/f'attack-gems-battle-{args.label}-{orientation}.png'))
    results[orientation]={'initial':initial,'equipped':equipped,'final':final,'first_fixture_casts':casts,'pageerrors':errors,'engine_errors':engine_errors,'passed':['normal start unchanged','touch attack kit twice without duplicate items','eight source attack gems previewed on actual inventory page','skill preview includes attached local bonus','replace owned critical gem with multi through touch','five real cast events have distinct local scales and no inherited next-scale','actual resolved hits and paused simulation'],'limit':'Linux Chromium touch emulation; numerical HP damage and single-line rules verified separately in native tests; not iPad Safari hardware or full twenty-wave balance.'}
    print(orientation,'ATTACK GEMS PASS',[e['own_damage_scale'] for e in casts],final['hits'],flush=True);await page.close()
  finally:await browser.close()
 (REPORT/f'attack-gems-{args.label}.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
try:asyncio.run(main())
finally:server.shutdown();server.server_close()
