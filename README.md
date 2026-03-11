# Screen Dreams Screenwriter

A simplified Python-based screenplay editor with Fountain format support, professional PDF output, and enhanced backup management.

## Features

- **Plain Text Editing**: Write screenplays using industry-standard Fountain format
- **PDF Export**: Generate professional PDFs with Courier font and proper formatting
- **Character Management**: Track characters, descriptions, and character arcs
- **Scene Organization**: Automatic scene parsing and organization
- **AI Assistant**: Ollama integration for character arc and plot suggestions
- **Auto-save**: Automatic saving every 15 seconds (configurable)
- **Industry Standard**: Follows screenplay formatting conventions

## Installation

### Option 1: Using uv (Recommended - Fast & Modern)

For modern, fast dependency management:

```bash
# Install uv (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Clone and setup
git clone https://github.com/opensourcemechanic/awen-screenplay-editor.git
cd awen-screenplay-editor
# Note: The app is branded as "Screen Dreams Screenwriter" inside

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
git clone https://github.com/opensourcemechanic/awen-screenplay-editor.git
cd awen-screenplay-editor
# Note: The app is branded as "Screen Dreams Screenwriter" inside

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
screenwriter/
├── app/
│   ├── __init__.py          # Flask app initialization
│   ├── models.py            # Database models
│   ├── routes.py            # API routes
│   ├── screenplay.py        # Fountain parser
│   ├── pdf_generator.py     # PDF generation with ReportLab
│   └── ai_assistant.py      # Ollama AI integration
├── templates/               # HTML templates
├── static/                  # CSS and JavaScript
├── screenplays/            # Saved screenplay files
├── requirements.txt        # Python dependencies
└── run.py                  # Application entry point
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

## License

MIT License
