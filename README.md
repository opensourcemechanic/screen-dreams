# <span style="color: #ff3366;">Screen Dreams</span>

A simplified Python-based screenplay editor with Fountain format support, professional PDF output, and enhanced backup management.

## Features

- **Plain Text Editing**: Write screenplays using industry-standard Fountain format
- **PDF Export**: Generate professional PDFs with Courier font and proper formatting
- **Character Management**: Track characters, descriptions, and character arcs
- **Scene Organization**: Automatic scene parsing and organization
- **AI Assistant**: Ollama integration for character arc and plot suggestions
- **Auto-save**: Automatic saving every 15 seconds (configurable)
- **Industry Standard**: Follows screenplay formatting conventions
- **Enhanced Theming**: 5 themes including evening (dark blue) and night (dark grey)
- **Mobile Responsive**: Optimized for mobile devices with touch-friendly controls

## Mobile Compatibility

**⚠️ IMPORTANT: Horizontal Orientation Required**

**For the best experience, please use your phone in horizontal (landscape) orientation.**

The application is designed primarily for desktop and horizontal mobile use. While some features work in vertical orientation, the editor and screenplay management interfaces are optimized for horizontal viewing.

### What Works Best in Horizontal Mode:
- ✅ **Editor**: Full screenplay text with syntax guide visible
- ✅ **Screenplay Cards**: Proper button layout and spacing
- ✅ **Scene Content**: Optimal scrolling and readability
- ✅ **AI Panel**: Full functionality with prompt editing

### Vertical Mode Limitations:
- ⚠️ **Editor**: Syntax guide moves below text area (reduced functionality)
- ⚠️ **Screenplay Cards**: Buttons stack vertically (less convenient)
- ⚠️ **Scene Content**: Reduced scrolling height
- ⚠️ **General Layout**: More scrolling required

### Mobile Browser Support
- Chrome Mobile (Android) - Recommended
- Safari Mobile (iOS)
- Firefox Mobile
- Edge Mobile

### Recommended Mobile Workflow:
1. **Rotate phone to horizontal orientation**
2. **Use desktop view if available** in browser settings
3. **Enable auto-rotation** for best experience
4. **Consider using tablet** for extended writing sessions

## Quick Start (Easiest Method)

### **One-Command Local Deployment with UVX** 

Deploy Screen Dreams instantly on your computer with a single command:

```bash
# Install UV (one-time setup)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Deploy Screen Dreams instantly
uvx git+https://github.com/opensourcemechanic/screen-dreams.git

# Open your browser to http://localhost:5000
```

**That's it!** Screen Dreams is now running locally on your machine with:
- Complete web interface
- Local data storage (all files saved on your computer)
- AI features (if configured)
- Privacy (no data leaves your machine)

For detailed UVX instructions, see [UVX Quick Start](UVX-QUICK-START.md).

---

## Installation

### Option 1: Using uv (Recommended - Fast & Modern)

For modern, fast dependency management:

```bash
# Install uv (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Clone and setup
git clone https://github.com/opensourcemechanic/screen-dreams.git
cd screen-dreams

# Create virtual environment and install dependencies
uv venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
uv pip install -e .

# Configure environment
cp .env.example .env
# Edit .env with your settings (SECRET_KEY is required)
```

### Option 2: Using Python venv (Standard)

Traditional setup using Python's built-in virtual environment:

```bash
# Clone and setup
git clone https://github.com/opensourcemechanic/screen-dreams.git
cd screen-dreams

# Create virtual environment
python3 -m venv .venv

# Activate environment
# Linux/macOS:
source .venv/bin/activate
# Windows:
.venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your settings (SECRET_KEY is required)
```

See [SETUP.md](SETUP.md) for detailed setup instructions and troubleshooting.

## Optional: AI Features Setup

For AI assistant features, install Ollama:

```bash
# Install Ollama (https://ollama.ai)
curl -fsSL https://ollama.ai/install.sh | sh

# Pull a model
ollama pull llama2

# Start Ollama
ollama run llama2
```

