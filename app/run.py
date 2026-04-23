#!/usr/bin/env python3
"""
Screen Dreams - Production entry point (uses gunicorn)
"""

import os
import sys
import subprocess
from pathlib import Path

def main():
    """Production entry point - runs via gunicorn"""
    # Create necessary directories
    for directory in ['uploads', 'screenplays', 'logs']:
        Path(directory).mkdir(exist_ok=True)

    port = os.environ.get('PORT', '5000')
    workers = os.environ.get('GUNICORN_WORKERS', '4')

    # Locate bundled gunicorn config (works both installed and from repo root)
    config_path = Path(__file__).parent / 'gunicorn.conf.py'
    if not config_path.exists():
        config_path = Path('gunicorn.conf.py')

    cmd = [
        sys.executable, '-m', 'gunicorn',
        '--bind', f'0.0.0.0:{port}',
        '--workers', workers,
        '--timeout', '120',
    ]
    if config_path.exists():
        cmd += ['--config', str(config_path)]
    cmd += ['app:create_app()']

    print("Screen Dreams - AI Screenwriting Application")
    print("=" * 50)
    print("Mode: Production (gunicorn)")
    print(f"Server: http://localhost:{port}")
    print(f"Workers: {workers}")
    print("=" * 50)
    print()

    try:
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        print("gunicorn not found - falling back to Flask dev server")
        from . import create_app
        app = create_app()
        app.run(debug=False, host='0.0.0.0', port=int(port))
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)

if __name__ == '__main__':
    main()
