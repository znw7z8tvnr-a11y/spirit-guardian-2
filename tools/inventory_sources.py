import hashlib,json,pathlib,re,subprocess
ROOT=pathlib.Path(__file__).resolve().parents[1]
rows=[]
for p in sorted(ROOT.glob('*.html')):
 raw=p.read_bytes();s=raw.decode();scripts=re.findall(r'<script\b[^>]*>(.*?)</script>',s,re.S|re.I)
 result=subprocess.run(['node','-e',"let s='';process.stdin.on('data',d=>s+=d);process.stdin.on('end',()=>{let e=[];JSON.parse(s).forEach((v,i)=>{try{new(require('vm').Script)(v)}catch(x){e.push({script:i+1,error:x.message})}});console.log(JSON.stringify(e))})"],input=json.dumps(scripts),text=True,capture_output=True,check=True)
 rows.append({'file':p.name,'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'git_blob':subprocess.check_output(['git','hash-object',str(p)],text=True).strip(),'title':re.search(r'<title>(.*?)</title>',s).group(1),'inline_scripts':len(scripts),'embedded_images':s.count('data:image'),'syntax_errors':json.loads(result.stdout)})
(ROOT/'docs/source-inventory.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
print(f'{len(rows)} HTML sources; {sum(len(v["syntax_errors"]) for v in rows)} script syntax errors. Syntax does not establish runtime integration.')
