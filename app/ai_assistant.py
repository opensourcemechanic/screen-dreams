import requests
import json
import os
from typing import List, Dict, Optional
from app import db
from flask_login import current_user
from app.models import PromptConfig

class OpenAIAssistant:
    """AI assistant using OpenAI API for screenplay suggestions"""
    
    def __init__(self):
        self.api_key = os.environ.get('OPENAI_API_KEY')
        self.model = os.environ.get('OPENAI_MODEL', 'gpt-3.5-turbo')
        self.base_url = os.environ.get('OPENAI_BASE_URL', 'https://api.openai.com/v1')
        self.timeout = int(os.environ.get('AI_TIMEOUT', '300'))
    
    def is_available(self) -> bool:
        """Check if OpenAI API is available"""
        return bool(self.api_key)
    
    def check_model(self) -> bool:
        """Check if the model is available (OpenAI models are always available if key exists)"""
        return self.is_available()
    
    def generate(self, prompt: str, context: str = "") -> str:
        """Generate text using OpenAI"""
        if not self.api_key:
            return "OpenAI API key not configured"
        
        try:
            full_prompt = f"{context}\n\n{prompt}" if context else prompt
            
            response = requests.post(
                f"{self.base_url}/chat/completions",
                json={
                    "model": self.model,
                    "messages": [{"role": "user", "content": full_prompt}],
                    "max_tokens": 1000
                },
                headers={
                    'Authorization': f'Bearer {self.api_key}',
                    'Content-Type': 'application/json'
                },
                timeout=self.timeout
            )
            
            if response.status_code == 200:
                return response.json()['choices'][0]['message']['content']
            return f"OpenAI API Error: HTTP {response.status_code} - {response.text}"
        except Exception as e:
            print(f"OpenAI generation failed: {e}")
            if "timed out" in str(e).lower():
                return "AI assistant timed out. Please try again."
            elif "connection" in str(e).lower():
                return "Cannot connect to OpenAI API. Please check your internet connection."
            else:
                return f"OpenAI API error: {str(e)}"

class AnthropicAssistant:
    """AI assistant using Anthropic Claude API for screenplay suggestions"""
    
    def __init__(self):
        self.api_key = os.environ.get('ANTHROPIC_API_KEY')
        self.model = os.environ.get('ANTHROPIC_MODEL', 'claude-3-sonnet-20240229')
        self.base_url = os.environ.get('ANTHROPIC_BASE_URL', 'https://api.anthropic.com/v1')
        self.timeout = int(os.environ.get('AI_TIMEOUT', '300'))
    
    def is_available(self) -> bool:
        """Check if Anthropic API is available"""
        return bool(self.api_key)
    
    def check_model(self) -> bool:
        """Check if the model is available (Anthropic models are always available if key exists)"""
        return self.is_available()
    
    def generate(self, prompt: str, context: str = "") -> str:
        """Generate text using Anthropic Claude"""
        if not self.api_key:
            return "Anthropic API key not configured"
        
        try:
            full_prompt = f"{context}\n\n{prompt}" if context else prompt
            
            response = requests.post(
                f"{self.base_url}/messages",
                json={
                    "model": self.model,
                    "max_tokens": 1000,
                    "messages": [{"role": "user", "content": full_prompt}]
                },
                headers={
                    'x-api-key': self.api_key,
                    'Content-Type': 'application/json',
                    'anthropic-version': '2023-06-01'
                },
                timeout=self.timeout
            )
            
            if response.status_code == 200:
                return response.json()['content'][0]['text']
            return f"Anthropic API Error: HTTP {response.status_code} - {response.text}"
        except Exception as e:
            print(f"Anthropic generation failed: {e}")
            if "timed out" in str(e).lower():
                return "AI assistant timed out. Please try again."
            elif "connection" in str(e).lower():
                return "Cannot connect to Anthropic API. Please check your internet connection."
            else:
                return f"Anthropic API error: {str(e)}"

