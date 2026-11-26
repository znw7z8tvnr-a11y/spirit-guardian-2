"""Run shared finite-FX touch acceptance against the thorn spell."""
import pathlib, runpy, sys
sys.argv[1:1] = ['--spell', 'thorn']
runpy.run_path(str(pathlib.Path(__file__).with_name('test_orbit_visuals_web.py')), run_name='__main__')
