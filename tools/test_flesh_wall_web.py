"""Real WebGL starter balance, flesh upgrades, true simulation speed and restart."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading,time
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1]
REPORT=ROOT/'docs/inventory';REPORT.mkdir(parents=True,exist_ok=True)
p=argparse.ArgumentParser();p.add_argument('--directory',default=str(ROOT/'godot/export/lab'));p.add_argument('--entry',default='/');p.add_argument('--report',default='flesh-web-smoke.json');args=p.parse_args()
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=args.directory))
threading.Thread(target=server.serve_forever,daemon=True).start()
async def main():
 results={}
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  for name,size in [('landscape',{'width':1180,'height':820}),('portrait',{'width':820,'height':1180})]:
   page=await browser.new_page(viewport=size,has_touch=True,device_scale_factor=1)
   errors=[];logs=[];page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:logs.append({'type':m.type,'text':m.text}))
   await page.goto(f'http://127.0.0.1:{server.server_port}{args.entry}?debug=1&seed=12032')
   await page.wait_for_function('window.SG_LAB_STATE?.wall_hp!==undefined',timeout=60000)
   async def state():return await page.evaluate('window.SG_LAB_STATE')
   async def tap(key):
    s=await state();rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport']
    await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height']);await page.wait_for_timeout(650)
   initial=await state();assert initial['wall_max']==360 and initial['hp']==100 and initial['speed']==1 and not initial['kit']
   # Compare elapsed simulation time against real time with no game-data injection.
   start=await state();real_start=time.monotonic();await page.wait_for_timeout(1500);end=await state();real_end=time.monotonic()
   base_rate=(end['combat_seconds']-start['combat_seconds'])/(real_end-real_start)
   for expected in [2,4,8]:
    await tap('Speed')
    print(name,'speed',expected,'observed',(await state())['speed'],flush=True)
    await page.screenshot(path=str(REPORT/f'flesh-speed-{name}.png'))
    await page.wait_for_function('(value)=>window.SG_LAB_STATE.speed===value',arg=expected,timeout=10000)
   start=await state();real_start=time.monotonic();await page.wait_for_timeout(1500);end=await state();real_end=time.monotonic()
   fast_rate=(end['combat_seconds']-start['combat_seconds'])/(real_end-real_start)
   assert fast_rate>4 and fast_rate>base_rate*3,(base_rate,fast_rate)
   await tap('Pause');paused=await state();await page.wait_for_timeout(1200);later=await state()
   assert later['paused'] and later['combat_seconds']==paused['combat_seconds'] and later['absorbed']==paused['absorbed']
   await tap('Flesh');assert (await state())['growth_open']
   await tap('AutoGrowth');assert not (await state())['auto_growth']
   await tap('GrowthDone');assert (await state())['paused'] # does not resume a user-paused game
   await tap('Pause');assert not (await state())['paused']
   await page.wait_for_function('window.SG_LAB_STATE.flesh>=6+7*window.SG_LAB_STATE.growth_levels.atk',timeout=90000)
   await tap('Flesh');before=await state();await page.screenshot(path=str(REPORT/f'flesh-menu-{name}.png'))
   await page.wait_for_timeout(1000);assert (await state())['combat_seconds']==before['combat_seconds']
   await tap('Grow atk');after=await state()
   assert after['growth_levels']['atk']==before['growth_levels']['atk']+1
   assert after['flesh']==before['flesh']-(6+7*before['growth_levels']['atk'])
   await tap('AutoGrowth');assert (await state())['auto_growth']
   await tap('GrowthDone')
   await page.wait_for_function('window.SG_LAB_STATE.wave>=4 && window.SG_LAB_STATE.hp>0',timeout=90000)
   battle=await state();assert not battle['kit'] and battle['slots']==[0]+[-1]*9 and battle['absorbed']>=72
   assert battle['attack_multiplier']>1 and battle['defense']>0 and battle['regen']>0
   await page.screenshot(path=str(REPORT/f'flesh-battle-{name}.png'))
   # Closing/restarting at 8x must reset both temporary growth and global speed.
   await tap('Restart');await page.wait_for_timeout(1000);reset=await state()
   assert reset['speed']==1 and reset['absorbed']==0 and reset['wall_max']==360 and reset['growth_levels']=={'atk':0,'hp':0,'armor':0,'regen':0}
   engine_errors=[m for m in logs if 'SCRIPT ERROR' in m['text'] or m['text'].startswith('ERROR:')]
   assert not errors and not engine_errors,(errors,engine_errors)
   results[name]={'viewport':size,'initial':initial,'battle':battle,'restart':reset,'rate_1x':base_rate,'rate_8x':fast_rate,'pageerrors':errors,'engine_errors':engine_errors,'passed':['actual WebGL starter with wall/core','global 2/4/8 speed','simulation-time acceleration observed','pause freezes combat at 8x','growth menu freezes combat','user pause preserved on menu close','auto-growth toggle','manual upgrade cost and attack increase','arcane-only clears third wave without kit','meat feeds all four stats','restart clears growth and restores 1x'],'limit':'Linux Chromium software WebGL touch emulation, not iPad Safari or full twenty-wave balance'}
   print(name,'PASS',{'wave':battle['wave'],'absorbed':battle['absorbed'],'rate_1x':base_rate,'rate_8x':fast_rate},flush=True)
   await page.close()
  await browser.close()
 (REPORT/args.report).write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n')
asyncio.run(main())
