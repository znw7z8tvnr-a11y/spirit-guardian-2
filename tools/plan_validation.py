"""Conservative changed-file selection; unknown game dependencies require full regression."""
import argparse,json,pathlib,subprocess
ROOT=pathlib.Path(__file__).resolve().parents[1]
BROWSERS=[pathlib.Path(p).name for p in json.loads((ROOT/'tools/validation_suites.json').read_text())]
# Only isolated helpers have narrow dependency rules. Shared or unknown game code expands to full.
RULES={
 'reward_reroll.gd':(['reroll','rewards','checkpoint'],['test_reward_reroll_web.py','test_checkpoint_web.py']),
 'inventory_filter.gd':(['inventoryfilters','inventory','tree'],['test_inventory_filters_web.py']),
 'inventory_view.gd':(['inventoryfilters','inventory','tree','touch'],['test_inventory_filters_web.py']),
 'enemy_presentation.gd':(['readability','enemytactics'],['test_enemy_readability_web.py','test_enemy_tactics_web.py']),
}
def select(paths,profile):
 native={'integration','modules','localization','touch'}; browsers=set(); reasons=[]
 full=profile=='full'
 for path in paths:
  name=pathlib.PurePosixPath(path).name
  if path.startswith('godot/experiments/chain_lab/') and name in RULES:
   n,b=RULES[name];native.update(n);browsers.update(b);reasons.append(f'{path}: isolated helper dependency rule')
  elif path.startswith('tools/test_') and name in BROWSERS:
   browsers.add(name);reasons.append(f'{path}: rerun changed browser test')
  elif path.startswith(('godot/','reference_modules/')) or path in ('tools/check_godot.py','tools/validation_suites.json','tools/build_supplement_catalog.py'):
   # Runner/manifest edits validate the runner separately; never silently narrow game changes.
   if path.startswith(('godot/','reference_modules/')) or name=='build_supplement_catalog.py':full=True
   reasons.append(f'{path}: '+('shared dependency, full coverage' if full else 'validation infrastructure'))
  elif path.startswith('tools/') and name not in ('plan_validation.py','test_validation_plan.py'):
   full=True;reasons.append(f'{path}: unknown tool dependency, full coverage')
 if profile=='integration':
  native.update(['chainlab','flow','reroll','rewards','inventory','checkpoint','earlywave','firstboss','flesh'])
  browsers.update(['test_chain_lab_web.py','test_reward_reroll_web.py','test_checkpoint_web.py','test_first_boss_web.py'])
 if full:
  native_arg='';browsers=set(BROWSERS)
 else:native_arg=','.join(sorted(native))
 return {'profile':'full' if full else profile,'native':native_arg,'browsers':sorted(browsers),'changed_files':paths,'reasons':reasons,'coverage_note':'Full regression' if full else 'Partial validation; 20-wave and all-skill regression omitted unless explicitly selected.'}
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--profile',choices=['focused','integration','full'],default='focused');p.add_argument('--base',default='');p.add_argument('--github-output');p.add_argument('--files',nargs='*');a=p.parse_args()
 if a.files is not None:paths=a.files
 elif not a.base or set(a.base)=={'0'}:
  paths=[];a.profile='full' # No trustworthy comparison: fail closed.
 else:
  try:paths=subprocess.check_output(['git','diff','--name-only',a.base,'HEAD'],cwd=ROOT,text=True).splitlines()
  except subprocess.CalledProcessError:paths=[];a.profile='full'
 result=select(paths,a.profile);result['source_sha']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
 out=ROOT/'qa/selection.json';out.parent.mkdir(exist_ok=True);out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');print(out.read_text())
 if a.github_output:
  with open(a.github_output,'a') as f:
   for k in ['profile','native','browsers']:f.write(k+'='+(json.dumps(result[k]) if k=='browsers' else result[k])+'\n')
if __name__=='__main__':main()
