#!/usr/bin/env python3
"""
Screen Dreams - Production entry point
"""

import os
import sys
from pathlib import Path

def main():
    """Production entry point"""
    # Create necessary directories
    directories = ['uploads', 'screenplays', 'logs', 'static']
    for directory in directories:
        Path(directory).mkdir(exist_ok=True)
    
    # Import and run the app
    try:
        from app import create_app
        app = create_app()
        
        # Debug mode controlled by environment variable (default: False)
        debug_mode = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
        
        print("Screen Dreams - AI Screenwriting Application")
        print("=" * 50)
        print("Mode: Production")
        print("Server: http://localhost:5000")
        print(f"Debug mode: {'ON' if debug_mode else 'OFF'}")
        if not debug_mode:
            print("Enable debug mode with: export FLASK_DEBUG=True")
        print("=" * 50)
        print()
        
        # Run the application
        app.run(debug=debug_mode, host='0.0.0.0', port=5000)
        
    except ImportError as e:
        print(f"Import error: {e}")
        print("Please ensure all dependencies are installed")
        sys.exit(1)
    except Exception as e:
        print(f"Startup error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
