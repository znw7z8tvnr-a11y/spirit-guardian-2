"""Extract unchanged embedded images; no new license is granted by extraction."""
import base64,hashlib,json,pathlib,re
from PIL import Image
ROOT=pathlib.Path(__file__).resolve().parents[1]
s=(ROOT/'spirit_guardian_v32_fusion_test.html').read_text()
a=json.loads(re.search(r'const SG_ASSET_DATA=(\{.*?\});',s).group(1))
a['arena']=re.search(r'SG61_ARENA.src="([^"]+)"',s).group(1)
out=ROOT/'godot/assets/legacy';out.mkdir(parents=True,exist_ok=True)
manifest=[]
for name in ['arena','tower_guardian','enemy_demon','enemy_wolf','enemy_knight','fireball','icebolt','lightning','arcane','walk_grunt','walk_swift','walk_armored','platform']:
 raw=base64.b64decode(a[name].split(',')[1]);p=out/(name+'.webp');p.write_bytes(raw)
 manifest.append({'file':p.relative_to(ROOT).as_posix(),'source':'spirit_guardian_v32_fusion_test.html','key':name,'sha256':hashlib.sha256(raw).hexdigest(),'size':Image.open(p).size,'license':'UNVERIFIED: temporary internal migration reference'})
terrain=out/'terrain.png'
if terrain.exists():
 manifest.append({'file':terrain.relative_to(ROOT).as_posix(),'source':'spirit_guardian_v32_fusion_test.html: SGBackground.canvas.toDataURL()','sha256':hashlib.sha256(terrain.read_bytes()).hexdigest(),'size':[1280,720],'license':'UNVERIFIED: temporary internal migration reference'})
(ROOT/'docs/asset-manifest.json').write_text(json.dumps(manifest,indent=2));print(json.dumps(manifest,indent=2))
