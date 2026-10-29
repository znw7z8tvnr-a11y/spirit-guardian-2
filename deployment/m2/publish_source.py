"""Fallback for this environment's missing Sites source helper.
Read a short-lived credential only from hidden stdin; never persist credentials.
"""
import hashlib,json,os,pathlib,subprocess,sys,termios
settings=termios.tcgetattr(0);settings[3]&=~termios.ECHO;termios.tcsetattr(0,termios.TCSANOW,settings)
print('Ready for Site source JSON on stdin (input is hidden).',flush=True)
payload=json.loads(sys.stdin.readline());credential=payload['credential']
root=pathlib.Path(payload['checkout']).resolve()
manifest=json.loads((root/'.openai/hosting.json').read_text())
assert manifest['project_id']==payload['project_id']
assert manifest['static']['directory']=='dist'
env=os.environ.copy()
for key in ['GIT_CURL_VERBOSE','GIT_TRACE_CURL','GIT_TRACE']:env.pop(key,None)
env['GIT_TERMINAL_PROMPT']='0'
if credential.get('auth_mode')!='work_proxy':
 index=int(env.get('GIT_CONFIG_COUNT','0'));env['GIT_CONFIG_COUNT']=str(index+1)
 env[f'GIT_CONFIG_KEY_{index}']='http.https://git.chatgpt-team.site/.extraheader'
 env[f'GIT_CONFIG_VALUE_{index}']='Authorization: Bearer '+credential['token']
def git(*args):
 result=subprocess.run(['git',*args],cwd=root,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120)
 if result.returncode:raise RuntimeError(result.stdout)
 return result.stdout.strip()
branch=credential['branch'];remote=git('ls-remote','--heads',credential['remote_url'],branch).split()[0]
assert git('rev-parse','HEAD')==remote,'Site checkout is stale; synchronize before publication'
git('add','--','.openai/hosting.json','dist','LAB.md')
git('commit','-m','Publish P1 chain-flow lab; preserve original M2.1 entry')
sha=git('rev-parse','HEAD');git('push','origin',f'HEAD:{branch}')
assert git('ls-remote','--heads',credential['remote_url'],branch).split()[0]==sha
archive=root/'chain-flow-site.tar.gz';git('archive','--format=tar.gz','-o',str(archive),'HEAD','.openai/hosting.json','dist')
result={'project_id':payload['project_id'],'commit_sha':sha,'archive':str(archive),'archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest()}
(root/'qa').mkdir(exist_ok=True);(root/'qa/flow-source-result.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result),flush=True)
