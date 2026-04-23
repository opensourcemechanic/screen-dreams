#!/usr/bin/env python3
"""
Screen Dreams - Production entry point for uvx
Uses gunicorn to bind to PORT environment variable
"""

import os
import sys
import subprocess
from pathlib import Path

def main():
    """Production entry point using gunicorn"""
    port = os.environ.get('PORT', '5000')
    data_dir = os.environ.get(
        'DATA_DIR',
        os.path.join(os.path.expanduser('~'), '.local', 'share', 'screen-dreams')
    )

    print("Screen Dreams - AI Screenwriting Application")
    print("=" * 50)
    print("Mode: Production")
    print(f"Server: http://localhost:{port}")
    print(f"Data dir: {data_dir}")
    print("Debug mode: DISABLED")
    print("Web Server: Gunicorn")
    print("=" * 50)
    print("For development mode, use: screen-dreams-dev")
    print()
    
    # Use gunicorn to bind to the specified port
    try:
        cmd = [
            'gunicorn',
            '--bind', f'0.0.0.0:{port}',
            '--workers', '2',
            '--timeout', '30',
            '--access-logfile', '-',
            'app:create_app()'
        ]
        subprocess.run(cmd, check=True)
    except FileNotFoundError:
        print("Error: gunicorn not found. Please install gunicorn:")
        print("  pip install gunicorn")
        print("Or use development mode: screen-dreams-dev")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"Error starting gunicorn: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
