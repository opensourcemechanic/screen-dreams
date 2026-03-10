import re
from typing import List, Dict, Tuple

class FountainParser:
    """Parser for Fountain screenplay format"""
    
    def __init__(self):
        self.scene_heading_pattern = re.compile(r'^(INT|EXT|EST|INT\./EXT|INT/EXT|I/E)[\.\s]', re.IGNORECASE)
        self.character_pattern = re.compile(r'^[A-Z][A-Z\s]+$')
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
            
            # Character name (all caps, followed by dialogue or parenthetical)
            if (self.character_pattern.match(line) and 
                i + 1 < len(lines) and 
                (lines[i + 1].strip().startswith('(') or 
                 (lines[i + 1].strip() and not self.scene_heading_pattern.match(lines[i + 1])))):
                
                elements.append({
                    'type': 'character',
                    'content': line,
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
        """Extract unique character names from screenplay"""
        elements = self.parse(text)
        characters = set()
        
        for element in elements:
            if element['type'] == 'character':
                # Remove (V.O.), (O.S.), etc.
                name = re.sub(r'\s*\([^)]+\)\s*$', '', element['content'])
                characters.add(name.strip())
        
        return sorted(list(characters))
    
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
