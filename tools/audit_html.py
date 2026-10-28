"""Read-only browser smoke: not a balance or iPad certification test."""
import asyncio,json,pathlib,threading,http.server,functools,base64,os
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1]
server=http.server.ThreadingHTTPServer(('127.0.0.1',8765),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(ROOT)))
threading.Thread(target=server.serve_forever,daemon=True).start()
async def main():
 async with async_playwright() as p:
  b=await p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox'])
  async def run(name):
   page=await b.new_page(viewport={'width':1180,'height':820},has_touch=True)
   errors=[]; page.on('pageerror',lambda e: errors.append(str(e)))
   await page.goto('http://127.0.0.1:8765/'+name); await page.wait_for_timeout(1200)
   await page.locator('#start').click(); await page.wait_for_timeout(15000)
   result=await page.evaluate('''() => ({title:document.title,state:SGBridge.getState(),wave:SGBridge.getWave(),kills:SGBridge.getKills(),enemies:SGBridge.getEnemies().length,chain:window.SGChain?.stats?.(),bossAPI:!!window.SG_BOSS,backgroundAPI:!!window.SGBackground,images:[...document.images].filter(i=>!i.complete||!i.naturalWidth).length})''')
   result['diagnostics']=await page.evaluate('window.SG311Diagnostics?.() || null'); await page.evaluate("document.getElementById('sg311Dismiss')?.click()"); await page.locator('#pause').click(force=True); result['pause']=await page.evaluate('SGBridge.getState()'); await page.locator('#pause').click(force=True)
   if name.startswith('spirit_guardian_v34'):
    await page.locator('#sgABModule').click(); await page.wait_for_timeout(1000); result['backgroundMode']=await page.evaluate('SG_AB_BACKGROUND_MODE')
   result['errors']=errors[:20]; result['errorCount']=len(errors)
   if name=='spirit_guardian_v32_fusion_test.html':
    data=await page.evaluate('SGBackground.canvas.toDataURL()'); (ROOT/'godot/assets/legacy/terrain.png').write_bytes(base64.b64decode(data.split(',')[1]))
   await page.screenshot(path=str(ROOT/'docs'/('html-'+name+'.png')))
   await page.close(); return name,result
  out=dict(await asyncio.gather(*[run(n) for n in ['index.html','spirit_guardian_v32_fusion_test.html','spirit_guardian_v33_tower_depth_test.html','spirit_guardian_v34_ab_altar_test.html']]))
  (ROOT/'docs/html-smoke.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)); print(json.dumps(out,ensure_ascii=False,indent=2)); await b.close()
asyncio.run(main())
