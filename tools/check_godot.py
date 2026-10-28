"""Godot import + engine integration, fail also on logged runtime errors."""
import json,os,pathlib,shutil,subprocess,tempfile
ROOT=pathlib.Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='sg-check-') as temporary:
 env=os.environ.copy()
 for name,folder in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
  env[name]=str(pathlib.Path(temporary)/folder);pathlib.Path(env[name]).mkdir()
 binary=os.environ.get('GODOT_BIN','godot')
 for label,args in [('import',['--editor','--import','--quit']),('integration',['--fixed-fps','60','--script','res://tests/integration.gd'])]:
  r=subprocess.run([binary,'--headless','--path',str(ROOT/'godot'),*args],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120)
  (ROOT/'docs'/('godot-'+label+'.log')).write_text(r.stdout)
  if r.returncode or 'SCRIPT ERROR' in r.stdout or 'ERROR:' in r.stdout:
   print(r.stdout);raise SystemExit(f'{label} failed (exit {r.returncode})')
  print(label, 'PASS')
  if label=='integration':
   line=next(v for v in r.stdout.splitlines() if v.startswith('INTEGRATION_RESULT '))
   result=json.loads(line.removeprefix('INTEGRATION_RESULT '))
   (ROOT/'docs/godot-integration.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
   if result['failures']:raise SystemExit(1)
   print(len(result['checks']),'checks passed;',result['soak'])
