"""Godot import + engine integration, fail also on logged runtime errors."""
import argparse,json,os,pathlib,shutil,subprocess,tempfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--suites', help='Comma-separated native suite labels; default: all. Import and scene parse always run.')
parser.add_argument('--report-dir', type=pathlib.Path, default=ROOT/'docs/reward-reroll')
options=parser.parse_args()
SUITES=[('import', ['--editor', '--import', '--quit']), ('labparse', ['--check-only', '--script', 'res://experiments/chain_lab/main.gd']), ('integration', ['--fixed-fps', '60', '--script', 'res://tests/integration.gd']), ('modules', ['--fixed-fps', '60', '--script', 'res://tests/modules.gd']), ('localization', ['--fixed-fps', '60', '--script', 'res://tests/localization.gd']), ('touch', ['--fixed-fps', '60', '--script', 'res://tests/touch_ui.gd']), ('chainlab', ['--fixed-fps', '60', '--script', 'res://tests/chain_lab.gd']), ('flow', ['--fixed-fps', '60', '--script', 'res://tests/chain_flow.gd']), ('reroll', ['--fixed-fps', '60', '--script', 'res://tests/reward_reroll.gd']), ('rewards', ['--fixed-fps', '60', '--script', 'res://tests/wave_rewards.gd']), ('inventoryfilters', ['--fixed-fps', '60', '--script', 'res://tests/inventory_filters.gd']), ('inventory', ['--fixed-fps', '60', '--script', 'res://tests/inventory_ui.gd']), ('tree', ['--fixed-fps', '60', '--script', 'res://tests/chain_tree.gd']), ('earlywave', ['--fixed-fps', '60', '--script', 'res://tests/early_wave.gd']), ('checkpoint', ['--fixed-fps', '60', '--script', 'res://tests/checkpoint.gd']), ('fullrun', ['--fixed-fps', '60', '--script', 'res://tests/full_run.gd']), ('readability', ['--fixed-fps', '60', '--script', 'res://tests/enemy_readability.gd']), ('enemytactics', ['--fixed-fps', '60', '--script', 'res://tests/enemy_tactics.gd']), ('finalgems', ['--fixed-fps', '60', '--script', 'res://tests/final_gems.gd']), ('attackgems', ['--fixed-fps', '60', '--script', 'res://tests/attack_gems.gd']), ('skeleton', ['--fixed-fps', '60', '--script', 'res://tests/skeleton_guardian.gd']), ('guardians', ['--fixed-fps', '60', '--script', 'res://tests/ghost_guardian.gd']), ('thorn', ['--fixed-fps', '60', '--script', 'res://tests/thorn_spell.gd']), ('orbit', ['--fixed-fps', '60', '--script', 'res://tests/orbit_spell.gd']), ('gravity', ['--fixed-fps', '60', '--script', 'res://tests/gravity_spell.gd']), ('swamp', ['--fixed-fps', '60', '--script', 'res://tests/swamp_spell.gd']), ('lava', ['--fixed-fps', '60', '--script', 'res://tests/lava_spell.gd']), ('blizzard', ['--fixed-fps', '60', '--script', 'res://tests/blizzard_spell.gd']), ('storm', ['--fixed-fps', '60', '--script', 'res://tests/storm_spell.gd']), ('spark', ['--fixed-fps', '60', '--script', 'res://tests/spark_spell.gd']), ('sword', ['--fixed-fps', '60', '--script', 'res://tests/sword_spell.gd']), ('wind', ['--fixed-fps', '60', '--script', 'res://tests/wind_spell.gd']), ('earth', ['--fixed-fps', '60', '--script', 'res://tests/earth_spell.gd']), ('pierce', ['--fixed-fps', '60', '--script', 'res://tests/pierce_spell.gd']), ('timing', ['--fixed-fps', '60', '--script', 'res://tests/timing_gem.gd']), ('lowhp', ['--fixed-fps', '60', '--script', 'res://tests/lowhp_gem.gd']), ('elementgems', ['--fixed-fps', '60', '--script', 'res://tests/element_gems.gd']), ('echo', ['--fixed-fps', '60', '--script', 'res://tests/echo_gem.gd']), ('amplify', ['--fixed-fps', '60', '--script', 'res://tests/amplify_gem.gd']), ('gemtriggers', ['--fixed-fps', '60', '--script', 'res://tests/gem_triggers.gd']), ('eightspells', ['--fixed-fps', '60', '--script', 'res://tests/eight_spells.gd']), ('firstboss', ['--fixed-fps', '60', '--script', 'res://tests/first_boss.gd']), ('flesh', ['--fixed-fps', '60', '--script', 'res://tests/flesh_wall.gd'])]
labels={label for label,_ in SUITES}
selected=set(options.suites.split(',')) if options.suites else labels
unknown=selected-labels
if unknown:parser.error('Unknown suites: '+', '.join(sorted(unknown)))
REPORT=options.report_dir
REPORT.mkdir(parents=True,exist_ok=True)
(REPORT/'selection.json').write_text(json.dumps({'selected': sorted(selected | {'import','labparse'}),'omitted': sorted(labels-selected-{'import','labparse'}),'full': selected >= labels-{'import','labparse'}},indent=2))
with tempfile.TemporaryDirectory(prefix='sg-check-') as temporary:
 env=os.environ.copy()
 for name,folder in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
  env[name]=str(pathlib.Path(temporary)/folder);pathlib.Path(env[name]).mkdir()
 binary=os.environ.get('GODOT_BIN','godot')
 for label,args in SUITES:
  if label not in selected | {'import','labparse'}:continue
  try:
   r=subprocess.run([binary,'--headless','--path',str(ROOT/'godot'),*args],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120)
  except subprocess.TimeoutExpired as error:
   captured=error.stdout or b''
   if isinstance(captured,bytes):captured=captured.decode(errors='replace')
   (REPORT/('godot-'+label+'.log')).write_text(captured)
   print(captured);raise SystemExit(f'{label} timed out after 120 seconds')
  (REPORT/('godot-'+label+'.log')).write_text(r.stdout)
  if r.returncode or 'SCRIPT ERROR' in r.stdout or 'ERROR:' in r.stdout:
   print(r.stdout);raise SystemExit(f'{label} failed (exit {r.returncode})')
  print(label, 'PASS')
  if label in ['reroll','inventoryfilters','earlywave','integration','modules','localization','touch','chainlab','flow','flesh','tree','inventory','rewards','firstboss','eightspells','gemtriggers','amplify','echo','elementgems','lowhp','timing','pierce','earth','wind','sword','spark','storm','blizzard','lava','swamp','gravity','orbit','thorn','guardians','skeleton','attackgems','finalgems','enemytactics','readability','fullrun','checkpoint']:
   prefix={'reroll':'REROLL_RESULT ','inventoryfilters':'INVENTORYFILTERS_RESULT ','earlywave':'EARLYWAVE_RESULT ','checkpoint':'CHECKPOINT_RESULT ','fullrun':'FULLRUN_RESULT ','readability':'READABILITY_RESULT ','enemytactics':'ENEMYTACTICS_RESULT ','finalgems':'FINALGEMS_RESULT ','attackgems':'ATTACKGEMS_RESULT ','skeleton':'SKELETON_RESULT ','guardians':'GUARDIAN_RESULT ','thorn':'THORN_RESULT ','orbit':'ORBIT_RESULT ','gravity':'GRAVITY_RESULT ','swamp':'SWAMP_RESULT ','lava':'LAVA_RESULT ','blizzard':'BLIZZARD_RESULT ','storm':'STORM_RESULT ','spark':'SPARK_RESULT ','sword':'SWORD_RESULT ','wind':'WIND_RESULT ','earth':'EARTH_RESULT ','pierce':'PIERCE_RESULT ','timing':'TIMING_RESULT ','lowhp':'LOWHP_RESULT ','elementgems':'ELEMENTGEMS_RESULT ','echo':'ECHO_RESULT ','amplify':'AMPLIFY_RESULT ','gemtriggers':'GEMTRIGGERS_RESULT ','integration':'INTEGRATION_RESULT ','modules':'MODULE_RESULT ','localization':'LOCALIZATION_RESULT ','touch':'TOUCH_RESULT ','chainlab':'CHAINLAB_RESULT ','flow':'FLOW_RESULT ','eightspells':'EIGHTSPELLS_RESULT ','firstboss':'FIRSTBOSS_RESULT ','rewards':'REWARDS_RESULT ','inventory':'INVENTORY_RESULT ','tree':'TREE_RESULT ','flesh':'FLESH_RESULT '}[label]
   line=next((v for v in r.stdout.splitlines() if v.startswith(prefix)),None)
   if line is None:raise SystemExit(f'{label} failed: missing structured result')
   result=json.loads(line.removeprefix(prefix))
   (REPORT/('godot-'+label+'.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2))
   if result['failures']:raise SystemExit(1)
   print(len(result['checks']),'checks passed;',result.get('soak',{}))
