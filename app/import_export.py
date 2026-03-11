"""
Import/Export functionality for screenplays
Supports Fountain, Final Draft (FDX), and plain text formats
"""

import os
import xml.etree.ElementTree as ET
from datetime import datetime
from flask import jsonify, request, send_file
from flask_login import login_required, current_user
from app import db
from app.models import Screenplay
import re
import tempfile
import zipfile
import json


class ImportExportManager:
    """Handles screenplay import/export operations"""
    
    @staticmethod
    def export_fountain(screenplay):
        """Export screenplay in Fountain format"""
        return screenplay.content or ""
    
    @staticmethod
    def export_plain_text(screenplay):
        """Export screenplay as plain text (remove Fountain syntax)"""
        content = screenplay.content or ""
        
        # Remove Fountain syntax elements
        content = re.sub(r'^#+\s*', '', content, flags=re.MULTILINE)  # Scene headings
        content = re.sub(r'^[A-Z][A-Z\s]+$', '', content, flags=re.MULTILINE)  # Character names
        content = re.sub(r'^\([^\)]*\)$', '', content, flags=re.MULTILINE)  # Parentheticals
        content = re.sub(r'^\s*\*\s*.*$', '', content, flags=re.MULTILINE)  # Comments
        content = re.sub(r'^\s*>\s*.*$', '', content, flags=re.MULTILINE)  # Notes
        
        return content.strip()
    
    @staticmethod
    def export_final_draft(screenplay):
        """Export screenplay in Final Draft FDX format"""
        content = screenplay.content or ""
        title = screenplay.title or "Untitled"
        
        # Create FDX XML structure
        root = ET.Element("FinalDraft")
        document = ET.SubElement(root, "Content")
        
        # Add title page
        title_page = ET.SubElement(document, "TitlePage")
        ET.SubElement(title_page, "Content").text = title
        
        # Parse and convert Fountain content to FDX
        lines = content.split('\n')
        current_scene = None
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
                
            paragraph = ET.SubElement(document, "Paragraph")
            
            # Scene heading
            if re.match(r'^(INT\.|EXT\.|I/E\.)', line, re.IGNORECASE):
                paragraph.set("Type", "Scene Heading")
                ET.SubElement(paragraph, "Text").text = line
                current_scene = line
                
            # Character name
            elif re.match(r'^[A-Z][A-Z\s]+$', line) and len(line) < 30:
                paragraph.set("Type", "Character")
                ET.SubElement(paragraph, "Text").text = line
                
            # Parenthetical
            elif line.startswith('(') and line.endswith(')'):
                paragraph.set("Type", "Parenthetical")
                ET.SubElement(paragraph, "Text").text = line
                
            # Dialogue
            elif current_scene and not line.startswith('#'):
                paragraph.set("Type", "Dialogue")
                ET.SubElement(paragraph, "Text").text = line
                
            # Action/Treatment
            else:
                paragraph.set("Type", "Action")
                ET.SubElement(paragraph, "Text").text = line
        
        # Convert to XML string
        xml_str = ET.tostring(root, encoding='unicode', xml_declaration=True)
        return xml_str
    
    @staticmethod
    def import_fountain(content, title=None):
        """Import screenplay from Fountain format"""
        # Fountain is the native format, so just return as-is
        return content.strip()
    
    @staticmethod
    def import_plain_text(content, title=None):
        """Import screenplay from plain text and convert to Fountain format"""
        lines = content.split('\n')
        fountain_lines = []
        
        for line in lines:
            line = line.strip()
            if not line:
                fountain_lines.append("")
                continue
                
            # Try to detect scene headings
            if re.match(r'^(INT\.|EXT\.|I/E\.|INT\./EXT\.)', line, re.IGNORECASE):
                fountain_lines.append(line.upper())
            # Try to detect character names (all caps, short)
            elif re.match(r'^[A-Z][A-Z\s]+$', line) and len(line) < 30:
                fountain_lines.append(line)
            # Everything else as action
            else:
                fountain_lines.append(line)
        
        return '\n'.join(fountain_lines)
    
    @staticmethod
    def import_final_draft(content, title=None):
        """Import screenplay from Final Draft FDX format"""
        try:
            root = ET.fromstring(content)
            fountain_lines = []
            
            for paragraph in root.findall(".//Paragraph"):
                para_type = paragraph.get("Type", "")
                text_elem = paragraph.find("Text")
                if text_elem is None:
                    continue
                    
                text = text_elem.text or ""
                
                if para_type == "Scene Heading":
                    fountain_lines.append(text.upper())
                elif para_type == "Character":
                    fountain_lines.append(text)
                elif para_type == "Dialogue":
                    fountain_lines.append(text)
                elif para_type == "Parenthetical":
                    fountain_lines.append(f"({text})")
                elif para_type == "Action":
                    fountain_lines.append(text)
                else:
                    fountain_lines.append(text)
            
            return '\n'.join(fountain_lines)
            
        except ET.ParseError as e:
            raise ValueError(f"Invalid Final Draft FDX format: {e}")
    
    @staticmethod
    def create_backup_package(screenplay):
        """Create a complete backup package with all formats"""
        backup_data = {
            'title': screenplay.title,
            'created_at': datetime.now().isoformat(),
            'content': screenplay.content,
            'formats': {
                'fountain': ImportExportManager.export_fountain(screenplay),
                'plain_text': ImportExportManager.export_plain_text(screenplay),
                'final_draft': ImportExportManager.export_final_draft(screenplay)
            },
            'metadata': {
                'character_count': len(screenplay.characters) if screenplay.characters else 0,
                'word_count': len(screenplay.content.split()) if screenplay.content else 0,
                'line_count': len(screenplay.content.split('\n')) if screenplay.content else 0
            }
        }
        
        return backup_data


