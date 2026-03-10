# Screenplay Editor

A simplified Python-based screenplay editor with Fountain format support and professional PDF output.

## Features

- **Plain Text Editing**: Write screenplays using industry-standard Fountain format
- **PDF Export**: Generate professional PDFs with Courier font and proper formatting
- **Character Management**: Track characters, descriptions, and character arcs
- **Scene Organization**: Automatic scene parsing and organization
- **AI Assistant**: Ollama integration for character arc and plot suggestions
- **Auto-save**: Automatic saving every 3 seconds
- **Industry Standard**: Follows screenplay formatting conventions

## Installation

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. (Optional) Install Ollama for AI features:
- Download from https://ollama.ai
- Run: `ollama pull llama2`

## Running the Application

```bash
python run.py
```

The application will be available at http://localhost:5000

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
