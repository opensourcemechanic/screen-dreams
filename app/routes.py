from flask import Blueprint, render_template, request, jsonify, send_file, current_app
from app import db
from app.models import Screenplay, Scene, Character
from app.screenplay import FountainParser
from app.pdf_generator import ScreenplayPDFGenerator
from app.ai_assistant import OllamaAssistant
import os
from datetime import datetime

main = Blueprint('main', __name__)
parser = FountainParser()
pdf_generator = ScreenplayPDFGenerator()
ai_assistant = OllamaAssistant()

@main.route('/')
def index():
    """Main editor page"""
    screenplays = Screenplay.query.order_by(Screenplay.updated_at.desc()).all()
    return render_template('index.html', screenplays=screenplays)

@main.route('/screenplay/<int:screenplay_id>')
def edit_screenplay(screenplay_id):
    """Edit specific screenplay"""
    screenplay = Screenplay.query.get_or_404(screenplay_id)
    return render_template('editor.html', screenplay=screenplay)

@main.route('/characters/<int:screenplay_id>')
def characters(screenplay_id):
    """Character management page"""
    screenplay = Screenplay.query.get_or_404(screenplay_id)
    return render_template('characters.html', screenplay=screenplay)

@main.route('/scenes/<int:screenplay_id>')
def scenes(screenplay_id):
    """Scene organization page"""
    screenplay = Screenplay.query.get_or_404(screenplay_id)
    return render_template('scenes.html', screenplay=screenplay)

# API Routes

@main.route('/api/screenplays', methods=['GET', 'POST'])
def api_screenplays():
    """Get all screenplays or create new one"""
    if request.method == 'POST':
        data = request.json
        screenplay = Screenplay(
            title=data.get('title', 'Untitled'),
            author=data.get('author', ''),
            content=data.get('content', '')
        )
        db.session.add(screenplay)
        db.session.commit()
        return jsonify({
            'id': screenplay.id,
            'title': screenplay.title,
            'author': screenplay.author,
            'created_at': screenplay.created_at.isoformat()
        }), 201
    
    screenplays = Screenplay.query.order_by(Screenplay.updated_at.desc()).all()
    return jsonify([{
        'id': s.id,
        'title': s.title,
        'author': s.author,
        'updated_at': s.updated_at.isoformat()
    } for s in screenplays])

@main.route('/api/screenplay/<int:screenplay_id>', methods=['GET', 'PUT', 'DELETE'])
def api_screenplay(screenplay_id):
    """Get, update, or delete screenplay"""
    screenplay = Screenplay.query.get_or_404(screenplay_id)
    
    if request.method == 'DELETE':
        db.session.delete(screenplay)
        db.session.commit()
        return '', 204
    
    if request.method == 'PUT':
        data = request.json
        screenplay.title = data.get('title', screenplay.title)
        screenplay.author = data.get('author', screenplay.author)
        screenplay.content = data.get('content', screenplay.content)
        screenplay.updated_at = datetime.utcnow()
        db.session.commit()
    
    return jsonify({
        'id': screenplay.id,
        'title': screenplay.title,
        'author': screenplay.author,
        'content': screenplay.content,
        'created_at': screenplay.created_at.isoformat(),
        'updated_at': screenplay.updated_at.isoformat()
    })

@main.route('/api/screenplay/<int:screenplay_id>/parse', methods=['POST'])
def api_parse_screenplay(screenplay_id):
    """Parse screenplay and extract scenes/characters"""
    screenplay = Screenplay.query.get_or_404(screenplay_id)
    
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
def api_generate_pdf(screenplay_id):
    """Generate PDF for screenplay"""
    screenplay = Screenplay.query.get_or_404(screenplay_id)
    
    screenplay_data = {
        'title': screenplay.title,
        'author': screenplay.author,
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
def api_characters(screenplay_id):
    """Get or create characters"""
    screenplay = Screenplay.query.get_or_404(screenplay_id)
    
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

@main.route('/api/character/<int:character_id>', methods=['PUT', 'DELETE'])
def api_character(character_id):
    """Update or delete character"""
    character = Character.query.get_or_404(character_id)
    
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
def api_ai_character_arc():
    """Get AI suggestion for character arc"""
    if not ai_assistant.is_available():
        return jsonify({'error': 'AI assistant not available'}), 503
    
    data = request.json
    suggestion = ai_assistant.suggest_character_arc(
        data.get('character_name'),
        data.get('character_description', ''),
        data.get('screenplay_context', '')
    )
    
    return jsonify({'suggestion': suggestion})

@main.route('/api/ai/plot-development', methods=['POST'])
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
def api_ai_status():
    """Check if AI assistant is available"""
    return jsonify({'available': ai_assistant.is_available()})
