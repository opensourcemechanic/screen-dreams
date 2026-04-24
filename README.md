# <span style="color: #ff3366;">Screen Dreams</span>

A  Python-based screenplay editor with Fountain format support, professional PDF output, backup management and AI support.

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

### `start.sh` — Universal Launcher

The `start.sh` script auto-detects your environment and starts the server using the best available runtime:

| Runtime | Used when |
|---|---|
| **uvx** (recommended) | `uvx` is installed — dev mode uses Flask, prod mode uses gunicorn |
| **Podman** | `uvx` not found — maps `$PORT` on the host to port 5000 in the container |
| **gunicorn** | Podman not found but `gunicorn` is installed |
| **Python** | Last resort — creates `.venv`, installs dependencies, runs directly |

```bash
# Production mode on port 5000 (default)
./start.sh

# Development mode with auto-reload on port 5000
./start.sh dev

# Production mode on a custom port
PORT=8080 ./start.sh

# One-command via uvx (production, port 5000)
uvx git+https://github.com/opensourcemechanic/screen-dreams.git

# One-command via uvx on custom port
PORT=9000 uvx git+https://github.com/opensourcemechanic/screen-dreams.git screen-dreams-prod
```

### Persistent Data Storage

All user accounts, screenplays, and uploads are stored in a **single persistent directory** that survives across `uvx` re-runs, upgrades, and restarts:

| Platform | Default location |
|---|---|
| Linux / macOS | `~/.local/share/screen-dreams/` |
| Override | Set `DATA_DIR=/your/path` |

```bash
# Use default location (~/.local/share/screen-dreams)
uvx git+https://github.com/opensourcemechanic/screen-dreams.git

# Use a custom location (e.g. a shared drive or Docker volume)
DATA_DIR=/mnt/data/screen-dreams uvx git+https://github.com/opensourcemechanic/screen-dreams.git screen-dreams-prod
```

The startup banner always prints the active data directory so you can confirm where data is being stored.

### `stop.sh` — Universal Stopper

Stops all running Screen Dreams instances regardless of how they were started:

```bash
./stop.sh
```

Handles all deployment modes:
- uvx / screen-dreams entry point processes
- gunicorn workers
- Flask dev server (`run_dev.py`, `run.py`)
- Podman containers (by image or name)
- Docker containers (by image or name)
- Docker Compose services

### Access the Application
1. Open your browser to `http://localhost:5000` (default) or `http://localhost:<PORT>` if you set a custom port
2. Login with the demo account:
   - Email: `demo@example.com`
   - Password: `demo123`
3. Create your first screenplay!

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

Screen Dreams is licensed under a **Modified MIT License** with commercial use provisions.

### Quick Summary
- **Free for**: Individual users, non-commercial use, education, open source projects
- **Commercial license required**: When SaaS income exceeds $1000/month (standalone or bundled)
- **Full license**: See [LICENSE.md](LICENSE.md) for complete terms

### Commercial Use
Commercial licensing required for any individual or company whose total screen-dreams Software as a Service (SaaS) income exceeds $1000/month, regardless of whether screen-dreams is a stand-alone web application or part of a SaaS bundle.

For commercial licensing inquiries, please contact the project maintainer through the GitHub repository.

---

*See [LICENSE.md](LICENSE.md) for the complete license text.*
