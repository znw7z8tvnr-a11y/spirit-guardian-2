"""Focused trusted-touch guardian cast and strike checks; no gameplay injection."""
import argparse, asyncio, functools, http.server, json, os, pathlib, threading
from playwright.async_api import async_playwright
ROOT = pathlib.Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('--directory', default=str(ROOT/'godot/export/lab'))
p.add_argument('--report-dir', type=pathlib.Path, default=ROOT/'docs/guardian-atlas/browser')
args = p.parse_args(); args.report_dir.mkdir(parents=True, exist_ok=True)
server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(http.server.SimpleHTTPRequestHandler, directory=args.directory))
threading.Thread(target=server.serve_forever, daemon=True).start()
async def main():
 results = {}
 async with async_playwright() as pw:
  browser = await pw.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'), headless=True, args=['--no-sandbox', '--enable-webgl', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'])
  try:
   for direction, size in [('landscape', {'width':1180, 'height':820}), ('portrait', {'width':820, 'height':1180})]:
    results[direction] = {}
    for species in ['summon', 'skeleton']:
     context = await browser.new_context(viewport=size, has_touch=True, device_scale_factor=1)
     page = await context.new_page(); errors = []; logs = []
     page.on('pageerror', lambda error: errors.append(str(error)))
     page.on('console', lambda message: logs.append(message.text))
     await page.goto(f'http://127.0.0.1:{server.server_port}/index.html?debug=1&seed=12032')
     await page.wait_for_function('window.SG_LAB_STATE!==undefined', timeout=60000)
     async def state(): return await page.evaluate('window.SG_LAB_STATE')
     async def tap(key):
      s = await state(); x,y,w,h = s['buttons'][key]; vw,vh = s['viewport']; rect = await page.locator('#canvas').bounding_box()
      assert 0 <= x-w/2 < x+w/2 <= vw+1 and 0 <= y-h/2 < y+h/2 <= vh+1
      assert w/vw*rect['width'] >= 44 and h/vh*rect['height'] >= 44
      await page.touchscreen.tap(rect['x']+x/vw*rect['width'], rect['y']+y/vh*rect['height']); await page.wait_for_timeout(350)
     await tap('SpellKit'); kit = await state()
     assert len(kit['spell_keys']) == 22 and kit['spell_kit'] and kit['edit_open']
     await tap('Slot 0'); await tap('Inventory')
     item = kit['spell_kit_ids'][species]; target_page = (item+1)//15
     for attempt in range(4):
      if (await state())['inventory_page'] == target_page: break
      await tap('InventoryNext')
     assert (await state())['inventory_page'] == target_page
     await tap(f'Item {item}'); await tap('InventoryApply'); await tap('Done')
     if (await state())['paused']: await tap('Pause')
     await page.wait_for_function("key => (window.SG_LAB_STATE.spell_hits[key]||0)>0 && window.SG_LAB_STATE.guardian_by_type[key].hits>0", arg=species, timeout=60000)
     await tap('Pause'); battle = await state()
     assert battle['paused'] and battle['slots'][0] == item and 0 < len(battle['guardians']) <= 4
     assert battle['guardian_by_type'][species]['spawns'] > 0 and battle['guardian_by_type'][species]['hits'] > 0
     assert all(guard['type'] == species for guard in battle['guardians'])
     await page.screenshot(path=str(args.report_dir/f'{species}-{direction}.png'))
     engine = [line for line in logs if 'SCRIPT ERROR' in line or line.startswith('ERROR:')]
     assert not errors and not engine, (errors, engine)
     results[direction][species] = {'battle':battle, 'pageerrors':errors, 'engine_errors':engine, 'passed':['touch training loadout and owned item equip', 'real projectile hit and autonomous guardian strike', 'bounded live guardians with correct species', '44 CSS pixel touch controls'], 'limit':'Explicit training fixture, Chromium software WebGL; no Safari hardware or final art claim.'}
     print(direction, species, 'PASS', flush=True); await context.close()
  finally:
   await browser.close(); server.shutdown()
 (args.report_dir/'guardian-visuals-web.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
asyncio.run(main())
