"""Touch playthrough of the exact staged Site loader and Spark loadout, no state injection."""
import asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[2]
REPORT=ROOT/'docs/spark-spell'
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
    await tap('SpellKit');s=await state();assert s['item_count']==23 and len(s['spell_keys'])==13
    await tap('Slot 0');await tap('Inventory');await tap('InventoryNext');assert (await state())['inventory_page']==1
    await tap(f"Item {s['spell_kit_ids']['spark']}");assert '火花術' in (await state())['inventory_detail'];await tap('InventoryApply')
    assert (await state())['slots'][0]==s['spell_kit_ids']['spark']
    # Cache the real touch coordinate before the 0.7-second effect starts.
    # Additional debug/bounds protocol calls after observing FX can outlast it on software WebGL.
    controls=await state();canvas=await page.locator('#canvas').bounding_box();x,y,_,_=controls['buttons']['Pause'];vw,vh=controls['viewport']
    pause_point=(canvas['x']+x/vw*canvas['width'],canvas['y']+y/vh*canvas['height'])
    await tap('Done');await page.wait_for_function("(window.SG_LAB_STATE.spell_hits.spark||0)>0 && window.SG_LAB_STATE.spell_visuals.includes('spark')",timeout=60000)
    await page.touchscreen.tap(*pause_point);await page.wait_for_timeout(500)
    final=await state();(REPORT/f'spark-package-state-{name}.json').write_text(json.dumps(final,ensure_ascii=False,indent=2));await page.screenshot(path=str(REPORT/f'spark-package-{name}.png'));print(name,'package state',final['spell_casts'],final['spell_hits'],final['paused'],final['spell_visuals'],flush=True)
    assert final['spell_casts']['spark']>0 and final['spell_hits']['spark']>0 and final['paused'] and 'spark' in final['spell_visuals']
    engine_errors=[v for v in logs if 'SCRIPT ERROR' in v or v.startswith('ERROR:')];assert not errors and not engine_errors,(errors,engine_errors)
    await page.screenshot(path=str(REPORT/f'spark-package-{name}.png'))
    results[name]={'state':final,'pageerrors':errors,'engine_errors':engine_errors,'passed':['staged streaming loader boots','twenty-three owned items and thirteen lab skills','touch second inventory page','equip spark as root from owned item','actual spark casts and resolved hits','dedicated spark Sprite visible in real battle','pause battle'],'limit':'Linux Chromium touch emulation; not iPad Safari hardware or final artwork acceptance.'}
    print(name,'PACKAGED SPARK PASS',final['spell_casts']['spark'],final['spell_hits']['spark'],flush=True);await page.close()
  finally:await browser.close()
 (REPORT/'spark-packaged-web.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
try:asyncio.run(main())
finally:server.shutdown();server.server_close()
