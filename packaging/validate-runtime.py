#!/usr/bin/env python3
"""Check the installed runtime in an isolated nested Shell, without logging out."""
import os
from pathlib import Path
import subprocess
import tempfile

packaging = Path(__file__).resolve().parent
multiarch = subprocess.check_output(
    ['dpkg-architecture', '-qDEB_HOST_MULTIARCH'], text=True).strip()
environment = os.environ.copy()
for line in (packaging / 'org.gnome.Shell.PerMonitor.service').read_text().splitlines():
    if line.startswith('Environment='):
        name, value = line.removeprefix('Environment=').split('=', 1)
        environment[name] = value.replace('@MULTIARCH@', multiarch)
environment['MUTTER_DEBUG_NUM_DUMMY_MONITORS'] = '2'
environment['XDG_SESSION_TYPE'] = 'wayland'
log = Path.home() / '.cache/per-monitor-workspaces/independence-check.log'
log.parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='per-monitor-runtime-') as runtime:
    environment['XDG_RUNTIME_DIR'] = runtime
    with log.open('w') as output:
        result = subprocess.run([
            'dbus-run-session', '--',
            '/opt/per-monitor-workspaces/usr/bin/gnome-shell',
            '--nested', '--wayland',
            f'--automation-script={packaging / "check-independent-workspaces.js"}',
        ], env=environment, stdout=output, stderr=subprocess.STDOUT, timeout=45)
contents = log.read_text()
if result.returncode or 'PER_MONITOR_CHECK_PASS' not in contents:
    print('\n'.join(contents.splitlines()[-55:]))
    raise SystemExit(f'Runtime check failed (exit {result.returncode}); see {log}')
print(next(line for line in contents.splitlines() if 'PER_MONITOR_CHECK_PASS' in line))
print(f'Nested Shell exited cleanly. Log: {log}')
