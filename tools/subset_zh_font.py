"""Subset an OFL Noto Sans CJK TC font and rename the modified family.
The produced font is committed; regeneration needs fontTools and the source TTC.
"""
import argparse,ast,hashlib,json,pathlib
from fontTools import subset
from fontTools.ttLib import TTFont
ROOT=pathlib.Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--source',default='/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc');p.add_argument('--check',action='store_true');args=p.parse_args()
chars=set(chr(i) for i in range(32,127))
for path in (ROOT/'godot').rglob('*.gd'):
 if 'tests' not in path.parts:chars.update(path.read_text())
for path in (ROOT/'godot/localization').glob('*.po'):chars.update(path.read_text())
catalog=json.loads((ROOT/'godot/data/supplement_catalog.json').read_text())
for name in ['SK','GEM']:
 for row in catalog[name].values():
  chars.update(str(row[1]));
  if name=='GEM':chars.update(str(row[2]))
for name in ['FUSIONS','FINISHERS']:
 for row in catalog[name].values():chars.update(row[0])
for row in json.loads((ROOT/'godot/data/resonance_profiles.json').read_text())['recipes']:chars.update(row['name'])
chars={c for c in chars if ord(c)>=32}
output=ROOT/'godot/assets/fonts/SpiritGuardianTC-Regular.otf'
if args.check:
 font=TTFont(output);missing=sorted(ord(c) for c in chars if ord(c) not in font.getBestCmap())
 if missing:raise SystemExit('Missing UI glyphs: '+','.join(f'U+{x:04X}' for x in missing))
 print('Font coverage PASS:',len(chars),'required characters');raise SystemExit(0)
font=TTFont(args.source,fontNumber=3)
missing=sorted(ord(c) for c in chars if ord(c) not in font.getBestCmap())
if missing:raise SystemExit('Source font lacks required glyphs: '+','.join(f'U+{x:04X}' for x in missing))
copyright=font['name'].getDebugName(0)
for record in font['name'].names:
 names={1:'Spirit Guardian TC',2:'Regular',3:'SpiritGuardianTC-Regular-UI-Subset-1',4:'Spirit Guardian TC Regular',6:'SpiritGuardianTC-Regular',16:'Spirit Guardian TC',17:'Regular'}
 if record.nameID in names:record.string=names[record.nameID].encode(record.getEncoding())
options=subset.Options();options.name_IDs=['*'];options.name_languages=['*'];options.name_legacy=True
sub=subset.Subsetter(options=options);sub.populate(unicodes={ord(c) for c in chars});sub.subset(font)
output.parent.mkdir(exist_ok=True,parents=True);font.save(output)
(ROOT/'godot/localization/required_chars.txt').write_text(''.join(sorted(chars))+'\n')
license_source=pathlib.Path('/usr/share/doc/fonts-noto-cjk/copyright').read_text()
license_block=license_source[license_source.index('\nLicense: SIL-1.1\n ------------------------------------------------')+len('\nLicense: SIL-1.1\n'):].split('\nLicense: GPL-3+')[0]
license_text='\n'.join('' if line==' .' else line[1:] if line.startswith(' ') else line for line in license_block.splitlines()).strip()
(output.parent/'OFL.txt').write_text(str(copyright)+'\n\n'+license_text+'\n')
metadata={'derived_family':'Spirit Guardian TC','source_family':'Noto Sans CJK TC Regular','source_url':'https://github.com/notofonts/noto-cjk','source_file_sha256':hashlib.sha256(pathlib.Path(args.source).read_bytes()).hexdigest(),'source_collection_index':3,'license':'SIL Open Font License 1.1','modified':'Subset for UI and renamed; glyph outlines unchanged','characters':len(chars),'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest()}
(output.parent/'FONT_INFO.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2));print(json.dumps(metadata,ensure_ascii=False,indent=2))
