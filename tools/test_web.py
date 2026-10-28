"""Actual exported Godot WebGL smoke; Chromium touch emulation is not Safari."""
import asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1]
REPORT=ROOT/'docs/m2-1'
REPORT.mkdir(parents=True,exist_ok=True)
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(ROOT/'godot/export/web')))
threading.Thread(target=server.serve_forever,daemon=True).start()
async def main():
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  results={}
  for label,size in [('landscape',{'width':1180,'height':820}),('portrait',{'width':820,'height':1180})]:
   page=await browser.new_page(viewport=size,has_touch=True,device_scale_factor=1)
   errors=[]; logs=[]
   page.on('pageerror',lambda e:errors.append(str(e)))
   page.on('console',lambda m:(logs.append({'type':m.type,'text':m.text}),print(m.type,m.text,flush=True)))
   await page.goto(f'http://127.0.0.1:{server.server_port}/index.html?debug=1')
   await page.wait_for_function('window.SG_M1_STATE !== undefined',timeout=45000)
   print('BOOT_STATE',await page.evaluate('window.SG_M1_STATE'),flush=True)
   await page.wait_for_timeout(5000)
   async def state():return await page.evaluate('window.SG_M1_STATE')
   async def tap(key):
    s=await state();rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport']
    await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height'])
    await page.wait_for_timeout(500)
   if (await state())['paused']:
    await tap('Pause')
   await page.wait_for_function('window.SG_M1_STATE?.enemies > 0',timeout=30000)
   initial=await state()
   assert initial['locale']=='zh_TW' and initial['labels']['Pause']=='暫停' and initial['labels']['Fire']=='爆裂火球'
   assert '水晶生命' in initial['status_text']
   await tap('Pause');paused=await state();assert paused['paused'],paused
   await tap('Pause');assert not (await state())['paused']
   await tap('1x');assert (await state())['speed']==2
   assert (await state())['spell_columns']==(4 if label=='portrait' else 8)
   rect=await page.locator('#canvas').bounding_box()
   current=await state()
   for key in ['Fire','Ice','Pause','Chain','Performance']:
    assert current['buttons'][key][3]/current['viewport'][1]*rect['height']>=44,(label,key,'touch target too short')
   await tap('Performance');assert (await state())['performance_visible']
   await tap('Performance');assert not (await state())['performance_visible']
   await tap('Chain');assert (await state())['graph_open']
   assert (await state())['labels']['Add']=='新增' and (await state())['labels']['Done']=='完成並返回'
   edges=lambda value: {(int(e['from']),int(e['to'])) for e in value['edges']}
   before_edges=edges(await state())
   await tap('Source 1');assert (await state())['pending_source']==1
   await tap('Target 3');assert (1,3) in edges(await state())
   await tap('Undo');assert edges(await state())==before_edges
   await tap('Redo');assert (1,3) in edges(await state())
   await tap('Source 3');await tap('Target 1')
   assert (3,1) not in edges(await state()) and '無法連線' in (await state())['link_hint']
   await tap('Cancel link');assert (await state())['pending_source']==-1
   await tap('Link mode');await tap('Source 1');await tap('Target 3')
   assert (1,3) not in edges(await state())
   await tap('Undo');assert (1,3) in edges(await state())
   await tap('Redo');assert edges(await state())==before_edges
   await tap('Link mode')
   scroll=(await state())['graph_scroll']
   await tap('Pan down');assert (await state())['graph_scroll'][1]>scroll[1]
   await tap('Pan up');assert (await state())['graph_scroll']==scroll
   before=(await state())['nodes']
   await page.screenshot(path=str(REPORT/('graph-before-'+label+'.png')))
   print('GRAPH_STATE',await state(),flush=True)
   await tap('Add');assert (await state())['nodes']==before+1
   await tap('Undo');assert (await state())['nodes']==before
   await tap('Redo');assert (await state())['nodes']==before+1
   await page.screenshot(path=str(REPORT/('graph-'+label+'.png')))
   await tap('Done');assert not (await state())['graph_open']
   await tap('Ice');assert (await state())['element']=='ice'
   await tap('Arcane');assert (await state())['element']=='arcane'
   await page.screenshot(path=str(REPORT/('godot-web-'+label+'.png')))
   await tap('Restart');await page.wait_for_timeout(800);restarted=await state();assert restarted['speed']==1 and restarted['element']=='fire' and restarted['hp']==100 and restarted['nodes']==before+1
   assert not errors,errors
   engine_errors=[v for v in logs if 'SCRIPT ERROR' in v['text'] or v['text'].startswith('ERROR:')]
   assert not engine_errors,engine_errors
   results[label]={'viewport':size,'initial':initial,'restart':restarted,'pageerrors':errors,'console':logs,'passed':['WebGL boot','spawns','touch pause/resume','touch speed','touch ice/arcane selection','touch restart','Traditional Chinese HUD and graph labels','graph modal','touch add/undo/redo','two-tap connect/disconnect and cycle rejection','44 CSS pixel battle targets','portrait four-column layout','performance display toggle','build save and scene reload'],'limitations':'Software WebGL on Linux Chromium; no Safari/device performance claim'}
   await page.close()
  await browser.close()
  (REPORT/'web-smoke.json').write_text(json.dumps(results,ensure_ascii=False,indent=2));print(json.dumps({k:v['passed'] for k,v in results.items()},indent=2))
asyncio.run(main())
