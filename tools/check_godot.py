"""Godot import + engine integration, fail also on logged runtime errors."""
import json,os,pathlib,shutil,subprocess,tempfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
REPORT=ROOT/'docs/rewards'
REPORT.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='sg-check-') as temporary:
 env=os.environ.copy()
 for name,folder in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
  env[name]=str(pathlib.Path(temporary)/folder);pathlib.Path(env[name]).mkdir()
 binary=os.environ.get('GODOT_BIN','godot')
 for label,args in [('import',['--editor','--import','--quit']),('integration',['--fixed-fps','60','--script','res://tests/integration.gd']),('modules',['--fixed-fps','60','--script','res://tests/modules.gd']),('localization',['--fixed-fps','60','--script','res://tests/localization.gd']),('touch',['--fixed-fps','60','--script','res://tests/touch_ui.gd']),('chainlab',['--fixed-fps','60','--script','res://tests/chain_lab.gd']),('flow',['--fixed-fps','60','--script','res://tests/chain_flow.gd']),('rewards',['--fixed-fps','60','--script','res://tests/wave_rewards.gd']),('inventory',['--fixed-fps','60','--script','res://tests/inventory_ui.gd']),('tree',['--fixed-fps','60','--script','res://tests/chain_tree.gd']),('flesh',['--fixed-fps','60','--script','res://tests/flesh_wall.gd'])]:
  r=subprocess.run([binary,'--headless','--path',str(ROOT/'godot'),*args],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120)
  (REPORT/('godot-'+label+'.log')).write_text(r.stdout)
  if r.returncode or 'SCRIPT ERROR' in r.stdout or 'ERROR:' in r.stdout:
   print(r.stdout);raise SystemExit(f'{label} failed (exit {r.returncode})')
  print(label, 'PASS')
  if label in ['integration','modules','localization','touch','chainlab','flow','flesh','tree','inventory','rewards']:
   prefix={'integration':'INTEGRATION_RESULT ','modules':'MODULE_RESULT ','localization':'LOCALIZATION_RESULT ','touch':'TOUCH_RESULT ','chainlab':'CHAINLAB_RESULT ','flow':'FLOW_RESULT ','rewards':'REWARDS_RESULT ','inventory':'INVENTORY_RESULT ','tree':'TREE_RESULT ','flesh':'FLESH_RESULT '}[label]
   line=next(v for v in r.stdout.splitlines() if v.startswith(prefix))
   result=json.loads(line.removeprefix(prefix))
   (REPORT/('godot-'+label+'.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2))
   if result['failures']:raise SystemExit(1)
   print(len(result['checks']),'checks passed;',result.get('soak',{}))
