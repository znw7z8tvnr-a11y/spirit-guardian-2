"""Selection controls skipped coverage, so test narrow rules and conservative fallback."""
import unittest
from plan_validation import select,BROWSERS,ROOT,request_selection
class SelectionTests(unittest.TestCase):
 def test_reward_input_selection(self):
  r=select(['godot/experiments/chain_lab/reward_view.gd','godot/tests/reward_input.gd'],'focused');self.assertEqual(r['profile'],'focused');self.assertIn('rewardinput',r['native']);self.assertIn('test_reward_reroll_web.py',r['browsers'])
 def test_checkpoint_prompt_selection(self):
  r=select(['godot/experiments/chain_lab/checkpoint_view.gd','godot/tests/checkpoint.gd'],'focused');self.assertEqual(r['profile'],'focused');self.assertIn('checkpoint',r['native']);self.assertEqual(r['browsers'],['test_checkpoint_web.py'])
 def test_enemy_presentation_selection(self):
  r=select(['godot/experiments/chain_lab/enemy_presentation.gd','godot/tests/enemy_readability.gd'],'focused');self.assertEqual(r['profile'],'focused');self.assertIn('readability',r['native']);self.assertIn('test_enemy_readability_web.py',r['browsers']);self.assertNotIn('test_run_results_web.py',r['browsers'])
 def test_tree_touch_selection(self):
  r=select(['godot/experiments/chain_lab/tree_view.gd','godot/tests/chain_tree.gd'],'focused');self.assertEqual(r['profile'],'focused');self.assertIn('tree',r['native']);self.assertIn('test_chain_lab_web.py',r['browsers']);self.assertIn('test_inventory_filters_web.py',r['browsers'])
 def test_guardian_presentation_selection(self):
  r=select(['godot/experiments/chain_lab/guardian_actor.gd','godot/experiments/chain_lab/assets/ghost_strike.tres','godot/tests/skeleton_guardian.gd'],'focused');self.assertEqual(r['profile'],'focused');self.assertIn('guardians',r['native']);self.assertIn('skeleton',r['native']);self.assertEqual(r['browsers'],['test_guardian_visuals_web.py'])
 def test_guardian_ai_remains_full(self):
  self.assertEqual(select(['godot/experiments/chain_lab/guardian_manager.gd'],'focused')['profile'],'full')
 def test_orbit_presentation_selection(self):
  r=select(['godot/experiments/chain_lab/orbit_fx.gd','godot/tests/orbit_spell.gd'],'focused');self.assertEqual(r['profile'],'focused');self.assertIn('orbit',r['native']);self.assertIn('chainlab',r['native']);self.assertEqual(r['browsers'],['test_orbit_visuals_web.py'])
 def test_thorn_presentation_selection(self):
  r=select(['godot/experiments/chain_lab/thorn_fx.gd','godot/tests/thorn_spell.gd'],'focused');self.assertEqual(r['profile'],'focused');self.assertIn('thorn',r['native']);self.assertIn('orbit',r['native']);self.assertEqual(set(r['browsers']),{'test_thorn_visuals_web.py','test_orbit_visuals_web.py'})
 def test_audio_selection(self):
  r=select(['godot/modules/audio/audio.gd','godot/tests/audio_pool.gd','godot/tests/audio_pool.gd.uid'],'focused');self.assertEqual(r['profile'],'focused');self.assertIn('audio',r['native']);self.assertIn('modules',r['native']);self.assertEqual(r['browsers'],['test_audio_web.py'])
 def test_lab_audio_observer_selection(self):
  r=select(['godot/experiments/chain_lab/audio_controller.gd','godot/tests/lab_audio.gd'],'focused');self.assertEqual(r['profile'],'focused');self.assertIn('labaudio',r['native']);self.assertIn('test_lab_audio_web.py',r['browsers'])
 def test_lab_scene_change_requires_full(self):
  self.assertEqual(select(['godot/experiments/chain_lab/main.tscn'],'focused')['profile'],'full')
 def test_full(self):
  r=select([], 'full');self.assertEqual(r['native'],'');self.assertEqual(set(r['browsers']),set(BROWSERS))
 def test_reroll(self):
  r=select(['godot/experiments/chain_lab/reward_reroll.gd'],'focused');self.assertIn('reroll',r['native']);self.assertIn('checkpoint',r['native']);self.assertNotIn('test_eight_spells_web.py',r['browsers'])
 def test_inventory_native_suite_selects_related_coverage(self):
  for path in ['godot/tests/inventory_filters.gd','godot/tests/inventory_ui.gd']:
   r=select([path],'focused');self.assertEqual(r['profile'],'focused');self.assertIn('inventoryfilters',r['native']);self.assertIn('inventory',r['native']);self.assertIn('test_inventory_filters_web.py',r['browsers'])
 def test_shared_overrides_leaf(self):
  r=select(['godot/experiments/chain_lab/reward_reroll.gd','godot/experiments/chain_lab/main.gd'],'focused');self.assertEqual(r['profile'],'full')
 def test_unknown_game_is_full(self):self.assertEqual(select(['godot/new_resource.tres'],'focused')['profile'],'full')
 def test_changed_browser_only(self):self.assertEqual(select(['tools/test_checkpoint_web.py'],'focused')['browsers'],['test_checkpoint_web.py'])
 def test_infrastructure_is_short(self):self.assertEqual(select(['.github/workflows/godot-m1.yml','tools/check_godot.py','tools/plan_validation.py'],'focused')['browsers'],[])
 def test_integration_excludes_long_runs(self):
  r=select([],'integration');self.assertIn('firstboss',r['native']);self.assertNotIn('test_run_results_web.py',r['browsers']);self.assertNotIn('test_eight_spells_web.py',r['browsers'])
