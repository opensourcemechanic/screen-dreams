from flask import Blueprint, render_template, request, jsonify, send_file, current_app, redirect, url_for, flash
from flask_login import login_required, current_user
from app import db
from app.models import Screenplay, Scene, Character, User, ScreenplayChange, PromptConfig
from app.screenplay import FountainParser
from app.pdf_generator import ScreenplayPDFGenerator
from app.ai_assistant import OllamaAssistant
import os
from datetime import datetime, timedelta

main = Blueprint('main', __name__)
parser = FountainParser()
pdf_generator = ScreenplayPDFGenerator()
ai_assistant = OllamaAssistant()

# Debug route to check users
@main.route('/debug/users')
def debug_users():
    from app.models import User
    users = User.query.all()
    user_list = []
    for user in users:
        user_list.append({
            'email': user.email,
            'username': user.username,
            'active': user.active,
            'confirmed_at': str(user.confirmed_at) if user.confirmed_at else None
        })
    return jsonify({'users': user_list, 'count': len(user_list)})

# Debug route to test form submission
@main.route('/debug/register-test', methods=['POST'])
def debug_register_test():
    return jsonify({
        'status': 'success',
        'message': 'Form submission received',
        'data': request.form.to_dict()
    })

# Test registration page
@main.route('/debug/test-register')
def test_register():
    from flask import current_app
    from flask_security.forms import RegisterForm
    form = RegisterForm()
    return render_template('test_register.html', register_user_form=form)

# Main application routes
@main.route('/')
@login_required
def index():
    """Main page with user's screenplays"""
    screenplays = Screenplay.query.filter_by(user_id=current_user.id).order_by(Screenplay.updated_at.desc()).all()
    return render_template('index.html', screenplays=screenplays)

@main.route('/screenplay/<int:screenplay_id>')
@login_required
def edit_screenplay(screenplay_id):
    """Edit specific screenplay (user must own it)"""
    screenplay = Screenplay.query.filter_by(id=screenplay_id, user_id=current_user.id).first_or_404()
    return render_template('editor.html', screenplay=screenplay)

@main.route('/characters/<int:screenplay_id>')
@login_required
def characters(screenplay_id):
    """Character management page (user must own screenplay)"""
    screenplay = Screenplay.query.filter_by(id=screenplay_id, user_id=current_user.id).first_or_404()
    return render_template('characters.html', screenplay=screenplay)

@main.route('/scenes/<int:screenplay_id>')
@login_required
def scenes(screenplay_id):
    """Scene organization page (user must own screenplay)"""
    screenplay = Screenplay.query.filter_by(id=screenplay_id, user_id=current_user.id).first_or_404()
    return render_template('scenes.html', screenplay=screenplay)

# API Routes
@main.route('/api/screenplays', methods=['GET', 'POST'])
@login_required
def api_screenplays():
    """Get user's screenplays or create new one"""
    if request.method == 'POST':
        data = request.json
        screenplay = Screenplay(
            title=data.get('title', 'Untitled'),
            content=data.get('content', ''),
            user_id=current_user.id
        )
        db.session.add(screenplay)
        db.session.commit()
        return jsonify({
            'id': screenplay.id,
            'title': screenplay.title,
            'created_at': screenplay.created_at.isoformat()
        }), 201
    
    screenplays = Screenplay.query.filter_by(user_id=current_user.id).order_by(Screenplay.updated_at.desc()).all()
    return jsonify([{
        'id': s.id,
        'title': s.title,
        'updated_at': s.updated_at.isoformat()
    } for s in screenplays])

