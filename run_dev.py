#!/usr/bin/env python3
"""
Development runner with debug mode enabled
Use this for active development and debugging
"""

import os
import sys

# Set debug mode before importing the app
os.environ['FLASK_DEBUG'] = 'True'

# Import and run the app
from app import create_app

app = create_app()

if __name__ == '__main__':
    # Create screenplays folder if it doesn't exist
    os.makedirs('screenplays', exist_ok=True)
    
    print("🔧 Development Mode (Debug ON)")
    print("=" * 40)
    print("🐛 Debug mode: ENABLED")
    print("🌐 Server: http://127.0.0.1:5000")
    print("📝 Auto-reload: ENABLED")
    print("🔍 Interactive debugger: ENABLED")
    print("=" * 40)
    print("💡 For production mode, use: python run.py")
    print()
    
    # Run with debug enabled
    app.run(debug=True, host='0.0.0.0', port=5000)
