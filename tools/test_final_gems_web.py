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
    await page.goto(f'http://127.0.0.1:{server.server_port}{args.entry}?debug=1&seed=6110');await page.wait_for_function('window.SG_LAB_STATE!==undefined',timeout=60000)
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
    initial=await state();assert initial['item_count']==1 and initial['criticals_enabled'] and not initial['final_gem_kit']
    await tap('Configure');await tap('FinalGemKit');s=await state()
    assert s['final_gem_kit'] and s['item_count']==42 and s['slots'].count(-1)==5
    await tap('FinalGemKit');assert (await state())['item_count']==42
    await page.screenshot(path=str(REPORT/f'final-gems-tree-{args.label}-{orientation}.png'))
    await tap('Slot 1');await tap('Inventory')
    for key,name,description in [('rapid','迅捷寶石','35%'),('crit','暴擊條件','50%')]:
     await tap(f"Item {s['gem_kit_ids'][key]}");selected=await state()
     assert selected['candidate']==s['gem_kit_ids'][key] and name in selected['inventory_detail'] and description in selected['inventory_detail'],selected['inventory_detail']
    await page.screenshot(path=str(REPORT/f'final-gems-inventory-{args.label}-{orientation}.png'));await tap('InventoryClose')
    controls=await state();canvas=await page.locator('#canvas').bounding_box();x,y,_,_=controls['buttons']['Pause'];vw,vh=controls['viewport'];pause_point=(canvas['x']+x/vw*canvas['width'],canvas['y']+y/vh*canvas['height'])
    await tap('Done')
    await page.wait_for_function("window.SG_LAB_STATE.trace.some(e=>e.kind==='gem'&&e.key==='crit'&&e.success&&e.critical) && window.SG_LAB_STATE.trace.some(e=>e.kind==='cast'&&e.slot===4&&Math.abs(e.damage_scale-1.35)<.001)",timeout=90000)
    await page.touchscreen.tap(*pause_point);await page.wait_for_timeout(500);final=await state();assert final['paused'] and final['critical_victims']>0
    gate=next(e for e in final['trace'] if e['kind']=='gem' and e['key']=='crit' and e['success'] and e['critical'])
    events=[e for e in final['trace'] if e['run']==gate['run']]
    assert any(e['kind']=='hit' and e.get('critical') for e in events),events
    assert any(e['kind']=='cast' and e['slot']==4 and abs(e['damage_scale']-1.35)<.001 for e in events),events
    clock=final['combat_seconds'];await page.wait_for_timeout(1000);assert (await state())['combat_seconds']==clock
    engine_errors=[v for v in logs if 'SCRIPT ERROR' in v or v.startswith('ERROR:')];assert not errors and not engine_errors,(errors,engine_errors)
    await page.screenshot(path=str(REPORT/f'final-gems-battle-{args.label}-{orientation}.png'))
    results[orientation]={'initial':initial,'final':final,'successful_run':events,'pageerrors':errors,'engine_errors':engine_errors,'seed':6110,'passed':['normal start unchanged; criticals enabled','training idempotent at 42 items','both gems previewed through touch on third inventory page','actual critical hit passes real conditional probability','rapid boosts next real cast 35 percent','pause stops simulation'],'limit':'Linux Chromium touch emulation, not iPad Safari hardware or full twenty-wave balance.'}
    print(orientation,'FINAL GEMS PASS',final['critical_victims'],flush=True);await page.close()
  finally:await browser.close()
 (REPORT/f'final-gems-{args.label}.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
try:asyncio.run(main())
finally:server.shutdown();server.server_close()
