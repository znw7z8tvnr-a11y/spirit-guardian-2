"""Standalone lab import ZIP selects lab scene; repository default remains M2.1."""
import hashlib,pathlib,zipfile
ROOT=pathlib.Path(__file__).resolve().parents[1];out=ROOT/'dist';out.mkdir(exist_ok=True)
project=out/'SpiritGuardian-Godot-ChainLab.zip'
with zipfile.ZipFile(project,'w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted((ROOT/'godot').rglob('*')):
  rel=p.relative_to(ROOT/'godot')
  if p.is_file() and not any(v in {'.godot','export'} for v in rel.parts):
   if str(rel)=='project.godot':z.writestr(str(rel),p.read_text().replace('run/main_scene="res://scenes/main.tscn"','run/main_scene="res://experiments/chain_lab/main.tscn"'))
   else:z.write(p,rel)
 z.write(ROOT/'docs/CHAIN_FLOW.md','CHAIN_FLOW.md');
 z.write(ROOT/'docs/CHAIN_LAB.md','CHAIN_LAB.md');z.write(ROOT/'LICENSE-GODOT-CODE.md','LICENSE-GODOT-CODE.md')
 for p in sorted((ROOT/'docs/chain-flow').glob('*')):
  if p.is_file():z.write(p,'test_reports/'+p.name)
web=out/'SpiritGuardian-Web-ChainLab.zip'
with zipfile.ZipFile(web,'w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted((ROOT/'godot/export/lab').iterdir()):
  if p.is_file():z.write(p,p.name)
for p in [project,web]:print(p.name,p.stat().st_size,hashlib.sha256(p.read_bytes()).hexdigest())