class OllamaAssistant:
    """AI assistant using Ollama for screenplay suggestions"""
    
    def __init__(self, base_url: str = "http://localhost:11434"):
        # Support both HTTP and HTTPS
        if not base_url.startswith(('http://', 'https://')):
            if os.environ.get('FORCE_HTTPS', 'False').lower() == 'true':
                base_url = f"https://{base_url}"
            else:
                base_url = f"http://{base_url}"
        
        self.base_url = os.environ.get('OLLAMA_BASE_URL', base_url)
        self.model = os.environ.get('OLLAMA_MODEL', 'llama2')
        self.timeout = int(os.environ.get('OLLAMA_TIMEOUT', '300'))
        self.check_timeout = int(os.environ.get('OLLAMA_CHECK_TIMEOUT', '5'))
        self.api_key = os.environ.get('OLLAMA_API_KEY', None)
        self.verify_ssl = os.environ.get('OLLAMA_VERIFY_SSL', 'true').lower() == 'true'
    
    def _get_headers(self) -> Dict[str, str]:
        """Get headers for requests"""
        headers = {'Content-Type': 'application/json'}
        if self.api_key:
            headers['Authorization'] = f'Bearer {self.api_key}'
        return headers
    
    def is_available(self) -> bool:
        """Check if Ollama is running"""
        try:
            response = requests.get(
                f"{self.base_url}/api/tags", 
                timeout=self.check_timeout,
                headers=self._get_headers(),
                verify=self.verify_ssl
            )
            return response.status_code == 200
        except Exception as e:
            print(f"Ollama availability check failed: {e}")
            return False
    
    def check_model(self) -> bool:
        """Check if the specific model is available"""
        try:
            response = requests.get(
                f"{self.base_url}/api/tags", 
                timeout=self.check_timeout,
                headers=self._get_headers(),
                verify=self.verify_ssl
            )
            if response.status_code == 200:
                models = response.json().get('models', [])
                return any(model.get('name', '').startswith(self.model) for model in models)
            return False
        except Exception as e:
            print(f"Ollama model check failed: {e}")
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
                timeout=self.timeout,
                headers=self._get_headers(),
                verify=self.verify_ssl
            )
            
            if response.status_code == 200:
                return response.json().get('response', '')
            return f"Error: HTTP {response.status_code}"
        except Exception as e:
            print(f"Ollama generation failed: {e}")
            if "timed out" in str(e).lower():
                return "AI assistant timed out. Please ensure Ollama is running and try again."
            elif "connection" in str(e).lower():
                return "Cannot connect to Ollama. Please check the server configuration."
            else:
                return f"AI assistant error: {str(e)}"
    
    def get_user_prompt_config(self) -> PromptConfig:
        """Get or create user prompt configuration"""
        if not current_user or not current_user.is_authenticated:
            # Return default config for non-authenticated users
            default_config = PromptConfig()
            default_config.max_characters = 2000
            return default_config
        
        config = PromptConfig.query.filter_by(user_id=current_user.id).first()
        if not config:
            config = PromptConfig(user_id=current_user.id, max_characters=2000)
            db.session.add(config)
            db.session.commit()
        return config
    
    def suggest_character_arc(self, character_name: str, character_description: str, screenplay_context: str) -> str:
        """Suggest character arc development"""
        config = self.get_user_prompt_config()
        max_chars = config.max_characters
        
        # Use custom prompt if available, otherwise default
        if config.character_arc_prompt:
            custom_prompt = config.character_arc_prompt
            context = screenplay_context[:max_chars] if screenplay_context else ""
            prompt = custom_prompt.format(
                character_name=character_name,
                character_description=character_description,
                context=context
            )
        else:
            # Default prompt with configurable context limit
            context = screenplay_context[:max_chars] if screenplay_context else ""
            
            prompt = f"""You are a professional screenplay consultant. Analyze the following character and suggest a compelling character arc.

Character: {character_name}
Description: {character_description}

Context from screenplay:
{context}

Provide a brief character arc suggestion (3-5 sentences) focusing on:
1. Character's starting point
2. Key transformation
3. Final state

Make the suggestion specific to the character and the story context. Consider:
- The character's personality traits
- Their current situation in the story
- Potential conflicts they might face
- How they can grow or change

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

Format your response as a JSON array of objects with 'line', 'error', and 'suggestion' fields.
If no errors are found, return an empty array.

Response:"""
        
        try:
            response = self.generate(prompt)
            # Try to parse as JSON, fallback to empty list
            try:
                return json.loads(response)
            except:
                return []
        except:
            return []
    
    def get_common_locations(self, partial_text: str = "") -> List[str]:
        """Get common screenplay locations"""
        common_locations = [
            "INT. COFFEE SHOP - DAY",
            "INT. APARTMENT - NIGHT", 
            "EXT. CITY STREET - DAY",
            "INT. OFFICE - DAY",
            "EXT. PARK - DAY",
            "INT. RESTAURANT - NIGHT",
            "EXT. BEACH - SUNSET",
            "INT. CAR - DAY",
            "INT. HOSPITAL ROOM - DAY",
            "EXT. FOREST - DAY"
        ]
        
        if not partial_text:
            return common_locations[:5]
        
        matches = [loc for loc in common_locations if partial_text.upper() in loc]
        return matches[:5]

