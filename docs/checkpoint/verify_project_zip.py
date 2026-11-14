import tempfile,pathlib,zipfile,subprocess,os,json
root=pathlib.Path(__file__).resolve().parents[2];report=root/'docs/checkpoint'
with tempfile.TemporaryDirectory(prefix='sg-zip-import-') as temporary:
 temp=pathlib.Path(temporary);project=temp/'project';project.mkdir()
 with zipfile.ZipFile(root/'dist/SpiritGuardian-Godot-ChainLab.zip') as archive:archive.extractall(project)
 env=os.environ.copy()
 for key,folder in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
  target=temp/folder;target.mkdir();env[key]=str(target)
 probe=temp/'probe.gd';probe.write_text('''extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var entry: String=ProjectSettings.get_setting("application/run/main_scene")
 var game=load(entry).instantiate();game.persist_book=false;game.persist_run=false;root.add_child(game);current_scene=game
 # The normal run starts after a five-second opening rest.
 for i in 600:await physics_frame
 var result: Dictionary={"entry":entry,"wave":game.wave,"casts":game.chain.casts,"enemies":game.enemies.get_child_count(),"items":game.chain.items.size(),"combat_seconds":game.combat_seconds,"simulated_frames":600}
 var ok: bool=entry=="res://experiments/chain_lab/main.tscn" and game.wave>=1 and game.chain.casts>0 and game.enemies.get_child_count()>0 and game.chain.items.size()==1
 print("ZIP_RUNTIME_RESULT "+JSON.stringify(result));quit(0 if ok else 1)
''')
 for name,arguments in [('import',['--editor','--import','--quit']),('runtime',['--fixed-fps','60','--script',str(probe)])]:
  result=subprocess.run(['godot','--headless','--path',str(project),*arguments],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120)
  (report/('zip-'+name+'.log')).write_text(result.stdout)
  assert result.returncode==0 and 'SCRIPT ERROR' not in result.stdout and 'ERROR:' not in result.stdout,result.stdout[-2500:]
  print(name,'PASS')
  if name=='runtime':
   row=next(x for x in result.stdout.splitlines() if x.startswith('ZIP_RUNTIME_RESULT '));(report/'zip-runtime.json').write_text(row.removeprefix('ZIP_RUNTIME_RESULT '));print(row)
