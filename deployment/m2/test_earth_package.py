"""Touch playthrough of the exact staged Site loader and Earth loadout, no state injection."""
import asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[2]
REPORT=ROOT/'docs/earth-spell'
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
    await tap('SpellKit');s=await state();assert s['item_count']==20 and len(s['spell_keys'])==10
    await tap('Slot 0');await tap('Inventory');await tap('InventoryNext');assert (await state())['inventory_page']==1
    await tap(f"Item {s['spell_kit_ids']['earth']}");assert '土刺' in (await state())['inventory_detail'];await tap('InventoryApply')
    assert (await state())['slots'][0]==s['spell_kit_ids']['earth']
    await tap('Done');await page.wait_for_function("(window.SG_LAB_STATE.spell_hits.earth||0)>0",timeout=60000);await tap('Pause')
    final=await state();assert final['spell_casts']['earth']>0 and final['spell_hits']['earth']>0 and final['paused']
    engine_errors=[v for v in logs if 'SCRIPT ERROR' in v or v.startswith('ERROR:')];assert not errors and not engine_errors,(errors,engine_errors)
    await page.screenshot(path=str(REPORT/f'earth-package-{name}.png'))
    results[name]={'state':final,'pageerrors':errors,'engine_errors':engine_errors,'passed':['staged streaming loader boots','twenty owned items and ten lab skills','touch second inventory page','equip earth as root from owned item','actual earth casts and resolved hits','pause battle'],'limit':'Linux Chromium touch emulation; not iPad Safari hardware or final artwork acceptance.'}
    print(name,'PACKAGED EARTH PASS',final['spell_casts']['earth'],final['spell_hits']['earth'],flush=True);await page.close()
  finally:await browser.close()
 (REPORT/'earth-packaged-web.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
try:asyncio.run(main())
finally:server.shutdown();server.server_close()
