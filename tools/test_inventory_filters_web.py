"""Real owned-inventory filters, filtered pagination and confirmation via touch."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1];REPORT=ROOT/'docs/inventory-filters';REPORT.mkdir(exist_ok=True)
p=argparse.ArgumentParser();p.add_argument('--directory',default=str(ROOT/'godot/export/lab'));p.add_argument('--entry',default='/');p.add_argument('--label',default='web');args=p.parse_args()
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=args.directory));threading.Thread(target=server.serve_forever,daemon=True).start()
async def main():
 results={}
 async with async_playwright() as pw:
  browser=await pw.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  try:
   for name,size in [('landscape',{'width':1180,'height':820}),('portrait',{'width':820,'height':1180})]:
    context=await browser.new_context(viewport=size,has_touch=True,device_scale_factor=1);page=await context.new_page();errors=[];logs=[]
    page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:logs.append(m.text))
    await page.goto(f'http://127.0.0.1:{server.server_port}{args.entry}?debug=1&seed=12032')
    async def state():return await page.evaluate('window.SG_LAB_STATE')
    async def wait(condition,timeout=60000):await page.wait_for_function(condition,timeout=timeout)
    async def tap(key):
     s=await state();rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport'];assert 0<=x-w/2 and x+w/2<=vw+1 and 0<=y-h/2 and y+h/2<=vh+1,(key,s['buttons'][key],s['viewport'])
     assert w/vw*rect['width']>=44 and h/vh*rect['height']>=44,(key,w,h,rect)
     await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height']);await page.wait_for_timeout(350)
    await wait('window.SG_LAB_STATE?.inventory_filter_counts!==undefined');await page.wait_for_timeout(650)
    await tap('Configure');await tap('Inventory');fresh=await state();assert fresh['inventory_filter_counts']=={'all':1,'skill':1,'gem':0,'available':0}
    await tap('InventoryFilter gem');empty=await state();assert empty['inventory_filtered_ids']==[] and empty['candidate']==-2 and empty['inventory_apply_disabled']
    await tap('InventoryApply');assert (await state())['slots']==fresh['slots'] and (await state())['item_count']==1
    await page.screenshot(path=str(REPORT/f'empty-{args.label}-{name}.png'))
    await tap('InventoryClose');await tap('Done');await tap('SpellKit');await tap('Inventory');training=await state();assert training['item_count']==32 and training['inventory_filter']=='all'
    scroll_probe=None
    if name=='landscape':
     await page.set_viewport_size({'width':1180,'height':600});await page.wait_for_timeout(650)
     before_scroll=await state();rect=await page.locator('#canvas').bounding_box()
     cdp=await context.new_cdp_session(page);x=rect['x']+rect['width']*.6;start=rect['y']+rect['height']*.92;end=rect['y']+rect['height']*.66
     await cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':x,'y':start}]})
     for step in range(1,11):
      await cdp.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[{'x':x,'y':start+(end-start)*step/10}]});await page.wait_for_timeout(30)
     await cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});await page.wait_for_timeout(600)
     after_scroll=await state()
     assert after_scroll['buttons']['Item 0'][1]<before_scroll['buttons']['Item 0'][1],(before_scroll['buttons']['Item 0'],after_scroll['buttons']['Item 0'])
     for key in ['InventoryApply','InventoryClose','InventoryFilter skill']:assert before_scroll['buttons'][key]==after_scroll['buttons'][key],key
     assert after_scroll['slots']==training['slots'] and after_scroll['item_count']==32 and after_scroll['candidate']==before_scroll['candidate']
     scroll_probe={'before':before_scroll,'after':after_scroll,'input':'Chromium CDP touch drag; not Safari hardware'}
     await page.screenshot(path=str(REPORT/f'scrolled-{args.label}-{name}.png'))
     await page.set_viewport_size(size);await page.wait_for_timeout(650)
    await tap('InventoryFilter skill');skills=await state();skill_ids=skills['inventory_filtered_ids'];assert len(skill_ids)==skills['inventory_filter_counts']['skill'] and len(skill_ids)>15 and -1 not in skill_ids
    await tap('InventoryNext');last=await state();assert last['inventory_page']==1 and last['inventory_visible_ids']==skill_ids[15:30]
    target=skill_ids[-1];await tap(f'Item {target}');preview=await state();assert preview['candidate']==target and not preview['inventory_apply_disabled']
    await tap('InventoryPrev');paged_away=await state();assert paged_away['candidate']==-2 and paged_away['inventory_apply_disabled']
    await tap('InventoryApply');assert (await state())['slots']==training['slots'] and (await state())['inventory_open']
    await tap('InventoryNext');await tap(f'Item {target}');assert (await state())['candidate']==target
    await tap('InventoryClose');closed=await state();assert not closed['inventory_open'] and closed['candidate']==-2 and closed['inventory_apply_disabled'] and closed['slots']==training['slots']
    await tap('Inventory');reopened_cancelled=await state();assert reopened_cancelled['candidate']==training['slots'][0] and reopened_cancelled['inventory_apply_disabled']
    await tap('InventoryFilter skill');await tap('InventoryNext');await tap(f'Item {target}')
    await tap('InventoryFilter gem');gems=await state();assert len(gems['inventory_filtered_ids'])==gems['inventory_filter_counts']['gem'] and gems['candidate']==-2 and gems['inventory_apply_disabled']
    await tap('InventoryApply');unchanged=await state();assert unchanged['inventory_open'] and unchanged['slots']==training['slots'] and unchanged['edges']==training['edges'] and unchanged['item_count']==32
    await tap('InventoryFilter available');available=await state();assert 0 not in available['inventory_filtered_ids'] and not set(available['inventory_filtered_ids']).intersection(training['slots'])
    assert available['inventory_filtered_ids'] and set(available['inventory_filtered_ids']).issubset(skill_ids)
    replacement=available['inventory_visible_ids'][0];await tap(f'Item {replacement}');ready=await state();assert not ready['inventory_apply_disabled']
    await page.screenshot(path=str(REPORT/f'available-{args.label}-{name}.png'))
    await tap('InventoryApply');equipped=await state();assert not equipped['inventory_open'] and equipped['slots'][0]==replacement and equipped['item_count']==32 and equipped['edges']==training['edges']
    await tap('Inventory');reopened=await state();assert reopened['inventory_filter']=='all' and reopened['inventory_page']==0
    await tap('InventoryFilter available');returned=await state();assert 0 in returned['inventory_filtered_ids'] and replacement not in returned['inventory_filtered_ids']
    await tap('InventoryClose');await tap('Done');await wait('window.SG_LAB_STATE.casts>0');battle=await state();assert battle['slots'][0]==replacement and battle['item_count']==32
    engine=[v for v in logs if 'SCRIPT ERROR' in v or v.startswith('ERROR:')];assert not errors and not engine,(errors,engine)
    results[name]={'scroll_probe':scroll_probe,'fresh':fresh,'empty':empty,'skills':skills,'last_skill_page':last,'paged_away':paged_away,'cancelled':closed,'reopened_cancelled':reopened_cancelled,'gem_filter':gems,'available':available,'equipped':equipped,'returned':returned,'battle':battle,'pageerrors':errors,'engine_errors':engine,'passed':['normal start reveals only owned arcane','empty results and hidden preview cannot equip','physical skill IDs paginate correctly','paging away cancels hidden selection and blocks stale confirmation','closing clears preview and reopening selects actual equipment','switching type cancels hidden preview without changing graph','compatible filter excludes occupied items','real touch confirm equips one owned copy and keeps edges','returned item becomes available after reopen','confirmed graph resumes real casting','44 CSS pixel targets fit viewport'],'limit':'Explicit, visibly labelled training inventory used for large-backpack coverage; no gameplay-state injection, iPad Safari hardware, or final-art claim.'}
    print(name,'INVENTORY FILTERS PASS',flush=True);await context.close()
  finally:await browser.close();server.shutdown()
 (REPORT/f'browser-{args.label}.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
asyncio.run(main())
