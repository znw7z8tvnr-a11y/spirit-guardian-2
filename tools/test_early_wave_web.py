"""Real touch early-wave controls and checkpoint recovery; no gameplay injection."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1];REPORT=ROOT/'docs/early-wave';REPORT.mkdir(exist_ok=True)
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
    async def wait(condition,timeout=90000):await page.wait_for_function(condition,timeout=timeout)
    async def tap(key,settle=350):
     s=await state();rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport']
     assert 0<=x-w/2 and x+w/2<=vw+1 and 0<=y-h/2 and y+h/2<=vh+1,(key,s['buttons'][key],s['viewport'])
     if key in ['NextWave','Speed','Configure']:assert w/vw*rect['width']>=44 and h/vh*rect['height']>=44,(key,w,h,rect)
     await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height']);await page.wait_for_timeout(settle)
    await wait('window.SG_LAB_STATE?.early_wave_enabled===true');initial=await state();assert initial['wave']==0 and initial['item_count']==1
    await tap('NextWave');await wait('window.SG_LAB_STATE.wave===1');started=await state();assert started['reward_granted']==0 and not started['early_wave_enabled']
    await tap('NextWave');assert (await state())['wave']==1
    await tap('Pause');paused=await state();assert paused['paused'] and paused['early_wave_blocked_by']=='paused' and not paused['early_wave_enabled']
    await tap('NextWave');held=await state();assert held['combat_seconds']==paused['combat_seconds'] and held['wave']==1
    await tap('Pause')
    await wait("window.SG_LAB_STATE.wave===1&&window.SG_LAB_STATE.early_wave_enabled&&window.SG_LAB_STATE.early_wave_blocked_by===''")
    cleared=await state();assert 1 in cleared['reward_completed'] and cleared['enemies']==0
    await page.screenshot(path=str(REPORT/f'intermission-{args.label}-{name}.png'))
    await tap('NextWave');await wait('window.SG_LAB_STATE.wave===2');second=await state();assert second['checkpoint_wave']==1 and second['item_count']==1 and second['reward_granted']==0
    await page.reload();await wait('window.SG_LAB_STATE?.resume_pending===true')
    await tap('CheckpointResume');await wait('window.SG_LAB_STATE.wave===1&&window.SG_LAB_STATE.early_wave_enabled');restored=await state();assert restored['reward_completed']==[1] and restored['reward_granted']==0
    await tap('Configure');assert (await state())['early_wave_blocked_by']=='configuration' and not (await state())['early_wave_enabled']
    await tap('Done');await tap('NextWave');await wait('window.SG_LAB_STATE.wave===2')
    await wait('window.SG_LAB_STATE.wave===3&&window.SG_LAB_STATE.reward_pending===1',150000)
    reward=await state();assert reward['early_wave_blocked_by']=='reward' and not reward['early_wave_enabled']
    pick=next(i for i,v in enumerate(reward['reward_offers']) if v['kind']=='gem');await tap(f'Reward {pick}');assert (await state())['edit_open'] and (await state())['early_wave_blocked_by']=='configuration'
    await tap('Random');await tap('Done');await wait('window.SG_LAB_STATE.early_wave_enabled===true');await tap('NextWave');await wait('window.SG_LAB_STATE.wave===4')
    fourth=await state();assert fourth['reward_granted']==1 and fourth['item_count']==2 and fourth['reward_pending']==0 and fourth['checkpoint_wave']==3
    await tap('NextWave');assert (await state())['wave']==4
    await page.screenshot(path=str(REPORT/f'wave-four-{args.label}-{name}.png'))
    engine=[v for v in logs if 'SCRIPT ERROR' in v or v.startswith('ERROR:')];assert not errors and not engine,(errors,engine)
    results[name]={'initial':initial,'cleared':cleared,'started_second':second,'restored':restored,'third_reward':reward,'fourth':fourth,'pageerrors':errors,'engine_errors':engine,'passed':['touch skips only opening wait','combat and paused touches cannot skip','actual first-wave clear permits one next wave','latest safe state remains recoverable after early start','configuration and real third-wave reward block advancement','confirmed earned loadout starts wave four without new items or grants','44 CSS pixel controls fit viewport'],'limits':'One normal seeded policy at 1x per orientation, Linux Chromium WebGL; no iPad Safari hardware or final-balance claim.'}
    print(name,'EARLY WAVE PASS',flush=True);await context.close()
  finally:await browser.close();server.shutdown()
 (REPORT/f'browser-{args.label}.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
asyncio.run(main())
