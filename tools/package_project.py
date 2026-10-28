"""Create clean M2 project, Web export and untouched reference-module ZIPs."""
import hashlib,pathlib,zipfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
out=ROOT/'dist';out.mkdir(exist_ok=True)
project=out/'SpiritGuardian-Godot-M2.1-zh-Hant.zip'
with zipfile.ZipFile(project,'w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted((ROOT/'godot').rglob('*')):
  relative=p.relative_to(ROOT/'godot')
  if p.is_file() and not any(v in {'.godot','export'} for v in relative.parts):z.write(p,relative)
 for name in ['AUDIT.md','FEATURES.md','ARCHITECTURE.md','TESTING.md','M2_MODULES.md','M2_TESTING.md','M2_ZH.md','M2_1.md','asset-manifest.json','source-inventory.json','supplement-manifest.json','supplement-html-smoke.json']:
  p=ROOT/'docs'/name
  if p.exists():z.write(p,'migration_docs/'+name)
 for p in sorted((ROOT/'docs/m2-1').glob('*')):
  if p.is_file() and p.suffix in ['.json','.png','.log']:z.write(p,'migration_docs/m2-1/'+p.name)
 z.write(ROOT/'LICENSE-GODOT-CODE.md','LICENSE-GODOT-CODE.md')
with zipfile.ZipFile(project) as z:
 assert 'project.godot' in z.namelist() and 'scenes/main.tscn' in z.namelist()
 assert not any(n.startswith(('.godot/','export/')) for n in z.namelist())
web=ROOT/'godot/export/web'
if (web/'index.html').exists():
 with zipfile.ZipFile(out/'SpiritGuardian-Web-M2.1-zh-Hant.zip','w',zipfile.ZIP_DEFLATED) as z:
  for p in sorted(web.iterdir()):
   if p.is_file():z.write(p,p.name)
with zipfile.ZipFile(out/'SpiritGuardian-ReferenceModules.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted((ROOT/'reference_modules').glob('*.html')):z.write(p,'reference_modules/'+p.name)
 z.write(ROOT/'docs/supplement-manifest.json','supplement-manifest.json')
 z.writestr('LICENSE_STATUS.txt','User-provided reference HTML preserved unchanged. Original licensing has not been established; this archive does not grant new rights to existing artwork or code. See source attribution in supplement-manifest.json.')
files=[project,out/'SpiritGuardian-Web-M2.1-zh-Hant.zip',out/'SpiritGuardian-ReferenceModules.zip']
sums=[]
for p in files:
 if p.exists():
  digest=hashlib.sha256(p.read_bytes()).hexdigest();print(p.name,p.stat().st_size,digest);sums.append(digest+'  '+p.name)
(out/'M2-SHA256SUMS.txt').write_text('\n'.join(sums)+'\n')
