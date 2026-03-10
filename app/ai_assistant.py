import requests
import json
from typing import List, Dict, Optional

class OllamaAssistant:
    """AI assistant using Ollama for screenplay suggestions"""
    
    def __init__(self, base_url: str = "http://localhost:11434"):
        self.base_url = base_url
        self.model = "llama2"  # Default model, can be configured
    
    def is_available(self) -> bool:
        """Check if Ollama is running"""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=2)
            return response.status_code == 200
        except:
            return False
    
    def generate(self, prompt: str, context: str = "") -> str:
        """Generate text using Ollama"""
        try:
            full_prompt = f"{context}\n\n{prompt}" if context else prompt
            
            response = requests.post(
                f"{self.base_url}/api/generate",
                json={
                    "model": self.model,
                    "prompt": full_prompt,
                    "stream": False
                },
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json().get('response', '')
            return ""
        except Exception as e:
            print(f"Error generating with Ollama: {e}")
            return ""
    
    def suggest_character_arc(self, character_name: str, character_description: str, screenplay_context: str) -> str:
        """Suggest character arc development"""
        prompt = f"""You are a professional screenplay consultant. Analyze the following character and suggest a compelling character arc.

Character: {character_name}
Description: {character_description}

Context from screenplay:
{screenplay_context[:1000]}

Provide a brief character arc suggestion (3-5 sentences) focusing on:
1. Character's starting point
2. Key transformation
3. Final state

Suggestion:"""
        
        return self.generate(prompt)
    
    def suggest_plot_development(self, current_scenes: List[str], characters: List[str]) -> str:
        """Suggest plot development based on current screenplay"""
        scenes_text = "\n".join([f"- {scene}" for scene in current_scenes[:10]])
        characters_text = ", ".join(characters[:10])
        
        prompt = f"""You are a professional screenplay consultant. Based on the following scenes and characters, suggest the next plot development.

Characters: {characters_text}

Recent scenes:
{scenes_text}

Provide a brief plot suggestion (3-5 sentences) for what could happen next, considering:
1. Character motivations
2. Conflict escalation
3. Story structure

Suggestion:"""
        
        return self.generate(prompt)
    
    def enhance_dialogue(self, character_name: str, dialogue: str, context: str = "") -> str:
        """Suggest improvements to dialogue"""
        prompt = f"""You are a professional screenplay dialogue coach. Improve the following dialogue while maintaining the character's voice.

Character: {character_name}
Current dialogue: {dialogue}

{f'Context: {context}' if context else ''}

Provide an improved version of the dialogue that is:
1. More natural and authentic
2. Character-specific
3. Concise and impactful

Improved dialogue:"""
        
        return self.generate(prompt)
    
    def check_spelling_grammar(self, text: str) -> List[Dict]:
        """Check spelling and grammar (basic implementation)"""
        # This is a simplified version - in production, you might use a dedicated library
        # or more sophisticated Ollama prompting
        prompt = f"""Check the following text for spelling and grammar errors. List any errors found.

Text: {text}

Errors (if any):"""
        
        result = self.generate(prompt)
        
        # Parse result into structured format
        # For now, return as simple list
        return [{"text": result}] if result else []
    
    def autocomplete_character(self, partial_name: str, known_characters: List[str]) -> List[str]:
        """Autocomplete character names"""
        # Simple matching - could be enhanced with Ollama for fuzzy matching
        matches = [char for char in known_characters if char.upper().startswith(partial_name.upper())]
        return sorted(matches)
    
    def suggest_scene_heading(self, partial_text: str) -> List[str]:
        """Suggest scene heading completions"""
        common_locations = [
            "INT. COFFEE SHOP - DAY",
            "INT. OFFICE - DAY",
            "INT. APARTMENT - NIGHT",
            "EXT. STREET - DAY",
            "EXT. PARK - DAY",
            "INT. CAR - DAY",
            "INT. RESTAURANT - NIGHT",
            "EXT. BUILDING - DAY",
            "INT. BEDROOM - NIGHT",
            "INT. KITCHEN - MORNING"
        ]
        
        if not partial_text:
            return common_locations[:5]
        
        matches = [loc for loc in common_locations if partial_text.upper() in loc]
        return matches[:5]
