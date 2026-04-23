---
layout: docs
title: Getting Started
description: Deploy Screen Dreams in seconds with UVX
show_downloads: true
---

# Getting Started

Welcome to Screen Dreams! This guide will help you get up and running in minutes.

## Quick Start with UVX

The fastest way to get Screen Dreams running is with UVX - a modern Python application runner.

<div class="alert alert-info">
  <i class="fas fa-info-circle me-2"></i>
  <strong>UVX handles everything automatically:</strong> downloads the code, creates a virtual environment, installs dependencies, and starts the application.
</div>

### Step 1: Install UV (one-time setup)

Install UV, the modern Python package manager:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Restart your terminal after installation.

### Step 2: Deploy Screen Dreams

Run this single command to deploy Screen Dreams:

```bash
uvx git+https://github.com/opensourcemechanic/screen-dreams.git
```

UVX will automatically:
- Download the latest code from GitHub
- Create an isolated virtual environment
- Install all required dependencies
- Start the application

### Step 3: Open Your Browser

Screen Dreams is now running locally at:

```
http://localhost:5000
```

Open this URL in your web browser to start using Screen Dreams!

![Screen Dreams Interface]({{ '/assets/images/app-homepage.png' | relative_url }})

## Installation Options

While UVX is recommended, here are other installation methods:

### Traditional Installation

For developers who want to modify the source code:

```bash
# Clone the repository
git clone https://github.com/opensourcemechanic/screen-dreams.git
cd screen-dreams

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# or venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Run the application
python run_dev.py
```

### Docker/Podman

For containerized deployment:

```bash
# Using Podman (recommended)
podman run -d --name screen-dreams \
  -p 5000:5000 \
  -v $(pwd)/data:/app/data \
  screen-dreams:latest

# Using Docker
docker run -d --name screen-dreams \
  -p 5000:5000 \
  -v $(pwd)/data:/app/data \
  screen-dreams:latest
```

## Your First Project

Let's create your first screenplay project:

### Create an Account

When you first open Screen Dreams, you'll need to create an account:
- Click "Sign Up" in the top right
- Enter your email and choose a password
- Click "Create Account"

### Create Your First Screenplay

Once logged in, create your first project:
- Click the "+ New Screenplay" button
- Enter a title (e.g., "My First Screenplay")
- Click "Create"

### Start Writing

You're now in the screenplay editor! Here's what you can do:
- Write using Fountain format (industry standard)
- Add characters and track their development
- Organize scenes automatically
- Export to PDF when ready

![Editor Interface]({{ '/assets/images/editor-interface.png' | relative_url }})

## AI Assistant Setup (Optional)

Screen Dreams includes AI-powered writing assistance. Here's how to set it up:

### Ollama Setup (Recommended)

1. **Install Ollama**
   ```bash
   curl -fsSL https://ollama.ai/install.sh | sh
   ```

2. **Start Ollama**
   ```bash
   ollama serve
   ```

3. **Pull a Model**
   ```bash
   ollama pull tinyllama  # Small and fast
   # or
   ollama pull llama2     # Better quality
   ```

4. **Run Screen Dreams with AI**
   ```bash
   uvx --env AI_PROVIDER=ollama git+https://github.com/opensourcemechanic/screen-dreams.git
   ```

### OpenAI Setup

1. **Get API Key** from [OpenAI Platform](https://platform.openai.com)
2. **Run with OpenAI**
   ```bash
   export OPENAI_API_KEY="your-api-key"
   uvx --env AI_PROVIDER=openai --env OPENAI_API_KEY=$OPENAI_API_KEY git+https://github.com/opensourcemechanic/screen-dreams.git
   ```

### Anthropic Setup

1. **Get API Key** from [Anthropic Console](https://console.anthropic.com)
2. **Run with Claude**
   ```bash
   export ANTHROPIC_API_KEY="your-api-key"
   uvx --env AI_PROVIDER=anthropic --env ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY git+https://github.com/opensourcemechanic/screen-dreams.git
   ```

## Mobile Setup

Screen Dreams works great on mobile devices! Here's what you need to know:

<div class="alert alert-warning">
  <i class="fas fa-mobile-alt me-2"></i>
  <strong>Important:</strong> For the best experience, use your phone in horizontal (landscape) orientation.
</div>

### Mobile Browser Support
- ✅ Chrome Mobile (Android) - Recommended
- ✅ Safari Mobile (iOS)
- ✅ Firefox Mobile
- ✅ Edge Mobile

### Recommended Mobile Workflow
1. Rotate phone to horizontal orientation
2. Use desktop view if available in browser settings
3. Enable auto-rotation for best experience
4. Consider using tablet for extended writing sessions

![Mobile Horizontal View]({{ '/assets/images/mobile-horizontal.png' | relative_url }})

## Troubleshooting

Having issues? Here are common problems and solutions:

### "command not found: uvx"
**Solution:** Install UV first:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```
Then restart your terminal and try again.

### "Port already in use"
**Solution:** Use a different port:
```bash
uvx git+https://github.com/opensourcemechanic/screen-dreams.git -- --port=8080
```

### "Python version not supported"
**Solution:** Use a specific Python version:
```bash
uvx --python 3.11 git+https://github.com/opensourcemechanic/screen-dreams.git
```

### "AI features not working"
**Solution:** Check your AI provider configuration:
```bash
# For Ollama
uvx --env AI_PROVIDER=ollama git+https://github.com/opensourcemechanic/screen-dreams.git

# For OpenAI
uvx --env AI_PROVIDER=openai --env OPENAI_API_KEY=your-key git+https://github.com/opensourcemechanic/screen-dreams.git
```

## Next Steps

Congratulations! You now have Screen Dreams running. Here's what to explore next:

- [Features Overview]({{ '/docs/features/' | relative_url }}) - Discover all the powerful features
- [AI Assistant Setup]({{ '/docs/ai-assistant/' | relative_url }}) - Configure AI writing assistance
- [Mobile Guide]({{ '/docs/mobile/' | relative_url }}) - Best practices for mobile usage

<div class="alert alert-success mt-4">
  <i class="fas fa-check-circle me-2"></i>
  <strong>You're all set!</strong> Screen Dreams is ready to help you write your next screenplay. If you need help, check out our detailed documentation or visit our GitHub repository.
</div>