## Quick Start

### Production Mode (Default - Debug Disabled)
```bash
# Start the application (debug disabled for better performance)
python3 run.py

# Or use the quick start script
./start.sh prod
```

### Development Mode (Debug Enabled)
```bash
# For active development with debugging
python3 run_dev.py

# Or use the quick start script
./start.sh dev

# Or enable debug via environment variable
export FLASK_DEBUG=True
python3 run.py
```

### Access the Application
1. Open your browser to `http://localhost:5000`
2. Login with the demo account:
   - Email: `demo@example.com`
   - Password: `demo123`
3. Create your first screenplay!

### Debug Mode Features
When debug mode is enabled (`FLASK_DEBUG=True`):
- **Auto-reload**: Server restarts when code changes
- **Interactive debugger**: Detailed error pages with console
- **Performance impact**: ~50% slower response times
- **Use for**: Active development and debugging

### Performance Mode
When debug mode is disabled (default):
- **Better performance**: ~2x faster response times
- **Lower memory usage**
- **Use for**: Testing, demos, and production-like scenarios

## Fountain Format Quick Reference

### Scene Heading
```
INT. COFFEE SHOP - DAY
```

### Character and Dialogue
```
JOHN
(nervous)
Is anyone here?
```

### Action
```
John enters and looks around nervously.
```

### Transition
```
FADE OUT.
```

## Project Structure

```
screen-dreams/
├── app/
│   ├── __init__.py          # Flask app initialization
│   ├── models.py            # Database models
│   ├── routes.py            # API routes
│   ├── screenplay.py        # Fountain parser
│   ├── pdf_generator.py     # PDF generation with ReportLab
│   ├── ai_assistant.py      # Ollama AI integration
│   ├── templates/           # HTML templates (canonical)
│   └── static/              # CSS and JavaScript (canonical)
├── screenplays/             # Saved screenplay files
├── requirements.txt         # Python dependencies
└── pyproject.toml           # Package configuration
```

## API Endpoints

- `GET /api/screenplays` - List all screenplays
- `POST /api/screenplays` - Create new screenplay
- `GET /api/screenplay/<id>` - Get screenplay
- `PUT /api/screenplay/<id>` - Update screenplay
- `DELETE /api/screenplay/<id>` - Delete screenplay
- `GET /api/screenplay/<id>/pdf` - Generate PDF
- `POST /api/screenplay/<id>/parse` - Parse scenes and characters
- `GET /api/characters/<screenplay_id>` - List characters
- `POST /api/ai/character-arc` - Get AI character arc suggestion
- `POST /api/ai/plot-development` - Get AI plot suggestion

## PDF Output

PDFs are generated with:
- **Font**: Courier 12pt (industry standard)
- **Margins**: 1.5" left, 1" right, 1" top/bottom
- **Page Numbers**: Top right corner
- **Proper Element Formatting**: Scene headings, character names, dialogue, etc.

## AI Features (Requires Ollama)

- Character arc suggestions
- Plot development recommendations
- Dialogue enhancement
- Auto-completion for character names

## Author & Architect

**Brian Nitz** - Architect and AI Coordinator

Brian Nitz is the lead architect and AI coordinator for Screen Dreams, overseeing the technical design and AI integration aspects of the project.

## License

Modified MIT License - Commercial Use Provisions

This software is licensed under a modified MIT license with the following provisions:

### Free Use
- **Individual Users**: Free to use, modify, and distribute
- **Small Businesses**: Free to deploy and use for services generating up to $500/month in SaaS revenue
- **Educational Use**: Free for educational and non-profit purposes

### Commercial Licensing
- **Revenue Threshold**: If your total SaaS revenue for this product exceeds $500/month, please contact the author about large scale licensing
- **Enterprise Use**: Commercial licensing available for larger deployments
- **Redistribution**: Must include this license and copyright notice

### Contact for Licensing
For large scale commercial licensing inquiries, please contact the project maintainer through the GitHub repository.

---

**Standard MIT License terms apply below:**

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
