"""Real touch selection and direct-modifier trace acceptance; no gameplay state injection."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1];REPORT=ROOT/'docs/run-results';REPORT.mkdir(exist_ok=True)
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
    async def tap(key,settle=500):
     s=await state()
     if key.startswith('Item '):
      target=(int(key.split()[1])+1)//15
      for attempt in range(4):
       if s['inventory_page']==target:break
       await tap('InventoryNext' if target>s['inventory_page'] else 'InventoryPrev');s=await state()
      assert s['inventory_page']==target,(key,s['inventory_page'],target)
     rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport'];assert 0<=x<=vw and 0<=y<=vh,(key,[x,y],s['viewport'])
     await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height']);await page.wait_for_timeout(settle)
    initial=await state();assert initial['item_count']==1 and initial['slots']==[0]+[-1]*9 and not initial['run_outcome']
    for speed in [2,4,8]:await tap('Speed');assert (await state())['speed']==speed
    skills=1;gems=0;claimed=0;waves=[];deadlines=asyncio.get_running_loop().time()+210
    while True:
     s=await state()
     if s['run_outcome']:break
     assert asyncio.get_running_loop().time()<deadlines,{'wave':s['wave'],'pending':s['reward_pending'],'core':s['hp'],'clock':s['combat_seconds']}
     if not waves or waves[-1]!=s['wave']:waves.append(s['wave'])
     if s['reward_pending']>0:
      offers=s['reward_offers'];pick=0
      for i,item in enumerate(offers):
       if (gems<skills and item['kind']=='gem') or (gems>=skills and skills<5 and item['kind']=='skill') or (gems>=skills and skills>=5 and item['kind']=='affix' and item['key']=='power'):pick=i;break
      item=offers[pick];before=s['item_count'];await tap(f'Reward {pick}');after=await state();claimed+=1
      if item['kind']=='skill':skills+=1
      elif item['kind']=='gem':gems+=1
      assert after['item_count']==before+(0 if item['kind']=='affix' else 1)
      assert after['combat_seconds']==s['combat_seconds']
     elif s['edit_open']:await tap('Random');await tap('Done')
     else:await page.wait_for_timeout(350)
    victory=await state();assert victory['run_outcome']=='victory' and victory['result_visible'] and victory['wave']==20 and victory['boss_kills']==4
    assert not victory['kit'] and not victory['enemy_drill'] and not victory['run_summary']['training'] and victory['reward_pending']==0
    assert victory['run_summary']['awards']==claimed and victory['run_summary']['cleared_waves']==20 and set(range(1,21)).issubset(set(waves))
    clock=victory['combat_seconds'];summary=victory['run_summary'];await page.wait_for_timeout(1000);held=await state();assert held['combat_seconds']==clock and held['run_summary']==summary
    await page.screenshot(path=str(REPORT/f'victory-{args.label}-{orientation}.png'))
    await tap('ResultRestart');await page.wait_for_function("window.SG_LAB_STATE.run_outcome===''&&window.SG_LAB_STATE.item_count===1",timeout=15000)
    fresh=await state();assert fresh['slots']==[0]+[-1]*9 and fresh['hp']==100 and fresh['wall_hp']==360 and fresh['flesh']==0 and fresh['reward_granted']==0 and fresh['boss_kills']==0 and fresh['speed']==1 and not fresh['result_visible']
    assert all(v==0 for v in fresh['growth_levels'].values()) and fresh['discovered']==victory['discovered']
    assert fresh['reward_attack_stacks']==0 and fresh['reward_extra_refresh']==0
    await tap('Configure');await tap('CrowdDrill')
    for speed in [2,4,8]:await tap('Speed')
    await page.wait_for_function("window.SG_LAB_STATE.run_outcome==='defeat'",timeout=45000)
    defeat=await state();assert defeat['result_visible'] and defeat['hp']==0 and defeat['run_summary']['training'] and defeat['run_summary']['outcome']=='defeat'
    await page.screenshot(path=str(REPORT/f'defeat-drill-{args.label}-{orientation}.png'))
    await tap('ResultRestart');await page.wait_for_function("window.SG_LAB_STATE.run_outcome===''&&window.SG_LAB_STATE.item_count===1",timeout=15000)
    restarted=await state();assert not restarted['enemy_drill'] and restarted['reward_granted']==0 and restarted['slots']==[0]+[-1]*9
    engine_errors=[v for v in logs if 'SCRIPT ERROR' in v or v.startswith('ERROR:')];assert not errors and not engine_errors,(errors,engine_errors)
    results[orientation]={'initial':initial,'waves_seen':waves,'claimed':claimed,'victory':victory,'fresh_after_victory':fresh,'defeat_drill':defeat,'fresh_after_defeat':restarted,'pageerrors':errors,'engine_errors':engine_errors,'passed':['twenty real waves from arcane-only start with earned rewards and touch auto-arrangement','four actual Boss kills and final rewards before victory','read-only frozen victory summary','restart clears run growth, inventory and reward history while existing book remains','real crowd-drill lethal defeat is marked training','touch restart works after both outcomes'],'limit':'One seeded browser policy per orientation plus a separately marked drill defeat. Not all random builds, iPad Safari hardware, final balance or a persistent run-history feature.'}
    print(orientation,'FULL RUN RESULT PASS',victory['run_summary'],flush=True);await page.close()
  finally:await browser.close()
 (REPORT/f'run-results-{args.label}.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
try:asyncio.run(main())
finally:server.shutdown();server.server_close()
