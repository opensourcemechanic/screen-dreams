from app import create_app
import os

app = create_app()

if __name__ == '__main__':
    # Create screenplays folder if it doesn't exist
    os.makedirs('screenplays', exist_ok=True)
    
    # Run the application
    app.run(debug=True, host='0.0.0.0', port=5000)
