"""Create clean importable Godot ZIP and separate Web export ZIP."""
import hashlib,pathlib,zipfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
out=ROOT/'dist';out.mkdir(exist_ok=True)
project=out/'SpiritGuardian-Godot-M1.zip'
with zipfile.ZipFile(project,'w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted((ROOT/'godot').rglob('*')):
  relative=p.relative_to(ROOT/'godot')
  if p.is_file() and not any(v in {'.godot','export'} for v in relative.parts):z.write(p,relative)
 for name in ['AUDIT.md','FEATURES.md','ARCHITECTURE.md','TESTING.md','asset-manifest.json','source-inventory.json','godot-integration.json','web-smoke.json','godot-web-landscape.png','godot-web-portrait.png']:
  p=ROOT/'docs'/name
  if p.exists():z.write(p,'migration_docs/'+name)
 z.write(ROOT/'LICENSE-GODOT-CODE.md','LICENSE-GODOT-CODE.md')
with zipfile.ZipFile(project) as z:
 assert 'project.godot' in z.namelist() and 'scenes/main.tscn' in z.namelist()
 assert not any(n.startswith(('.godot/','export/')) for n in z.namelist())
web=ROOT/'godot/export/web'
if (web/'index.html').exists():
 with zipfile.ZipFile(out/'SpiritGuardian-Web-M1.zip','w',zipfile.ZIP_DEFLATED) as z:
  for p in sorted(web.iterdir()):
   if p.is_file():z.write(p,p.name)
for p in out.glob('*.zip'):
 print(p.name,p.stat().st_size,hashlib.sha256(p.read_bytes()).hexdigest())