# API Endpoints
def register_import_export_routes(blueprint):
    
    @blueprint.route('/api/screenplay/<int:screenplay_id>/export/<format>')
    @login_required
    def export_screenplay(screenplay_id, format):
        """Export screenplay in specified format"""
        screenplay = Screenplay.query.get_or_404(screenplay_id)
        
        # Check ownership
        if screenplay.user_id != current_user.id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        try:
            if format == 'fountain':
                content = ImportExportManager.export_fountain(screenplay)
                filename = f"{screenplay.title or 'screenplay'}.fountain"
                mimetype = 'text/plain'
                
            elif format == 'plain_text':
                content = ImportExportManager.export_plain_text(screenplay)
                filename = f"{screenplay.title or 'screenplay'}.txt"
                mimetype = 'text/plain'
                
            elif format == 'final_draft':
                content = ImportExportManager.export_final_draft(screenplay)
                filename = f"{screenplay.title or 'screenplay'}.fdx"
                mimetype = 'application/xml'
                
            elif format == 'backup':
                # Create backup package
                backup_data = ImportExportManager.create_backup_package(screenplay)
                content = json.dumps(backup_data, indent=2)
                filename = f"{screenplay.title or 'screenplay'}_backup.json"
                mimetype = 'application/json'
                
            else:
                return jsonify({'error': 'Unsupported format'}), 400
            
            # Create temporary file
            with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix=os.path.splitext(filename)[1]) as f:
                f.write(content)
                temp_path = f.name
            
            return send_file(temp_path, as_attachment=True, download_name=filename, mimetype=mimetype)
            
        except Exception as e:
            return jsonify({'error': f'Export failed: {str(e)}'}), 500
    
    @blueprint.route('/api/screenplay/import', methods=['POST'])
    @login_required
    def import_screenplay():
        """Import screenplay from uploaded file"""
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Get format and title from form
        format_type = request.form.get('format', 'auto')
        title = request.form.get('title', '')
        
        try:
            # Read file content
            content = file.read().decode('utf-8')
            filename = file.filename.lower()
            
            # Auto-detect format if not specified
            if format_type == 'auto':
                if filename.endswith('.fdx'):
                    format_type = 'final_draft'
                elif filename.endswith('.fountain') or filename.endswith('.txt'):
                    format_type = 'fountain'
                else:
                    # Try to detect by content
                    if content.strip().startswith('<?xml'):
                        format_type = 'final_draft'
                    else:
                        format_type = 'fountain'
            
            # Import based on format
            if format_type == 'fountain':
                imported_content = ImportExportManager.import_fountain(content, title)
            elif format_type == 'plain_text':
                imported_content = ImportExportManager.import_plain_text(content, title)
            elif format_type == 'final_draft':
                imported_content = ImportExportManager.import_final_draft(content, title)
            else:
                return jsonify({'error': 'Unsupported import format'}), 400
            
            # Create new screenplay
            if not title:
                title = os.path.splitext(file.filename)[0] or "Imported Screenplay"
            
            screenplay = Screenplay(
                title=title,
                content=imported_content,
                user_id=current_user.id
            )
            
            db.session.add(screenplay)
            db.session.commit()
            
            return jsonify({
                'success': True,
                'screenplay': {
                    'id': screenplay.id,
                    'title': screenplay.title,
                    'content': screenplay.content
                }
            })
            
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Import failed: {str(e)}'}), 500
    
    @blueprint.route('/api/screenplay/<int:screenplay_id>/backup', methods=['POST'])
    @login_required
    def create_backup(screenplay_id):
        """Create a backup of the screenplay"""
        screenplay = Screenplay.query.get_or_404(screenplay_id)
        
        # Check ownership
        if screenplay.user_id != current_user.id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        try:
            backup_data = ImportExportManager.create_backup_package(screenplay)
            
            # Check if content has changed since last backup
            # Simple hash-based change detection
            import hashlib
            content_hash = hashlib.sha256(screenplay.content.encode('utf-8')).hexdigest()
            
            # Check last backup hash from localStorage (client-side)
            # For now, we'll let the client handle this logic
            # but we provide the hash for comparison
            
            # Add hash to backup data
            backup_data['content_hash'] = content_hash
            
            # Return backup data with hash for client-side comparison
            return jsonify({
                'success': True,
                'backup': backup_data,
                'content_hash': content_hash
            })
            
        except Exception as e:
            return jsonify({'error': f'Backup failed: {str(e)}'}), 500
    
    @blueprint.route('/api/screenplay/restore', methods=['POST'])
    @login_required
    def restore_from_backup():
        """Restore screenplay from backup data"""
        data = request.get_json()
        
        if not data or 'backup' not in data:
            return jsonify({'error': 'No backup data provided'}), 400
        
        try:
            backup = data['backup']
            
            # Create new screenplay from backup
            screenplay = Screenplay(
                title=backup.get('title', 'Restored Screenplay'),
                content=backup.get('content', ''),
                user_id=current_user.id
            )
            
            db.session.add(screenplay)
            db.session.commit()
            
            return jsonify({
                'success': True,
                'screenplay': {
                    'id': screenplay.id,
                    'title': screenplay.title,
                    'content': screenplay.content
                }
            })
            
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Restore failed: {str(e)}'}), 500
    
    return blueprint
