import re
from typing import List, Dict, Tuple, Optional

class FountainParser:
    """Parser for Fountain screenplay format"""
    
    ANNOTATION_PREFIX_DESC = '[[DESCRIPTION:'
    ANNOTATION_PREFIX_ARC  = '[[ARC:'
    ANNOTATION_SUFFIX      = ']]'
    ANNOTATION_PATTERN     = re.compile(r'^\[\[(DESCRIPTION|ARC):(.*)\]\]\s*$', re.IGNORECASE)

    def __init__(self):
        self.scene_heading_pattern = re.compile(r'^(INT|EXT|EST|INT\./EXT|INT/EXT|I/E)[\.\s]', re.IGNORECASE)
        self.character_pattern = re.compile(r'^[A-Za-z][A-Za-z\s]+$')
        self.transition_pattern = re.compile(r'^(FADE IN:|FADE OUT\.|CUT TO:|DISSOLVE TO:)', re.IGNORECASE)
        self.parenthetical_pattern = re.compile(r'^\([^)]+\)$')
        
    def parse(self, text: str) -> List[Dict]:
        """Parse Fountain text into structured elements"""
        lines = text.split('\n')
        elements = []
        i = 0
        
        while i < len(lines):
            line = lines[i].rstrip()
            
            # Skip empty lines
            if not line:
                i += 1
                continue
            
            # Scene heading
            if self.scene_heading_pattern.match(line):
                elements.append({
                    'type': 'scene_heading',
                    'content': line.upper(),
                    'line': i
                })
                i += 1
                continue
            
            # Transition
            if self.transition_pattern.match(line) or line.endswith('TO:'):
                elements.append({
                    'type': 'transition',
                    'content': line.upper(),
                    'line': i
                })
                i += 1
                continue
            
            # Character name (case-insensitive detection, converted to uppercase for consistency)
            if (self.character_pattern.match(line) and 
                i + 1 < len(lines) and 
                (lines[i + 1].strip().startswith('(') or 
                 (lines[i + 1].strip() and not self.scene_heading_pattern.match(lines[i + 1])))):
                
                # Convert to uppercase for screenplay/fountain standard consistency
                character_name = line.upper()
                
                elements.append({
                    'type': 'character',
                    'content': character_name,
                    'line': i
                })
                i += 1
                
                # Check for parenthetical
                if i < len(lines) and lines[i].strip().startswith('('):
                    elements.append({
                        'type': 'parenthetical',
                        'content': lines[i].strip(),
                        'line': i
                    })
                    i += 1
                
                # Collect dialogue
                dialogue_lines = []
                while i < len(lines) and lines[i].strip() and not self.scene_heading_pattern.match(lines[i]):
                    if self.character_pattern.match(lines[i].strip()):
                        break
                    dialogue_lines.append(lines[i].strip())
                    i += 1
                
                if dialogue_lines:
                    elements.append({
                        'type': 'dialogue',
                        'content': '\n'.join(dialogue_lines),
                        'line': i - len(dialogue_lines)
                    })
                continue
            
            # Action (default)
            elements.append({
                'type': 'action',
                'content': line,
                'line': i
            })
            i += 1
        
        return elements
    
    def extract_scenes(self, text: str) -> List[Dict]:
        """Extract scene information from screenplay"""
        elements = self.parse(text)
        scenes = []
        current_scene = None
        scene_number = 1
        
        for element in elements:
            if element['type'] == 'scene_heading':
                if current_scene:
                    scenes.append(current_scene)
                
                # Parse scene heading
                heading = element['content']
                parts = heading.split(' - ')
                location = parts[0] if parts else heading
                time_of_day = parts[1] if len(parts) > 1 else 'DAY'
                
                current_scene = {
                    'scene_number': scene_number,
                    'heading': heading,
                    'location': location,
                    'time_of_day': time_of_day,
                    'content': heading
                }
                scene_number += 1
            elif current_scene:
                current_scene['content'] += '\n' + element['content']
        
        if current_scene:
            scenes.append(current_scene)
        
        return scenes
    
    def extract_characters(self, text: str) -> List[str]:
        """Extract unique character names from screenplay and convert to uppercase for consistency"""
        elements = self.parse(text)
        characters = set()
        
        for element in elements:
            if element['type'] == 'character':
                # Remove (V.O.), (O.S.), etc.
                name = re.sub(r'\s*\([^)]+\)\s*$', '', element['content'])
                # Convert to uppercase for screenplay/fountain standard consistency
                name = name.strip().upper()
                characters.add(name)
        
        return sorted(list(characters))

    def read_annotations(self, text: str, character_name: str) -> Dict[str, str]:
        """Read [[DESCRIPTION:...]] and [[ARC:...]] annotations for a character from screenplay text."""
        name_upper = character_name.strip().upper()
        lines = text.split('\n')
        result = {'description': '', 'arc_notes': ''}
        i = 0
        while i < len(lines):
            stripped = lines[i].strip()
            if stripped.upper() == name_upper:
                # Look ahead for annotation lines immediately following this cue
                j = i + 1
                while j < len(lines):
                    ann = lines[j].strip()
                    m = self.ANNOTATION_PATTERN.match(ann)
                    if m:
                        key = m.group(1).upper()
                        val = m.group(2).strip()
                        if key == 'DESCRIPTION':
                            result['description'] = val
                        elif key == 'ARC':
                            result['arc_notes'] = val
                        j += 1
                    else:
                        break
                break
            i += 1
        return result

    def write_annotations(self, text: str, character_name: str,
                          description: str = '', arc_notes: str = '') -> str:
        """Insert/update [[DESCRIPTION:...]] and [[ARC:...]] lines after the first
        occurrence of character_name as a cue line in the screenplay text.
        Existing annotation lines for that character are replaced; screenplay text
        is otherwise unchanged."""
        name_upper = character_name.strip().upper()
        lines = text.split('\n')
        result = []
        i = 0
        written = False
        while i < len(lines):
            stripped = lines[i].strip()
            if not written and stripped.upper() == name_upper:
                result.append(lines[i])  # keep the cue line as-is
                i += 1
                # Skip any existing annotation lines immediately after
                while i < len(lines) and self.ANNOTATION_PATTERN.match(lines[i].strip()):
                    i += 1
                # Insert updated annotations (omit empty ones to keep text clean)
                if description.strip():
                    result.append(f'{self.ANNOTATION_PREFIX_DESC} {description.strip()}{self.ANNOTATION_SUFFIX}')
                if arc_notes.strip():
                    result.append(f'{self.ANNOTATION_PREFIX_ARC} {arc_notes.strip()}{self.ANNOTATION_SUFFIX}')
                written = True
                continue
            result.append(lines[i])
            i += 1
        return '\n'.join(result)

    def strip_annotations(self, text: str) -> str:
        """Return screenplay text with all [[...]] annotation lines removed (for PDF export)."""
        lines = text.split('\n')
        return '\n'.join(l for l in lines if not self.ANNOTATION_PATTERN.match(l.strip()))
    
    def format_screenplay_content(self, text: str) -> str:
        """Format screenplay content with uppercase character names while preserving original formatting"""
        lines = text.split('\n')
        formatted_lines = []
        
        for i, line in enumerate(lines):
            stripped_line = line.strip()

            # Preserve annotation lines exactly
            if self.ANNOTATION_PATTERN.match(stripped_line):
                formatted_lines.append(line)
                continue
            
            # Check if this line is a character name using the same logic as the parser
            # Character names must be followed by dialogue, annotation, or parenthetical
            is_character = False
            if (self.character_pattern.match(stripped_line) and 
                not self.scene_heading_pattern.match(stripped_line) and
                not self.transition_pattern.match(stripped_line) and
                not self.parenthetical_pattern.match(stripped_line)):
                
                # Check if next non-annotation line exists and could be dialogue or parenthetical
                if i + 1 < len(lines):
                    # Skip past any annotation lines to find what follows
                    j = i + 1
                    while j < len(lines) and self.ANNOTATION_PATTERN.match(lines[j].strip()):
                        j += 1
                    next_line = lines[j].strip() if j < len(lines) else ''
                    if (next_line.startswith('(') or 
                        (next_line and not self.scene_heading_pattern.match(next_line) and
                         not self.character_pattern.match(next_line))):
                        is_character = True
            
            if is_character:
                # This is a character name - convert to uppercase while preserving original whitespace
                leading_whitespace = line[:len(line) - len(line.lstrip())]
                formatted_lines.append(leading_whitespace + stripped_line.upper())
            else:
                # Keep all other lines exactly as-is (preserving spacing, indentation, etc.)
                formatted_lines.append(line)
        
        return '\n'.join(formatted_lines)
    
    def format_for_display(self, text: str) -> str:
        """Format Fountain text for HTML display"""
        elements = self.parse(text)
        html_parts = []
        
        for element in elements:
            elem_type = element['type']
            content = element['content']
            
            if elem_type == 'scene_heading':
                html_parts.append(f'<div class="scene-heading">{content}</div>')
            elif elem_type == 'action':
                html_parts.append(f'<div class="action">{content}</div>')
            elif elem_type == 'character':
                html_parts.append(f'<div class="character">{content}</div>')
            elif elem_type == 'dialogue':
                html_parts.append(f'<div class="dialogue">{content}</div>')
            elif elem_type == 'parenthetical':
                html_parts.append(f'<div class="parenthetical">{content}</div>')
            elif elem_type == 'transition':
                html_parts.append(f'<div class="transition">{content}</div>')
        
        return '\n'.join(html_parts)
