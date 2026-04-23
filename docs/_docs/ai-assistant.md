---
layout: docs
title: AI Assistant
description: Set up and use AI-powered writing assistance
---

# AI Assistant Setup

Learn how to configure and use AI-powered writing assistance in Screen Dreams.

## What Can AI Assistant Do?

The AI Assistant can help you with:

- **Character Development** - Generate character backstories, motivations, and relationships
- **Plot & Story** - Generate plot ideas, story structure, and narrative suggestions
- **Dialogue Help** - Improve dialogue flow and character voice consistency
- **Scene Ideas** - Get suggestions for scene settings and transitions

## AI Provider Setup

Choose from multiple AI providers based on your needs:

| Provider | Privacy | Cost | Setup | Quality |
|---------|---------|------|-------|--------|
| Ollama | 100% Private | Free | Medium | Good |
| OpenAI | Cloud-based | Pay-per-use | Easy | Excellent |
| Anthropic | Cloud-based | Pay-per-use | Easy | Excellent |

## Ollama Setup (Recommended for Privacy)

Ollama runs AI models locally on your machine for complete privacy.

### Step 1: Install Ollama

```bash
# Linux/macOS
curl -fsSL https://ollama.ai/install.sh | sh

# Windows
# Download from https://ollama.ai/download
```

### Step 2: Start Ollama

```bash
# Start the Ollama service
ollama serve
```

### Step 3: Download a Model

```bash
# Small and fast (good for testing)
ollama pull tinyllama

# Better quality
ollama pull llama2

# Latest model
ollama pull codellama
```

### Step 4: Configure Screen Dreams

```bash
# Run with Ollama
uvx --env AI_PROVIDER=ollama git+https://github.com/opensourcemechanic/screen-dreams.git
```

<div class="alert alert-info">
  <i class="fas fa-info-circle me-2"></i>
  <strong>Tip:</strong> Start with <code>tinyllama</code> for testing. It's fast and uses less memory.
</div>

## OpenAI Setup

Use OpenAI's powerful models for the best AI assistance quality.

### Step 1: Get API Key

1. Visit [OpenAI Platform](https://platform.openai.com)
2. Sign up or log in
3. Go to API Keys section
4. Create a new API key
5. Copy the key (keep it secure!)

### Step 2: Configure Screen Dreams

```bash
# Set your API key
export OPENAI_API_KEY="your-api-key-here"

# Run with OpenAI
uvx --env AI_PROVIDER=openai --env OPENAI_API_KEY=$OPENAI_API_KEY git+https://github.com/opensourcemechanic/screen-dreams.git
```

<div class="alert alert-warning">
  <i class="fas fa-exclamation-triangle me-2"></i>
  <strong>Important:</strong> Never share your API key or commit it to version control.
</div>

## Anthropic Claude Setup

Use Anthropic's Claude models for high-quality AI assistance.

### Step 1: Get API Key

1. Visit [Anthropic Console](https://console.anthropic.com)
2. Sign up or log in
3. Go to API Keys section
4. Create a new API key
5. Copy the key (keep it secure!)

### Step 2: Configure Screen Dreams

```bash
# Set your API key
export ANTHROPIC_API_KEY="your-api-key-here"

# Run with Anthropic
uvx --env AI_PROVIDER=anthropic --env ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY git+https://github.com/opensourcemechanic/screen-dreams.git
```

## Using AI Assistant

Once configured, use the AI Assistant in the Screen Dreams interface:

### Step 1: Open AI Panel
In the screenplay editor, click the "AI Assistant" button or press `Ctrl+G`.

### Step 2: Choose Assistance Type
Select from:
- **Character Arc** - Get help with character development
- **Plot Development** - Generate plot ideas and story structure
- **Dialogue Improvement** - Enhance dialogue quality

### Step 3: Provide Context
Enter your current scene, character information, or specific questions about your screenplay.

### Step 4: Get Suggestions
The AI will provide context-aware suggestions that you can accept, modify, or reject.

## AI Features in Detail

### Character Development

The AI can help with:

- **Character Backstories** - Generate detailed character histories
- **Motivations** - Suggest character goals and internal conflicts
- **Relationships** - Define character dynamics and connections
- **Character Arcs** - Plan character development through the story

### Plot Development

Get assistance with:

- **Story Structure** - Three-act structure, pacing, and flow
- **Plot Points** - Key story moments and turning points
- **Subplots** - Secondary storylines and themes
- **Conflict** - Sources of tension and resolution

### Dialogue Enhancement

Improve your dialogue with:

- **Character Voice** - Consistent speech patterns and personality
- **Natural Flow** - Realistic conversation patterns
- **Subtext** - Hidden meanings and implications
- **Pacing** - Rhythm and timing of dialogue

## Best Practices

### Be Specific
Provide detailed context about your characters, scene, and story for better suggestions.

### Iterate and Refine
Use AI suggestions as inspiration. Modify and refine them to match your vision.

### Maintain Consistency
Keep character voices and story themes consistent throughout your screenplay.

### Privacy Considerations
Use Ollama for complete privacy, or be mindful of data sent to cloud AI services.

## Troubleshooting

### "AI Assistant not available"
**Solution:** Check your AI provider configuration and ensure the service is running.

### "Slow AI responses"
**Solution:** For Ollama, try a smaller model. For cloud services, check your internet connection.

### "Poor quality suggestions"
**Solution:** Provide more context and be more specific in your requests.

### "API key errors"
**Solution:** Verify your API key is correct and has sufficient credits.

## Advanced Configuration

### Custom Prompts
You can customize AI prompts for specific use cases:

```bash
# Custom prompt for character development
export AI_CHARACTER_PROMPT="Generate detailed character development suggestions focusing on motivations and internal conflicts"
```

### Model Selection
Choose specific models for different tasks:

```bash
# Use specific models
uvx --env AI_PROVIDER=ollama --env OLLAMA_MODEL=llama2 git+https://github.com/opensourcemechanic/screen-dreams.git
```

### Temperature Settings
Adjust AI creativity level:

```bash
# Lower temperature for more focused responses
uvx --env AI_TEMPERATURE=0.7 git+https://github.com/opensourcemechanic/screen-dreams.git
```

## Privacy and Security

### Data Privacy
- **Ollama**: 100% private - all processing happens on your machine
- **OpenAI/Anthropic**: Data sent to cloud services - check their privacy policies

### API Key Security
- Never commit API keys to version control
- Use environment variables for sensitive data
- Regularly rotate your API keys

### Content Filtering
All AI providers have content filtering and safety measures in place.

## Cost Management

### Free Options
- **Ollama**: Completely free after initial setup
- **Free Tiers**: OpenAI and Anthropic offer free credits for new users

### Pay-per-Use
- **OpenAI**: ~$0.002 per 1K tokens
- **Anthropic**: ~$0.003 per 1K tokens
- **Usage**: Typical screenplay assistance uses < 1K tokens per request

### Budget Monitoring
Set up usage alerts and limits in your AI provider dashboards.

---

Ready to set up AI assistance? [Get Started with AI]({{ '/docs/getting-started/' | relative_url }}#ai-setup)
