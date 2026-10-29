"""Actual eight-spell training UI, projectile flight and resolved cast smoke."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1];REPORT=ROOT/'docs/timing-gem';REPORT.mkdir(parents=True,exist_ok=True)
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
    s=await state();rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport'];assert 0<=x<=vw and 0<=y<=vh,(key,[x,y],s['viewport'])
    await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height']);await page.wait_for_timeout(500)
   initial=await state();assert initial['slots']==[0]+[-1]*9 and len(initial['spell_keys'])==8 and not initial['spell_kit']
   await tap('SpellKit');s=await state();assert s['spell_kit'] and s['item_count']==18 and s['edit_open'] and len(s['edges'])==8 and s['slots'].count(-1)==1
   await page.screenshot(path=str(REPORT/f'eight-spell-chain-{name}.png'))
   await tap('Inventory')
   await tap('Item 1');assert '下一個技能' in (await state())['inventory_detail'] and '35%' in (await state())['inventory_detail']
   for key,word in [('burn','火焰'),('freeze','緩速')]:
    await tap(f"Item {s['gem_kit_ids'][key]}");detail=(await state())['inventory_detail'];assert word in detail and '90%' in detail
   await tap(f"Item {s['gem_kit_ids']['lowhp']}");assert '55%' in (await state())['inventory_detail'] and '命中後' in (await state())['inventory_detail']
   await tap(f"Item {s['gem_kit_ids']['delay']}");assert '3 秒' in (await state())['inventory_detail'] and '目前冷卻' in (await state())['inventory_detail']
   await page.screenshot(path=str(REPORT/f'timing-gem-inventory-{name}.png'))
   await tap('Item 4');assert '50%' in (await state())['inventory_detail'] and '不延伸' in (await state())['inventory_detail']
   await tap(f"Item {s['spell_kit_ids']['poison']}");assert '附毒' in (await state())['inventory_detail']
   await tap(f"Item {s['spell_kit_ids']['beam']}");assert '穿透' in (await state())['inventory_detail']
   await page.screenshot(path=str(REPORT/f'eight-spell-inventory-{name}.png'));await tap('InventoryClose');await tap('Done')
   await page.wait_for_function("window.SG_LAB_STATE.spell_flights.includes('meteor')",timeout=90000)
   await tap('Pause');flight=await state();assert flight['paused'] and 'meteor' in flight['spell_flights']
   await page.screenshot(path=str(REPORT/f'meteor-flight-{name}.png'));await tap('Pause')
   await page.wait_for_function("['poison','meteor','nova','beam'].every(k=>(window.SG_LAB_STATE.spell_casts[k]||0)>0)",timeout=90000)
   await page.wait_for_function("window.SG_LAB_STATE.trace.some(e=>e.kind==='cast'&&e.is_echo)",timeout=90000)
   # Freeze the finished sequence before collecting evidence; no game-data injection.
   await tap('Pause');final=await state();assert sum(final['spell_hits'].get(k,0) for k in ['poison','meteor','nova','beam'])>0
   assert any(e['kind']=='cast' and e.get('damage_scale',1)>1 for e in final['trace'])
   assert any(e['kind']=='cast' and e.get('is_echo') for e in final['trace'])
   assert any(e['kind']=='gem' and e.get('reason')=='success' for e in final['trace'])
   assert all(e['kind']!='hit' or e['target']!=0 for e in final['trace'])
   await page.screenshot(path=str(REPORT/f'eight-spell-battle-{name}.png'))
   await tap('Configure')
   for slot,key in [(5,'burn'),(7,'freeze'),(1,'lowhp')]:
    await tap(f'Slot {slot}');await tap('Inventory');await tap(f"Item {final['gem_kit_ids'][key]}");assert not (await state())['inventory_apply_disabled'];await tap('InventoryApply');assert (await state())['slots'][slot]==final['gem_kit_ids'][key]
   await page.screenshot(path=str(REPORT/f'lowhp-gem-equipped-{name}.png'))
   equipped=await state()
   # Build a real two-skill chain from owned training items, then observe cooldown.
   timer_id=final['gem_kit_ids']['delay']
   await tap('Slot 1');await tap('Inventory');await tap(f'Item {timer_id}');await tap('InventoryApply')
   await tap('Slot 2');await tap('Source');await tap('Slot 3');await tap('Disconnect')
   await tap('Done');await tap('Pause')
   await page.wait_for_function("window.SG_LAB_STATE.trace.some(e=>e.kind==='gem'&&e.key==='delay'&&e.reason==='cooldown')",timeout=60000)
   await tap('Pause');cooling=await state();assert cooling['paused'] and cooling['gem_cooldowns'][str(timer_id)]>0
   await page.wait_for_timeout(1200);held=await state();assert held['gem_cooldowns']==cooling['gem_cooldowns'] and held['combat_seconds']==cooling['combat_seconds']
   await page.screenshot(path=str(REPORT/f'timing-cooldown-{name}.png'))
   await tap('Configure');await tap('Slot 1');await tap('Inventory');assert '目前冷卻' in (await state())['inventory_detail']
   await page.screenshot(path=str(REPORT/f'timing-inventory-cooldown-{name}.png'));await tap('InventoryClose');await tap('Done')
   for i in range(3):await tap('Speed')
   assert (await state())['speed']==8
   await tap('Pause')
   await page.wait_for_function("window.SG_LAB_STATE.trace.filter(e=>e.kind==='gem'&&e.key==='delay'&&e.reason==='success').length>=2",timeout=30000)
   await tap('Pause');timed=await state();assert timed['paused']
   successes=[e for e in timed['trace'] if e['kind']=='gem' and e.get('key')=='delay' and e['reason']=='success']
   assert all(b['clock']-a['clock']>=3-0.0001 for a,b in zip(successes,successes[1:]))
   await page.screenshot(path=str(REPORT/f'timing-eight-speed-{name}.png'))
   engine_errors=[s for s in logs if 'SCRIPT ERROR' in s or s.startswith('ERROR:')];assert not errors and not engine_errors,(errors,engine_errors)
   results[name]={'viewport':size,'initial':initial,'flight':flight,'final':final,'element_equipped':equipped,'cooling':cooling,'cooldown_held':held,'timed_eight_speed':timed,'pageerrors':errors,'engine_errors':engine_errors,'passed':['arcane-only normal start','eight canonical skill types','explicit nine-slot training fixture without duplicate grants','touch inventory poison and beam descriptions','actual meteor sprite in flight','four new spell completion callbacks in real battle','actual new-spell hits and no phantom target-zero hit'],'limit':'Explicit training fixture, Linux Chromium software WebGL touch emulation; behavior and individual hit shapes are also verified with real enemies in native tests. No iPad or full original-parity claim.'}
   print(name,'EIGHT SPELLS PASS',final['spell_casts'],flush=True);await page.close()
  await browser.close()
 (REPORT/'eight-spell-web.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
asyncio.run(main())