@main.route('/api/screenplay/<int:screenplay_id>', methods=['GET', 'PUT', 'DELETE'])
@login_required
def api_screenplay(screenplay_id):
    """Get, update, or delete screenplay (user must own it)"""
    screenplay = Screenplay.query.filter_by(id=screenplay_id, user_id=current_user.id).first_or_404()
    
    if request.method == 'DELETE':
        db.session.delete(screenplay)
        db.session.commit()
        return '', 204
    
    if request.method == 'PUT':
        data = request.json
        old_content = screenplay.content
        
        screenplay.title = data.get('title', screenplay.title)
        screenplay.content = data.get('content', screenplay.content)
        screenplay.updated_at = datetime.utcnow()
        
        # Track changes for undo/redo (only if content actually changed)
        if old_content != screenplay.content:
            change = ScreenplayChange(
                screenplay_id=screenplay.id,
                content=old_content,
                change_type='auto_save'
            )
            db.session.add(change)
            
            # Clean up old changes (keep only last 50)
            old_changes = ScreenplayChange.query.filter_by(screenplay_id=screenplay.id).order_by(ScreenplayChange.created_at.desc()).offset(50).all()
            for old_change in old_changes:
                db.session.delete(old_change)
        
        db.session.commit()
    
    return jsonify({
        'id': screenplay.id,
        'title': screenplay.title,
        'content': screenplay.content,
        'created_at': screenplay.created_at.isoformat(),
        'updated_at': screenplay.updated_at.isoformat()
    })

@main.route('/api/screenplay/<int:screenplay_id>/parse', methods=['POST'])
@login_required
def api_parse_screenplay(screenplay_id):
    """Parse screenplay and extract scenes/characters (user must own screenplay)"""
    screenplay = Screenplay.query.filter_by(id=screenplay_id, user_id=current_user.id).first_or_404()
    
    # Extract scenes
    scenes_data = parser.extract_scenes(screenplay.content)
    
    # Clear existing scenes
    Scene.query.filter_by(screenplay_id=screenplay_id).delete()
    
    # Add new scenes
    for scene_data in scenes_data:
        scene = Scene(
            screenplay_id=screenplay_id,
            scene_number=scene_data['scene_number'],
            heading=scene_data['heading'],
            location=scene_data['location'],
            time_of_day=scene_data['time_of_day'],
            content=scene_data['content'],
            order=scene_data['scene_number']
        )
        db.session.add(scene)
    
    # Extract characters
    character_names = parser.extract_characters(screenplay.content)
    existing_characters = {c.name for c in screenplay.characters}
    
    # Add new characters
    for name in character_names:
        if name not in existing_characters:
            character = Character(
                screenplay_id=screenplay_id,
                name=name
            )
            db.session.add(character)
    
    db.session.commit()
    
    return jsonify({
        'scenes': len(scenes_data),
        'characters': len(character_names)
    })

@main.route('/api/screenplay/<int:screenplay_id>/pdf', methods=['GET'])
@login_required
def api_generate_pdf(screenplay_id):
    """Generate PDF for screenplay (user must own it)"""
    screenplay = Screenplay.query.filter_by(id=screenplay_id, user_id=current_user.id).first_or_404()
    
    screenplay_data = {
        'title': screenplay.title,
        'author': current_user.username,
        'content': screenplay.content
    }
    
    pdf_buffer = pdf_generator.create_pdf(screenplay_data)
    
    return send_file(
        pdf_buffer,
        mimetype='application/pdf',
        as_attachment=True,
        download_name=f"{screenplay.title.replace(' ', '_')}.pdf"
    )

@main.route('/api/characters/<int:screenplay_id>', methods=['GET', 'POST'])
@login_required
def api_characters(screenplay_id):
    """Get or create characters (user must own screenplay)"""
    screenplay = Screenplay.query.filter_by(id=screenplay_id, user_id=current_user.id).first_or_404()
    
    if request.method == 'POST':
        data = request.json
        character = Character(
            screenplay_id=screenplay_id,
            name=data.get('name'),
            description=data.get('description', ''),
            arc_notes=data.get('arc_notes', '')
        )
        db.session.add(character)
        db.session.commit()
        return jsonify({
            'id': character.id,
            'name': character.name,
            'description': character.description,
            'arc_notes': character.arc_notes
        }), 201
    
    characters = Character.query.filter_by(screenplay_id=screenplay_id).all()
    return jsonify([{
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'arc_notes': c.arc_notes
    } for c in characters])

