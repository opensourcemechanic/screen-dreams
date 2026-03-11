from app import create_app
import os

app = create_app()

if __name__ == '__main__':
    # Create screenplays folder if it doesn't exist
    os.makedirs('screenplays', exist_ok=True)
    
    # Debug mode controlled by environment variable (default: False)
    debug_mode = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    
    print(f"🚀 Starting Flask app...")
    print(f"🐛 Debug mode: {'ON' if debug_mode else 'OFF'}")
    print(f"🌐 Server: http://127.0.0.1:5000")
    if not debug_mode:
        print(f"💡 Enable debug mode with: export FLASK_DEBUG=True")
    
    # Run the application
    app.run(debug=debug_mode, host='0.0.0.0', port=5000)
