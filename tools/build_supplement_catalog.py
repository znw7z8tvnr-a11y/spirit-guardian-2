"""Read preserved reference modules and regenerate pure-data catalogs/assets."""
from pathlib import Path
import base64,hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
REF=ROOT/'reference_modules'
def evaluate(expression):
 return json.loads(subprocess.check_output(['node','-e',"const vm=require('vm');let s='';process.stdin.on('data',d=>s+=d);process.stdin.on('end',()=>console.log(JSON.stringify(vm.runInNewContext(s,Object.create(null),{timeout:1000}))))"],input=expression,text=True))
def literal(source,name):
 return evaluate('('+re.search(r'const '+name+r'=(\{.*?\});',source,re.S).group(1)+')')
chain=(REF/'spirit_guardian_gem_chain_module_v9_integrated.html').read_text()
boss=(REF/'spirit_guardian_boss_v5_playable.html').read_text().replace('const MOVE=Object.freeze({','const MOVE={').replace('\n});\nconst clamp','\n};\nconst clamp')
catalog={k:literal(chain,k) for k in ['SK','GEM','ELEMENT','FUSIONS','FINISHERS']}
catalog['MOVE']=literal(boss,'MOVE')
(ROOT/'godot/data/supplement_catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2))
source=(REF/'spirit_guardian_v31_16_skills_final.html').read_text()
recipes=source[source.index('const SG7_SKILLS='):source.index('const SG71_TRAITS=')]
module=source[source.index('/* Spirit Guardian V31.16 — resonance final integration:'):]
profiles=module[module.index('const names='):module.index('function stateOK')]
parsed=evaluate(recipes+'\n'+profiles+'\n({recipes:SG7_RESONANCES,profiles})')
(ROOT/'godot/data/resonance_profiles.json').write_text(json.dumps(parsed,ensure_ascii=False,indent=2))
images=json.loads(re.search(r'const SG_ASSET_DATA=(\{.*?\});',(REF/'spirit_guardian_enemy_ai_final.html').read_text()).group(1))
assets=[]
for key in ['walk_shaman','walk_elite','walk_boss','boss_lava','boss_witch','boss_hydra','poison','meteor','blade','iceburst','voidburst']:
 raw=base64.b64decode(images[key].split(',')[1]);p=ROOT/'godot/assets/legacy'/f'{key}.webp';p.write_bytes(raw)
 assets.append({'file':p.relative_to(ROOT).as_posix(),'source':'reference_modules/spirit_guardian_enemy_ai_final.html','key':key,'sha256':hashlib.sha256(raw).hexdigest(),'license':'UNVERIFIED: temporary migration reference'})
(ROOT/'docs/m2/asset-manifest.json').write_text(json.dumps(assets,ensure_ascii=False,indent=2))
print('Catalogs:',len(catalog['SK']),'spells;',len(catalog['GEM']),'gems;',len(parsed['recipes']),'resonance recipes (data only).')
