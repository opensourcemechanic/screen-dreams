# Awen Screenplay Editor

A simplified Python-based screenplay editor with Fountain format support and professional PDF output.

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

1. Start the application:
```bash
python3 run.py
```

2. Open your browser to `http://localhost:5000`

3. Login with the demo account:
   - Email: `demo@example.com`
   - Password: `demo123`

4. Create your first screenplay!

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
