"""Touch playthrough of the exact staged Site loader and Thorn loadout, no state injection."""
import asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[2]
REPORT=ROOT/'docs/thorn-spell'
SITE=pathlib.Path('/workspace/sites/spirit-guardian-m2-play/dist')
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(SITE)))
threading.Thread(target=server.serve_forever,daemon=True).start()
async def main():
 results={}
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  try:
   for name,size in [('landscape',{'width':1180,'height':820}),('portrait',{'width':820,'height':1180})]:
    page=await browser.new_page(viewport=size,has_touch=True,device_scale_factor=1);errors=[];logs=[]
    page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:logs.append(m.text))
    await page.goto(f'http://127.0.0.1:{server.server_port}/lab/?debug=1&seed=12032')
    await page.wait_for_function('window.SG_LAB_STATE!==undefined',timeout=60000)
    async def state():return await page.evaluate('window.SG_LAB_STATE')
    async def tap(key):
     s=await state();rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport']
     assert 0<=x<=vw and 0<=y<=vh,(key,[x,y],s['viewport'])
     await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height']);await page.wait_for_timeout(500)
    await tap('SpellKit');s=await state();assert s['item_count']==30 and len(s['spell_keys'])==20
    await tap('Slot 0');await tap('Inventory');await tap('InventoryNext');await tap('InventoryNext');assert (await state())['inventory_page']==2
    last_id=s['item_count']-1;await tap(f'Item {last_id}');last=await state();assert last['candidate']==last_id and '時序' in last['inventory_detail']
    await page.screenshot(path=str(REPORT/f'thorn-package-third-page-{name}.png'))
    await tap('InventoryPrev');assert (await state())['inventory_page']==(s['spell_kit_ids']['thorn']+1)//15
    await tap(f"Item {s['spell_kit_ids']['thorn']}")
    selected=await state();(REPORT/f'thorn-package-selection-{name}.json').write_text(json.dumps(selected,ensure_ascii=False,indent=2));await page.screenshot(path=str(REPORT/f'thorn-package-selection-{name}.png'))
    print(name,'selection',selected['candidate'],s['spell_kit_ids']['thorn'],selected['inventory_detail'],selected['buttons'].get(f"Item {s['spell_kit_ids']['thorn']}"),flush=True)
    assert '荊棘護城' in selected['inventory_detail'];await tap('InventoryApply')
    assert (await state())['slots'][0]==s['spell_kit_ids']['thorn']
    # Cache the real touch coordinate before the 1.0-second effect starts.
    # Additional debug/bounds protocol calls after observing FX can outlast it on software WebGL.
    controls=await state();canvas=await page.locator('#canvas').bounding_box();x,y,_,_=controls['buttons']['Pause'];vw,vh=controls['viewport']
    pause_point=(canvas['x']+x/vw*canvas['width'],canvas['y']+y/vh*canvas['height'])
    await tap('Done');await page.wait_for_function("(window.SG_LAB_STATE.spell_hits.thorn||0)>0 && window.SG_LAB_STATE.spell_visuals.includes('thorn')",timeout=60000)
    await page.touchscreen.tap(*pause_point);await page.wait_for_timeout(500)
    final=await state();(REPORT/f'thorn-package-state-{name}.json').write_text(json.dumps(final,ensure_ascii=False,indent=2));await page.screenshot(path=str(REPORT/f'thorn-package-{name}.png'));print(name,'package state',final['spell_casts'],final['spell_hits'],final['paused'],final['spell_visuals'],flush=True)
    assert final['spell_casts']['thorn']>0 and final['spell_hits']['thorn']>0 and final['paused'] and 'thorn' in final['spell_visuals']
    engine_errors=[v for v in logs if 'SCRIPT ERROR' in v or v.startswith('ERROR:')];assert not errors and not engine_errors,(errors,engine_errors)
    await page.screenshot(path=str(REPORT/f'thorn-package-{name}.png'))
    results[name]={'state':final,'pageerrors':errors,'engine_errors':engine_errors,'passed':['staged streaming loader boots','thirty owned items and twenty lab skills','touch third-page final timing gem, return to second-page thorn','equip thorn as root from owned item','actual thorn casts and resolved hits','dedicated thorn Sprite visible in real battle','pause battle'],'limit':'Linux Chromium touch emulation; not iPad Safari hardware or final artwork acceptance.'}
    print(name,'PACKAGED THORN PASS',final['spell_casts']['thorn'],final['spell_hits']['thorn'],flush=True);await page.close()
  finally:await browser.close()
 (REPORT/'thorn-packaged-web.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
try:asyncio.run(main())
finally:server.shutdown();server.server_close()
