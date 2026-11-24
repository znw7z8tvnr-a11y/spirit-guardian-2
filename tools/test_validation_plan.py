"""Selection controls skipped coverage, so test narrow rules and conservative fallback."""
import unittest
from plan_validation import select,BROWSERS,ROOT
class SelectionTests(unittest.TestCase):
 def test_full(self):
  r=select([], 'full');self.assertEqual(r['native'],'');self.assertEqual(set(r['browsers']),set(BROWSERS))
 def test_reroll(self):
  r=select(['godot/experiments/chain_lab/reward_reroll.gd'],'focused');self.assertIn('reroll',r['native']);self.assertIn('checkpoint',r['native']);self.assertNotIn('test_eight_spells_web.py',r['browsers'])
 def test_shared_overrides_leaf(self):
  r=select(['godot/experiments/chain_lab/reward_reroll.gd','godot/experiments/chain_lab/main.gd'],'focused');self.assertEqual(r['profile'],'full')
 def test_unknown_game_is_full(self):self.assertEqual(select(['godot/new_resource.tres'],'focused')['profile'],'full')
 def test_changed_browser_only(self):self.assertEqual(select(['tools/test_checkpoint_web.py'],'focused')['browsers'],['test_checkpoint_web.py'])
 def test_infrastructure_is_short(self):self.assertEqual(select(['.github/workflows/godot-m1.yml','tools/check_godot.py','tools/plan_validation.py'],'focused')['browsers'],[])
 def test_integration_excludes_long_runs(self):
  r=select([],'integration');self.assertIn('firstboss',r['native']);self.assertNotIn('test_run_results_web.py',r['browsers']);self.assertNotIn('test_eight_spells_web.py',r['browsers'])
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
