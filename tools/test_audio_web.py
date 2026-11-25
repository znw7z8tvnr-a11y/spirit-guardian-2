"""Trusted touch audio toggle plus Web Audio output analysis; not a listening test."""
import argparse,asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--directory',default=str(ROOT/'godot/export/web'));p.add_argument('--report-dir',type=pathlib.Path,default=ROOT/'docs/audio-pool/browser');args=p.parse_args();args.report_dir.mkdir(parents=True,exist_ok=True)
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=args.directory));threading.Thread(target=server.serve_forever,daemon=True).start()
PROBE=r'''(() => {
 const p={maxAbs:0,samples:0,links:[],errors:[]};window.SG_AUDIO_PROBE=p;
 const watched=new WeakSet();const original=AudioNode.prototype.connect;
 AudioNode.prototype.connect=function(...args){
  const result=original.apply(this,args);
  if(args[0]===this.context.destination && !watched.has(this) && p.links.length<8){
   watched.add(this);
   try {const analyser=this.context.createAnalyser();analyser.fftSize=512;analyser.smoothingTimeConstant=0;
    original.call(this,analyser);p.links.push({analyser,data:new Float32Array(512)});
   } catch(error){p.errors.push(String(error));}
  }
  return result;
 };
 p.reset=()=>{p.maxAbs=0;p.samples=0;};
 p.snapshot=()=>({maxAbs:p.maxAbs,samples:p.samples,analysers:p.links.length,states:p.links.map(x=>x.analyser.context.state),errors:p.errors.slice()});
 setInterval(()=>{for(const link of p.links){link.analyser.getFloatTimeDomainData(link.data);for(const v of link.data)p.maxAbs=Math.max(p.maxAbs,Math.abs(v));p.samples++;}},5);
})();'''
async def main():
 results={}
 async with async_playwright() as pw:
  browser=await pw.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox','--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader'])
  try:
   for name,size in [('landscape',{'width':1180,'height':820}),('portrait',{'width':820,'height':1180})]:
    context=await browser.new_context(viewport=size,has_touch=True,device_scale_factor=1);await context.add_init_script(PROBE);page=await context.new_page();errors=[];logs=[]
    page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:logs.append(m.text))
    await page.goto(f'http://127.0.0.1:{server.server_port}/index.html?debug=1')
    await page.wait_for_function('window.SG_M1_STATE?.enemies>0',timeout=60000)
    async def state():return await page.evaluate('window.SG_M1_STATE')
    async def probe():return await page.evaluate('window.SG_AUDIO_PROBE.snapshot()')
    async def tap(key):
     s=await state();rect=await page.locator('#canvas').bounding_box();x,y,w,h=s['buttons'][key];vw,vh=s['viewport']
     assert w/vw*rect['width']>=44 and h/vh*rect['height']>=44,(key,w,h,rect)
     assert 0<=x-w/2<x+w/2<=vw+1 and 0<=y-h/2<y+h/2<=vh+1,(key,s['buttons'][key])
     await page.touchscreen.tap(rect['x']+x/vw*rect['width'],rect['y']+y/vh*rect['height']);await page.wait_for_timeout(500)
    await page.wait_for_timeout(1000);initial=await state();muted=await probe()
    assert initial['labels']['Audio: off']=='音效：關' and muted['maxAbs']<=0.00001,muted
    await tap('Audio: off');assert (await state())['labels']['Audio: off']=='音效：開'
    await page.wait_for_function('window.SG_AUDIO_PROBE.maxAbs>0.00001',timeout=15000);playing=await probe();assert playing['analysers']>0 and not playing['errors'],playing
    await tap('Ice');await page.wait_for_timeout(1500)
    await tap('Audio: off');assert (await state())['labels']['Audio: off']=='音效：關'
    await page.wait_for_timeout(400);await page.evaluate('window.SG_AUDIO_PROBE.reset()');await page.wait_for_timeout(1000);silent=await probe()
    assert silent['maxAbs']<=0.00001,silent
    await tap('Audio: off');await page.wait_for_function('window.SG_AUDIO_PROBE.maxAbs>0.00001',timeout=15000);resumed=await probe()
    await page.screenshot(path=str(args.report_dir/f'audio-{name}.png'))
    await tap('Audio: off')
    engine=[v for v in logs if 'SCRIPT ERROR' in v or v.startswith('ERROR:')];assert not errors and not engine,(errors,engine)
    results[name]={'muted':muted,'playing':playing,'silent':silent,'resumed':resumed,'pageerrors':errors,'engine_errors':engine,'passed':['default muted UI','trusted touch enables audio','nonzero master output observed','muting returns output to silence after short existing tail','touch re-enable restores output','44 CSS pixel audio target'],'limit':'Web Audio analyser side-branch observes actual browser output; no game-state injection or autoplay-policy bypass, no human listening or iPad Safari claim. This is stable M2, not Lab audio integration.'}
    print(name,'AUDIO PASS',flush=True);await context.close()
  finally:await browser.close();server.shutdown()
 (args.report_dir/'audio-web.json').write_text(json.dumps(results,ensure_ascii=False,indent=2))
asyncio.run(main())