class RequestTests(unittest.TestCase):
 def test_push_without_baseline_stays_full(self):
  r=request_selection([],'focused',False,False)
  self.assertEqual(r['profile'],'full');self.assertTrue(r['web_required'])
 def test_manual_integration_is_partial_without_baseline(self):
  r=request_selection([],'integration',False,True)
  self.assertEqual(r['profile'],'integration');self.assertIn('firstboss',r['native']);self.assertNotIn('test_run_results_web.py',r['browsers']);self.assertIn('not established',r['reasons'][0]);self.assertTrue(r['web_required'])
 def test_manual_focused_without_baseline_stays_full(self):
  self.assertEqual(request_selection([],'focused',False,True)['profile'],'full')
 def test_manual_full_stays_full(self):
  self.assertEqual(request_selection([],'full',False,True)['profile'],'full')
 def test_native_only_requires_no_web_build(self):
  r=request_selection(['tools/plan_validation.py'],'focused')
  self.assertFalse(r['web_required']);self.assertEqual(r['browsers'],[])
 def test_nested_unknown_helper_is_not_isolated(self):
  self.assertEqual(select(['godot/experiments/chain_lab/unknown/reward_reroll.gd'],'focused')['profile'],'full')
 def test_cli_manual_integration_output(self):
  import tempfile,pathlib,subprocess,sys,json
  with tempfile.TemporaryDirectory() as directory:
   output=pathlib.Path(directory)/'output'
   result=subprocess.run([sys.executable,str(ROOT/'tools/plan_validation.py'),'--event','workflow_dispatch','--profile','integration','--github-output',str(output)],capture_output=True,text=True)
   self.assertEqual(result.returncode,0,result.stderr)
   plan=json.loads(result.stdout);self.assertEqual(plan['profile'],'integration')
   self.assertIn('web_required=true',output.read_text());self.assertNotIn('test_eight_spells_web.py',output.read_text())
 def test_cli_known_baseline_native_only(self):
  import tempfile,pathlib,subprocess,sys,json
  with tempfile.TemporaryDirectory() as directory:
   output=pathlib.Path(directory)/'output'
   result=subprocess.run([sys.executable,str(ROOT/'tools/plan_validation.py'),'--files','tools/plan_validation.py','--github-output',str(output)],capture_output=True,text=True)
   self.assertEqual(result.returncode,0,result.stderr)
   self.assertFalse(json.loads(result.stdout)['web_required']);self.assertIn('web_required=false',output.read_text())
class RunnerTests(unittest.TestCase):
 def run_fake(self, mode):
  import tempfile,pathlib,subprocess,sys,os
  with tempfile.TemporaryDirectory() as directory:
   base=pathlib.Path(directory);fake=base/'godot'
   fake.write_text('#!'+sys.executable+'\nimport sys\n'+{
    'ok': 'print(\'INTEGRATION_RESULT {"checks":["fake"],"failures":[]}\') if "res://tests/integration.gd" in sys.argv else None\n',
    'logged': 'print("ERROR: simulated logged failure")\n',
    'missing': 'print("No structured result")\n',
    'exit': 'sys.exit(2)\n',
   }[mode]);fake.chmod(0o755)
   env=os.environ.copy();env['GODOT_BIN']=str(fake)
   result=subprocess.run([sys.executable,str(ROOT/'tools/check_godot.py'),'--suites','integration','--report-dir',str(base/'reports')],env=env,capture_output=True,text=True)
   selection=__import__('json').loads((base/'reports/selection.json').read_text())
   return result,selection
 def test_subset_and_omissions(self):
  result,selection=self.run_fake('ok');self.assertEqual(result.returncode,0,result.stdout+result.stderr);self.assertEqual(selection['selected'],['import','integration','labparse']);self.assertIn('fullrun',selection['omitted']);self.assertFalse(selection['full'])
 def test_logged_error_is_failure(self):self.assertNotEqual(self.run_fake('logged')[0].returncode,0)
 def test_missing_result_is_failure(self):self.assertIn('missing structured result',self.run_fake('missing')[0].stderr)
 def test_nonzero_exit_is_failure(self):self.assertNotEqual(self.run_fake('exit')[0].returncode,0)
if __name__=='__main__':unittest.main()
