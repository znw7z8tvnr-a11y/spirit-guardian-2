"""Conservative changed-file selection; unknown game dependencies require full regression."""
import argparse,json,pathlib,subprocess
ROOT=pathlib.Path(__file__).resolve().parents[1]
BROWSERS=[pathlib.Path(p).name for p in json.loads((ROOT/'tools/validation_suites.json').read_text())]
# Only isolated helpers have narrow dependency rules. Shared or unknown game code expands to full.
RULES={
 'orbit_fx.gd':(['orbit','chainlab','touch'],['test_orbit_visuals_web.py']),
 'guardian_actor.gd':(['guardians','skeleton','checkpoint','touch'],['test_guardian_visuals_web.py']),
 'audio_controller.gd':(['labaudio','audio','chainlab','checkpoint','inventoryfilters','touch'],['test_lab_audio_web.py','test_inventory_filters_web.py','test_checkpoint_web.py']),
 'tree_view.gd':(['tree','inventory','inventoryfilters','touch'],['test_chain_lab_web.py','test_inventory_filters_web.py']),
 'checkpoint_view.gd':(['checkpoint','touch'],['test_checkpoint_web.py']),
 'reward_view.gd':(['rewardinput','reroll','rewards','checkpoint','touch'],['test_reward_reroll_web.py']),
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
  if path == 'godot/experiments/chain_lab/'+name and name in RULES:
   n,b=RULES[name];native.update(n);browsers.update(b);reasons.append(f'{path}: isolated helper dependency rule')
  elif path=='godot/tests/orbit_spell.gd':
   n,b=RULES['orbit_fx.gd'];native.update(n);browsers.update(b);reasons.append(f'{path}: orbit presentation regression')
  elif path in ('godot/experiments/chain_lab/assets/ghost_strike.tres','godot/tests/ghost_guardian.gd','godot/tests/skeleton_guardian.gd'):
   n,b=RULES['guardian_actor.gd'];native.update(n);browsers.update(b);reasons.append(f'{path}: guardian presentation regression')
  elif path in ('godot/experiments/chain_lab/audio_controller.gd.uid','godot/tests/lab_audio.gd','godot/tests/lab_audio.gd.uid'):
   n,b=RULES['audio_controller.gd'];native.update(n);browsers.update(b);reasons.append(f'{path}: Lab audio observer regression')
  elif path in ('godot/modules/audio/audio.gd','godot/tests/audio_pool.gd','godot/tests/audio_pool.gd.uid'):
   native.update(['audio','integration','modules','localization','touch']);browsers.add('test_audio_web.py');reasons.append(f'{path}: shared M2 audio module')
  elif path=='godot/tests/chain_tree.gd':
   n,b=RULES['tree_view.gd'];native.update(n);browsers.update(b);reasons.append(f'{path}: tree touch regression suite')
  elif path=='godot/tests/enemy_readability.gd':
   n,b=RULES['enemy_presentation.gd'];native.update(n);browsers.update(b);reasons.append(f'{path}: enemy presentation regression suite')
  elif path=='godot/tests/checkpoint.gd':
   n,b=RULES['checkpoint_view.gd'];native.update(n);browsers.update(b);reasons.append(f'{path}: checkpoint UI regression suite')
  elif path=='godot/tests/reward_input.gd':
   n,b=RULES['reward_view.gd'];native.update(n);browsers.update(b);reasons.append(f'{path}: reward input regression suite')
  elif path in ('godot/tests/inventory_filters.gd','godot/tests/inventory_ui.gd'):
   n,b=RULES['inventory_view.gd'];native.update(n);browsers.update(b);reasons.append(f'{path}: inventory UI regression suite')
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
def request_selection(paths,profile,comparison_known=True,manual=False):
 if comparison_known:
  result=select(paths,profile)
  result['comparison']='git diff of supplied base against HEAD'
 elif manual and profile=='integration':
  result=select([],'integration')
  result['comparison']='none: explicitly requested fixed integration checklist'
  result['reasons'].append('Manual integration checks only; changed-file coverage is not established.')
 else:
  result=select([],'full')
  result['comparison']='none: complete regression required'
  result['reasons'].append('No trustworthy changed-file baseline; expanded to full regression.')
 result['web_required']=bool(result['browsers'])
 return result

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--profile',choices=['focused','integration','full'],default='focused')
 p.add_argument('--base',default='')
 p.add_argument('--event',choices=['push','workflow_dispatch'],default='push')
 p.add_argument('--github-output')
 p.add_argument('--files',nargs='*')
 a=p.parse_args()
 known=True
 if a.files is not None:paths=a.files
 elif not a.base or set(a.base)=={'0'}:paths=[];known=False
 else:
  try:paths=subprocess.check_output(['git','diff','--name-only',a.base,'HEAD'],cwd=ROOT,text=True).splitlines()
  except subprocess.CalledProcessError:paths=[];known=False
 result=request_selection(paths,a.profile,known,a.event=='workflow_dispatch')
 result['source_sha']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
 out=ROOT/'qa/selection.json';out.parent.mkdir(exist_ok=True)
 out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');print(out.read_text())
 if a.github_output:
  with open(a.github_output,'a') as f:
   for k in ['profile','native','browsers','web_required']:
    value=json.dumps(result[k]) if k in ('browsers','web_required') else result[k]
    f.write(k+'='+value+'\n')
if __name__=='__main__':main()
