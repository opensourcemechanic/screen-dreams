#!/usr/bin/env python3
"""
Examples of using Flask debugger for troubleshooting
"""

from flask import Flask, request, jsonify
from app import create_app
import os

# Create app for debugging
app = create_app()

@app.route('/debug/example1')
def debug_example1():
    """Example 1: Basic debugging with print statements"""
    print(f"🐞 DEBUG: Request method: {request.method}")
    print(f"🐞 DEBUG: Request args: {dict(request.args)}")
    print(f"🐞 DEBUG: Request headers: {dict(request.headers)}")
    
    # This will trigger the interactive debugger
    if request.args.get('trigger_error'):
        raise ValueError("This is a deliberate error for debugging!")
    
    return jsonify({
        'message': 'Debug example 1',
        'debug_info': {
            'method': request.method,
            'args': dict(request.args),
            'user_agent': request.headers.get('User-Agent')
        }
    })

@app.route('/debug/example2')
def debug_example2():
    """Example 2: Debugging with assertions"""
    user_id = request.args.get('user_id', '1')
    
    # Assertion will stop execution in debug mode
    assert user_id.isdigit(), f"User ID must be numeric, got: {user_id}"
    assert int(user_id) > 0, f"User ID must be positive, got: {user_id}"
    
    return jsonify({
        'message': 'Debug example 2',
        'user_id': int(user_id),
        'validation': 'passed'
    })

@app.route('/debug/example3')
def debug_example3():
    """Example 3: Debugging database operations"""
    from app.models import User, Character, Screenplay
    
    print(f"🐞 DEBUG: Database session: {db.session}")
    print(f"🐞 DEBUG: Total users: {User.query.count()}")
    print(f"🐞 DEBUG: Total characters: {Character.query.count()}")
    print(f"🐞 DEBUG: Total screenplays: {Screenplay.query.count()}")
    
    # Get first user for debugging
    first_user = User.query.first()
    if first_user:
        print(f"🐞 DEBUG: First user: {first_user.email}")
        print(f"🐞 DEBUG: First user ID: {first_user.id}")
        print(f"🐞 DEBUG: First user active: {first_user.active}")
    
    return jsonify({
        'message': 'Debug example 3',
        'database_stats': {
            'users': User.query.count(),
            'characters': Character.query.count(),
            'screenplays': Screenplay.query.count()
        }
    })

@app.route('/debug/example4')
def debug_example4():
    """Example 4: Debugging AI assistant"""
    from app.ai_assistant import OllamaAssistant
    
    ai = OllamaAssistant()
    
    print(f"🐞 DEBUG: AI base URL: {ai.base_url}")
    print(f"🐞 DEBUG: AI model: {ai.model}")
    print(f"🐞 DEBUG: AI timeout: {ai.timeout}")
    print(f"🐞 DEBUG: AI available: {ai.is_available()}")
    
    # Test AI with debug info
    test_prompt = "A character named John who is a detective"
    print(f"🐞 DEBUG: Testing prompt: {test_prompt}")
    
    if ai.is_available():
        try:
            result = ai.suggest_character_arc("John", "detective", "")
            print(f"🐞 DEBUG: AI result length: {len(result)}")
            print(f"🐞 DEBUG: AI result preview: {result[:100]}...")
        except Exception as e:
            print(f"🐞 DEBUG: AI error: {e}")
    else:
        print("🐞 DEBUG: AI not available")
    
    return jsonify({
        'message': 'Debug example 4',
        'ai_status': {
            'available': ai.is_available(),
            'model': ai.model,
            'base_url': ai.base_url,
            'timeout': ai.timeout
        }
    })

@app.route('/debug/example5')
def debug_example5():
    """Example 5: Debugging authentication"""
    from flask_login import current_user
    
    print(f"🐞 DEBUG: Current user authenticated: {current_user.is_authenticated}")
    print(f"🐞 DEBUG: Current user ID: {current_user.get_id()}")
    print(f"🐞 DEBUG: Session data: {dict(session)}")
    
    if current_user.is_authenticated:
        print(f"🐞 DEBUG: User email: {current_user.email}")
        print(f"🐞 DEBUG: User username: {current_user.username}")
        print(f"🐞 DEBUG: User active: {current_user.active}")
        
        # Get user's screenplays
        from app.models import Screenplay
        user_screenplays = Screenplay.query.filter_by(user_id=current_user.id).all()
        print(f"🐞 DEBUG: User screenplays count: {len(user_screenplays)}")
        
        for screenplay in user_screenplays:
            print(f"🐞 DEBUG: Screenplay: {screenplay.title} (ID: {screenplay.id})")
    
    return jsonify({
        'message': 'Debug example 5',
        'auth_status': {
            'authenticated': current_user.is_authenticated,
            'user_id': current_user.get_id() if current_user.is_authenticated else None,
            'session_keys': list(session.keys())
        }
    })

if __name__ == '__main__':
    print("🔧 Flask Debug Examples")
    print("=" * 40)
    print("Run these URLs to test debugging:")
    print("  http://127.0.0.1:5000/debug/example1")
    print("  http://127.0.0.1:5000/debug/example1?trigger_error=1")
    print("  http://127.0.0.1:5000/debug/example2")
    print("  http://127.0.0.1:5000/debug/example2?user_id=abc")
    print("  http://127.0.0.1:5000/debug/example3")
    print("  http://127.0.0.1:5000/debug/example4")
    print("  http://127.0.0.1:5000/debug/example5")
    print("\n🐞 Starting debug server...")
    
    # Import db for example3
    from app import db
    
    app.run(debug=True, host='127.0.0.1', port=5000)
