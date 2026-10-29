"""Read-only source inventory: data presence is not a completed behavior port."""
import hashlib,json,pathlib,re
ROOT=pathlib.Path(__file__).resolve().parents[1]
catalog=json.loads((ROOT/'godot/data/supplement_catalog.json').read_text())
recipes=json.loads((ROOT/'godot/data/resonance_profiles.json').read_text())['recipes']
manifest=json.loads((ROOT/'docs/supplement-manifest.json').read_text())
references=[]
for row in manifest:
 p=ROOT/'reference_modules'/row['file'];digest=hashlib.sha256(p.read_bytes()).hexdigest()
 assert digest==row['sha256'],f'Preserved source differs: {p.name}'
 references.append({'file':str(p.relative_to(ROOT)),'sha256':digest,'unchanged':True})
source=ROOT/'reference_modules/spirit_guardian_gem_chain_module_v9_integrated.html'
lines=source.read_text().splitlines()
function_line=next(i+1 for i,s in enumerate(lines) if s.startswith('function executeCast('))
selection_line=next(i+1 for i,s in enumerate(lines) if "['fire','ice','meteor','arcane','sword'" in s)
area={'fire','ice','meteor','arcane','sword','earth','wind','lava','gravity','storm','blizzard','nova','swamp','thorn','orbit'}
playable={'fire','ice','lightning','arcane','poison','meteor','nova','beam'}
lab=set(playable)
rows=[]
for key,spec in catalog['SK'].items():
 if key in area:
  radius=145 if key=='meteor' else 155 if key in {'storm','blizzard'} else 125 if key in {'gravity','wind'} else 110 if key=='sword' else 75
  behavior={'selection':'radius around primary target','radius':radius,'max_victims':24}
 elif key in {'lightning','spark'}:behavior={'selection':'within 165 of target','radius':165,'max_victims':6}
 elif key in {'pierce','beam'}:behavior={'selection':'horizontal strip around target','strip_half_width':38,'max_victims':8}
 else:behavior={'selection':'primary target','max_victims':1}
 rows.append({'key':key,'name':spec[1],'reference_power':spec[3],'source':str(source.relative_to(ROOT)),'source_lines':[function_line,selection_line],'v9_observed_selection':behavior,'m2_1':'partial runnable behavior' if key in playable else 'catalog only; behavior port pending','lab_v2':'provisional runnable behavior; see EIGHT_SPELLS.md' if key in lab else 'not implemented','cross_module_behavior_review':'PENDING: V9 selection alone cannot establish complete animation, summon AI or persistent zones'})
sets={tuple(sorted(r['parts'])) for r in recipes};ingredients=sorted({x for r in recipes for x in r['parts']})
assert len(rows)==22 and len(catalog['GEM'])==19 and len(recipes)==50 and len(sets)==50 and len(ingredients)==12
report={'scope':'P0 source inventory first pass; not full original-module parity audit','counts':{'skills':22,'gems':19,'resonance_recipes':50,'unique_recipe_sets':50,'recipe_materials':12,'three_distinct_material_combinations':220,'undefined_combinations':170},'references':references,'skills':rows,'gems':[{'key':k,'name':v[1],'description':v[2],'status':('Lab source-backed trigger rates; see GEM_TRIGGERS.md' if k in ['chance','hit','kill'] else 'Lab next-skill direct damage bonus; see AMPLIFY_GEM.md' if k=='split' else 'source metadata retained; behavior port pending')} for k,v in catalog['GEM'].items()],'resonance':{'recipes':recipes,'material_keys':ingredients,'non_skill_keys':[x for x in ingredients if x not in catalog['SK']],'status':'50 profiles retained; not 50 complete runtime spells'},'lab_gems':{'relay':'prototype-only item, not a renamed completed nineteen-gem port','implemented_original':['chance','hit','kill','split'],'remaining_original_count':15,'conditional_gates':'Four original types integrated into rewards and inventory; unsupported keys fail closed'},'conflicts':['SG7 resonance pool includes rate/shield/split, not just attack elements.','V9 executeCast maps arcane damage to lightning; current Catalog.element uses arcane. Final taxonomy remains undecided.','V9 observed victim selection shares behavior across many skills; other modules must be compared before claiming unique summons or zones.'],'enemy_review':{'sources':['reference_modules/spirit_guardian_enemy_ai_final.html','reference_modules/spirit_guardian_v31_10_enemy_ai_10passes.html','reference_modules/spirit_guardian_boss_v5_playable.html'],'status':'PENDING full special-ability, move, drop and scaling parity cards'}}
out=ROOT/'docs/design/SOURCE_INVENTORY_2026-10-29.json';out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
text=['# 原始功能盤點第一批（2026-10-29）','','這是來源與實作差距表，不是完整移植驗收。11個補充HTML逐檔SHA-256核對未改；資料為22技能、19寶石、50組唯一配方。','','| 技能 | V9觀察到的選敵 | M2.1 | Lab V2 |','|---|---|---|---|']
for row in rows:text.append(f"| {row['name']} | {row['v9_observed_selection']['selection']} | {row['m2_1']} | {row['lab_v2']} |")
text+=['','來源：reference_modules/spirit_guardian_gem_chain_module_v9_integrated.html 的 executeCast 與選敵分組；精確行數、原數值及檔案雜湊見同名JSON。','','待做：逐招對照V32、技能／VFX模組；完整怪物Boss能力與掉肉表；素材商用授權。不要因名稱而宣稱完整召喚AI或持續區域已存在／已移植。','','配方仍有12素材分類與新元素概念的衝突，先保存原資料，不自行刪除或把170個未定義組合當成完成法術。']
(ROOT/'docs/design/SOURCE_INVENTORY_2026-10-29.md').write_text('\n'.join(text)+'\n')
print('Source inventory:',len(rows),'skills;',len(references),'unchanged references; 19 gems; 50 unique recipes')