class AIAssistant:
    """Multi-provider AI assistant for screenplay suggestions"""
    
    def __init__(self):
        self.provider = os.environ.get('AI_PROVIDER', 'ollama').lower()
        
        # Initialize the appropriate provider
        if self.provider == 'openai':
            self.assistant = OpenAIAssistant()
        elif self.provider == 'anthropic':
            self.assistant = AnthropicAssistant()
        else:
            self.assistant = OllamaAssistant()
    
    def is_available(self) -> bool:
        """Check if the configured AI provider is available"""
        return self.assistant.is_available()
    
    def check_model(self) -> bool:
        """Check if the model is available"""
        if hasattr(self.assistant, 'check_model'):
            return self.assistant.check_model()
        return self.is_available()
    
    def generate(self, prompt: str, context: str = "") -> str:
        """Generate text using the configured provider"""
        return self.assistant.generate(prompt, context)
    
    def get_user_prompt_config(self) -> PromptConfig:
        """Get or create user prompt configuration"""
        if not current_user or not current_user.is_authenticated:
            # Return default config for non-authenticated users
            default_config = PromptConfig()
            default_config.max_characters = 2000
            return default_config
        
        config = PromptConfig.query.filter_by(user_id=current_user.id).first()
        if not config:
            config = PromptConfig(user_id=current_user.id, max_characters=2000)
            db.session.add(config)
            db.session.commit()
        return config
    
    def suggest_character_arc(self, character_name: str, character_description: str, screenplay_context: str) -> str:
        """Suggest character arc development"""
        config = self.get_user_prompt_config()
        max_chars = config.max_characters
        
        # Use custom prompt if available, otherwise default
        if config.character_arc_prompt:
            custom_prompt = config.character_arc_prompt
            context = screenplay_context[:max_chars] if screenplay_context else ""
            prompt = custom_prompt.format(
                character_name=character_name,
                character_description=character_description,
                context=context
            )
        else:
            # Default prompt with configurable context limit
            context = screenplay_context[:max_chars] if screenplay_context else ""
            
            prompt = f"""You are a professional screenplay consultant. Analyze the following character and suggest a compelling character arc.

Character: {character_name}
Description: {character_description}

Context from screenplay:
{context}

Provide a brief character arc suggestion (3-5 sentences) focusing on:
1. Character's starting point
2. Key transformation
3. Final state

Make the suggestion specific to the character and the story context. Consider:
- The character's personality traits
- Their current situation in the story
- Potential conflicts they might face
- How they can grow or change

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
        # or more sophisticated prompting
        prompt = f"""Check the following text for spelling and grammar errors. List any errors found.

Text: {text}

Format your response as a JSON array of objects with 'line', 'error', and 'suggestion' fields.
If no errors are found, return an empty array.

Response:"""
        
        try:
            response = self.generate(prompt)
            # Try to parse as JSON, fallback to empty list
            try:
                return json.loads(response)
            except:
                return []
        except:
            return []
    
    def get_common_locations(self, partial_text: str = "") -> List[str]:
        """Get common screenplay locations"""
        common_locations = [
            "INT. COFFEE SHOP - DAY",
            "INT. APARTMENT - NIGHT", 
            "EXT. CITY STREET - DAY",
            "INT. OFFICE - DAY",
            "EXT. PARK - DAY",
            "INT. RESTAURANT - NIGHT",
            "EXT. BEACH - SUNSET",
            "INT. CAR - DAY",
            "INT. HOSPITAL ROOM - DAY",
            "EXT. FOREST - DAY"
        ]
        
        if not partial_text:
            return common_locations[:5]
        
        matches = [loc for loc in common_locations if partial_text.upper() in loc]
        return matches[:5]
