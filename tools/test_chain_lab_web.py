"""Actual Chain Lab export, touch emulation; no native browser/device claim."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1]
REPORT=ROOT/'docs/first-boss';REPORT.mkdir(parents=True,exist_ok=True)
parser=argparse.ArgumentParser();parser.add_argument('--directory',default=str(ROOT/'godot/export/lab'));parser.add_argument('--entry',default='/');parser.add_argument('--editor-only',action='store_true');args=parser.parse_args()
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=args.directory))
threading.Thread(target=server.serve_forever,daemon=True).start()
async def main():
 results={}
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  for name,size in [('landscape',{'width':1180,'height':820}),('portrait',{'width':820,'height':1180})]:
   page=await browser.new_page(viewport=size,has_touch=True,device_scale_factor=1)
   errors=[];logs=[]
   page.on('pageerror',lambda e:errors.append(str(e)))
   page.on('console',lambda m:logs.append({'type':m.type,'text':m.text}))
   await page.goto(f'http://127.0.0.1:{server.server_port}{args.entry}?debug=1&seed=12032')
   await page.wait_for_function('window.SG_LAB_STATE!==undefined',timeout=60000)
   async def state():return await page.evaluate('window.SG_LAB_STATE')
   async def tap(key):
    s=await state();rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport']
    await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height'])
    await page.wait_for_timeout(650)
   initial=await state();assert initial['capacity']==10 and initial['slots']==[0]+[-1]*9 and initial['arrange_disabled']
   await tap('Kit');s=await state();assert s['kit'] and s['edit_open'] and len(s['edges'])==7
   await page.screenshot(path=str(REPORT/f'lab-editor-{name}.png'))
   await tap('Slot 2');assert (await state())['selected']==2
   await tap('Inventory');assert (await state())['inventory_open']
   before_inventory=(await state())['slots']
   await tap('Item 3');s=await state();assert s['inventory_apply_disabled'] and s['slots']==before_inventory and '不能重複' in s['inventory_detail']
   await tap('Item 8');s=await state();assert not s['inventory_apply_disabled'] and s['slots']==before_inventory
   await page.screenshot(path=str(REPORT/f'inventory-preview-{name}.png'))
   await tap('InventoryApply');s=await state();assert not s['inventory_open'] and s['slots'][2]==8 and 2 not in s['slots']
   await tap('Inventory');await tap('Item 2');await tap('InventoryClose');assert (await state())['slots'][2]==8
   await tap('Slot 1');await tap('Inventory');await tap('Item 9');s=await state()
   assert s['inventory_apply_disabled'] and '分岔' in s['inventory_detail'] and s['slots'][1]==1
   await tap('InventoryClose');await tap('Slot 2')
   await tap('Source');await tap('Slot 3');await tap('Connect')
   assert len((await state())['edges'])==7 # skill-to-skill must fail
   await tap('Random');s=await state();assert len([i for i in s['slots'] if i>=0])<=10 and len(set(i for i in s['slots'] if i>=0))==len([i for i in s['slots'] if i>=0])
   await tap('Done');assert not (await state())['edit_open']
   if args.editor_only:
    engine_errors=[m for m in logs if 'SCRIPT ERROR' in m['text'] or m['text'].startswith('ERROR:')]
    assert not errors and not engine_errors,(errors,engine_errors)
    results[name]={'passed':['graph selection','illegal link rejection','unique inventory arrangement','icon bag candidate preview and apply','cancel preserves gear','reject duplicate and fork downgrade','close editor'],'pageerrors':errors,'engine_errors':engine_errors}
    print(name,'editor PASS',flush=True);await page.close();continue
   # Reapply the known lab fixture, not a recipe-based automatic unlock.
   await tap('Kit');await tap('Done')
   await tap('Tempo');assert (await state())['tempo']==1
   await tap('Tempo');assert (await state())['tempo']==2
   await tap('Pause');assert (await state())['paused']
   paused_casts=(await state())['casts'];await page.wait_for_timeout(1500)
   assert (await state())['casts']==paused_casts
   await tap('Pause');assert not (await state())['paused']
   await page.wait_for_function('window.SG_LAB_STATE.casts>=8 && window.SG_LAB_STATE.jumps>0 && window.SG_LAB_STATE.misses>0 && window.SG_LAB_STATE.empty_casts>0',timeout=120000)
   await page.screenshot(path=str(REPORT/f'lab-battle-{name}.png'))
   final=await state();assert final['wave']>=1 and final['hp']>0
   casts=[v for v in final['trace'] if v['kind']=='cast']
   assert final['empty_casts']>0 # trace is bounded; cumulative counter proves a null-target launch occurred
   assert final['jumps']>0 and final['misses']>0
   assert all(v['kind']!='hit' or v['target']!=0 for v in final['trace'])
   engine_errors=[m for m in logs if 'SCRIPT ERROR' in m['text'] or m['text'].startswith('ERROR:')]
   assert not errors and not engine_errors,(errors,engine_errors)
   results[name]={'viewport':size,'initial':initial,'final':final,'pageerrors':errors,'engine_errors':engine_errors,'passed':['lab feature-scene export','arcane-only ten-slot start','unknown recipe gate','training kit inventory','icon bag preview, confirm and cancel','no duplicate equipment or lost forks','slot selection','reject skill-to-skill link','legal unique-item random arrangement','close editor and resume','tempo presets','pause/resume','actual chained impacts in battle','living-target jumps','visible empty continuations','no phantom hits on null target'],'limit':'Linux Chromium software WebGL touch emulation; no Safari or iPad performance claim'}
   print(name,'PASS',{'casts':final['casts'],'wave':final['wave']},flush=True)
   await page.close()
  await browser.close()
 (REPORT/('tree-editor-web.json' if args.editor_only else 'lab-web-smoke.json')).write_text(json.dumps(results,ensure_ascii=False,indent=2))
asyncio.run(main())
