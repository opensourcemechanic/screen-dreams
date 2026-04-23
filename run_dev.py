#!/usr/bin/env python3
"""
Screen Dreams - Main entry point for UVX deployment
Development runner with debug mode enabled
"""

import os
import sys

def main():
    """Main entry point for UVX deployment"""
    # Set debug mode before importing the app
    os.environ['FLASK_DEBUG'] = 'True'
    
    # Dev mode always runs on port 5000 (Flask auto-reload requires a fixed port)
    port = 5000
    data_dir = os.environ.get(
        'DATA_DIR',
        os.path.join(os.path.expanduser('~'), '.local', 'share', 'screen-dreams')
    )

    # Import and run the app
    try:
        from app import create_app
        app = create_app()
        
        print("Screen Dreams - AI Screenwriting Application")
        print("=" * 50)
        print("Mode: Development")
        print(f"Server: http://localhost:{port}")
        print(f"Data dir: {data_dir}")
        print("Debug mode: ENABLED")
        print("Auto-reload: ENABLED")
        print("Interactive debugger: ENABLED")
        print("=" * 50)
        print("For production mode, use: screen-dreams-prod")
        print()
        
        # Run with debug enabled
        app.run(debug=True, host='0.0.0.0', port=port)
        
    except ImportError as e:
        print(f"Import error: {e}")
        print("Please ensure all dependencies are installed")
        sys.exit(1)
    except Exception as e:
        print(f"Startup error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
