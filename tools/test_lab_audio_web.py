"""Run the shared trusted-touch audio acceptance against the Lab entry."""
import pathlib,runpy,sys
sys.argv[1:1]=['--mode','lab']
runpy.run_path(str(pathlib.Path(__file__).with_name('test_audio_web.py')),run_name='__main__')