@main.route('/api/character/<int:character_id>', methods=['GET', 'PUT', 'DELETE'])
@login_required
def api_character(character_id):
    """Get, update, or delete character (user must own screenplay)"""
    character = Character.query.join(Screenplay).filter(
        Character.id == character_id,
        Screenplay.user_id == current_user.id
    ).first_or_404()
    
    if request.method == 'GET':
        return jsonify({
            'id': character.id,
            'name': character.name,
            'description': character.description,
            'arc_notes': character.arc_notes
        })
    
    if request.method == 'DELETE':
        db.session.delete(character)
        db.session.commit()
        return '', 204
    
    data = request.json
    character.name = data.get('name', character.name)
    character.description = data.get('description', character.description)
    character.arc_notes = data.get('arc_notes', character.arc_notes)
    db.session.commit()
    
    return jsonify({
        'id': character.id,
        'name': character.name,
        'description': character.description,
        'arc_notes': character.arc_notes
    })

@main.route('/api/ai/character-arc', methods=['POST'])
@login_required
def api_ai_character_arc():
    """Get AI suggestion for character arc"""
    if not ai_assistant.is_available():
        return jsonify({'error': 'AI assistant not available'}), 503
    
    data = request.json
    character_id = data.get('character_id')
    character_name = data.get('character_name')
    character_description = data.get('character_description', '')
    screenplay_context = data.get('screenplay_context', '')
    
    # Generate suggestion
    suggestion = ai_assistant.suggest_character_arc(
        character_name,
        character_description,
        screenplay_context
    )
    
    # Save suggestion to database if character_id provided
    if character_id:
        character = Character.query.get(character_id)
        if character and character.screenplay.user_id == current_user.id:
            character.ai_arc_suggestion = suggestion
            character.ai_suggestion_updated = datetime.utcnow()
            db.session.commit()
    
    return jsonify({'suggestion': suggestion})

@main.route('/api/ai/plot-development', methods=['POST'])
@login_required
def api_ai_plot_development():
    """Get AI suggestion for plot development"""
    if not ai_assistant.is_available():
        return jsonify({'error': 'AI assistant not available'}), 503
    
    data = request.json
    suggestion = ai_assistant.suggest_plot_development(
        data.get('scenes', []),
        data.get('characters', [])
    )
    
    return jsonify({'suggestion': suggestion})

@main.route('/api/ai/enhance-dialogue', methods=['POST'])
@login_required
def api_ai_enhance_dialogue():
    """Get AI suggestion for dialogue enhancement"""
    if not ai_assistant.is_available():
        return jsonify({'error': 'AI assistant not available'}), 503
    
    data = request.json
    suggestion = ai_assistant.enhance_dialogue(
        data.get('character_name'),
        data.get('dialogue'),
        data.get('context', '')
    )
    
    return jsonify({'suggestion': suggestion})

@main.route('/api/ai/status', methods=['GET'])
@login_required
def api_ai_status():
    """Check if AI assistant is available"""
    available = ai_assistant.is_available()
    model_available = ai_assistant.check_model() if available else False
    
    return jsonify({
        'available': available,
        'model_available': model_available,
        'model': ai_assistant.model,
        'base_url': ai_assistant.base_url,
        'timeout': ai_assistant.timeout
    })

@main.route('/api/config', methods=['GET'])
@login_required
def api_config():
    """Get configuration for frontend"""
    return jsonify({
        'auto_save_interval': current_app.config['AUTO_SAVE_INTERVAL'],
        'username': current_user.username,
        'is_demo': current_user.email == 'demo@example.com'
    })

@main.route('/screenplay/<int:screenplay_id>/prompt-editor', methods=['GET', 'POST'])
@login_required
def prompt_editor(screenplay_id):
    """AI prompt editor page"""
    # Get screenplay
    screenplay = Screenplay.query.filter_by(id=screenplay_id, user_id=current_user.id).first_or_404()
    
    # Get or create prompt config
    config = PromptConfig.query.filter_by(user_id=current_user.id).first()
    if not config:
        config = PromptConfig(user_id=current_user.id, max_characters=2000)
        db.session.add(config)
        db.session.commit()
    
    if request.method == 'POST':
        data = request.get_json()
        
        # Update config
        config.max_characters = data.get('max_characters', 2000)
        config.character_arc_prompt = data.get('character_arc_prompt')
        config.plot_development_prompt = data.get('plot_development_prompt')
        config.dialogue_enhancement_prompt = data.get('dialogue_enhancement_prompt')
        config.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({'success': True})
    
    return render_template('prompt_editor.html', screenplay=screenplay, config=config)
