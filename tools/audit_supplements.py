"""Read-only source smoke. Errors are reported, not patched in original attachments."""
import asyncio,functools,http.server,json,os,pathlib,threading
from playwright.async_api import async_playwright
ROOT=pathlib.Path(__file__).resolve().parents[1]
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(ROOT/'reference_modules')))
threading.Thread(target=server.serve_forever,daemon=True).start()
async def main():
 async with async_playwright() as p:
  b=await p.chromium.launch(executable_path=os.environ.get('CHROMIUM_PATH'),headless=True,args=['--no-sandbox'])
  out={};limit=asyncio.Semaphore(2)
  async def run(path):
   async with limit:
    page=await b.new_page(viewport={'width':1180,'height':820},has_touch=True);errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    await page.goto(f'http://127.0.0.1:{server.server_port}/{path.name}');await page.wait_for_timeout(500)
    if await page.locator('#start').count():await page.locator('#start').click(force=True)
    if path.name=='spirit_guardian_boss_v5_playable.html':await page.locator('#attack').click()
    await page.wait_for_timeout(4000)
    data=await page.evaluate('''() => ({title:document.title,state:window.SGBridge?.getState?.(),enemies:window.SGBridge?.getEnemies?.().length,chain:window.SGChain?.version,chainDebug:window.SGChain?.debug?.(),ui:!!window.SG_UI_FINAL,audio:!!window.SGModule11,resonanceZones:!!window.SGResonanceZones,combatFX:!!window.SGCombatFinal,boss:window.SG_BOSS?.version,background:!!window.SGBackground})''')
    data['errors']=errors[:10];data['errorCount']=len(errors);out[path.name]=data;await page.close()
  await asyncio.gather(*[run(p) for p in sorted((ROOT/'reference_modules').glob('*.html'))]);await b.close()
  (ROOT/'docs/supplement-html-smoke.json').write_text(json.dumps(out,ensure_ascii=False,indent=2));print(json.dumps(out,ensure_ascii=False,indent=2))
asyncio.run(main())
