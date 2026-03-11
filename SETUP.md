# Development Setup

This guide explains how to set up the Screen Dreams Screenwriter using virtual environments for clean, reproducible development.

## Prerequisites

1. **Python 3.8+** required

## Option 1: Using uv (Recommended - Fast & Modern)

### Install uv
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```
Or follow the official uv installation guide: https://docs.astral.sh/uv/getting-started/installation/

### Quick Setup with uv
```bash
# Clone the repository
git clone https://github.com/opensourcemechanic/screen-dreams.git
cd screen-dreams

# Create virtual environment and install dependencies
uv venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install project dependencies
uv pip install -e .
```

**Benefits of uv:**
- 10-100x faster than pip
- Deterministic dependency resolution
- Modern pyproject.toml support
- Cross-platform compatibility

---

## Option 2: Using Python Built-in venv (Standard)

### Quick Setup with Python venv
```bash
# Clone the repository
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
```

### Alternative venv Commands
```bash
# Use specific Python version
python3.11 -m venv .venv

# Create with clear packages
python3 -m venv --clear .venv

# Create with system site packages (not recommended)
python3 -m venv --system-site-packages .venv
```

### 2. Environment Configuration

```bash
# Copy the example environment file
cp .env.example .env

# Edit the environment file with your settings
nano .env  # or use your preferred editor
```

**Required settings in `.env`:**
```env
SECRET_KEY=your-secret-key-here
SECURITY_PASSWORD_SALT=your-very-secure-password-salt-here
```

**Optional settings for AI features:**
```env
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama2
OLLAMA_TIMEOUT=300
OLLAMA_CHECK_TIMEOUT=5
```

### 3. Start the Application

```bash
python3 run.py
```

The application will be available at `http://localhost:5000`

---

## Package Management Comparison

### Using uv Commands
```bash
# Environment Management
uv venv                    # Create environment
source .venv/bin/activate  # Activate
rm -rf .venv              # Remove

# Package Management
uv pip install -e .       # Install project
uv pip install flask      # Install package
uv pip install -e ".[dev]" # Install dev deps
uv pip list               # List packages
uv pip cache clean        # Clear cache
```

### Using pip Commands (Standard venv)
```bash
# Environment Management
python3 -m venv .venv     # Create environment
source .venv/bin/activate  # Activate
rm -rf .venv              # Remove

# Package Management
pip install -r requirements.txt  # Install project
pip install flask              # Install package
pip install -r requirements-dev.txt  # Install dev deps
pip list                     # List packages
pip cache purge               # Clear cache
```

---

## Development Dependencies

### With uv
```bash
uv pip install -e ".[dev]"
```

### With pip
```bash
pip install pytest pytest-flask black flake8
```

Development dependencies include:
- `pytest` - Testing framework
- `pytest-flask` - Flask testing utilities
- `black` - Code formatting
- `flake8` - Linting

### Running Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app

# Run specific test file
pytest tests/test_app.py
```

### Code Quality
```bash
# Format code
black .

# Lint code
flake8 app/

# Both formatting and linting
black . && flake8 app/
```

## Project Structure

```
awen-screenplay-editor/
├── app/                    # Main application code
│   ├── __init__.py        # Flask app factory
│   ├── models.py          # Database models
│   ├── routes.py          # Main routes
│   ├── auth.py            # Authentication routes
│   └── ai_assistant.py    # AI integration
├── templates/             # Jinja2 templates
├── static/               # CSS, JS, images
├── tests/                # Test files
├── pyproject.toml        # Project configuration
├── .env.example          # Environment variables template
├── requirements.txt       # Legacy requirements (for compatibility)
└── run.py               # Application entry point
```

## Optional: Ollama Setup for AI Features

If you want to use the AI assistant features:

1. **Install Ollama** (https://ollama.ai)
2. **Pull a model**:
   ```bash
   ollama pull llama2
   ```
3. **Start Ollama**:
   ```bash
   ollama run llama2
   ```

The AI features will be available in the editor sidebar.

## Troubleshooting

### Virtual Environment Issues
```bash
# If activation fails, try:
uv venv --python 3.11
source .venv/bin/activate
```

### Dependencies Issues
```bash
# Clear cache and reinstall
uv pip cache clean
uv pip install -e .
```

### Port Already in Use
```bash
# Kill processes using port 5000
lsof -ti:5000 | xargs kill -9

# Or use a different port
export FLASK_RUN_PORT=5001
python3 run.py
```

## Production Deployment

For production, use the production configuration:

```bash
# Install with production dependencies
uv pip install -e ".[prod]"

# Set production environment variables
export FLASK_ENV=production
export SECRET_KEY=your-production-secret-key

# Run with production server
gunicorn -w 4 -b 0.0.0.0:5000 "app:create_app()"
```

## Benefits of Using uv

- **Fast**: uv is 10-100x faster than pip
- **Reliable**: Deterministic dependency resolution
- **Isolated**: Clean virtual environments
- **Modern**: Uses pyproject.toml for configuration
- **Cross-platform**: Works on Linux, macOS, and Windows

## Migration from pip

If you were previously using pip:

```bash
# Remove old virtual environment
deactivate
rm -rf venv

# Create new uv environment
uv venv
source .venv/bin/activate

# Install dependencies
uv pip install -e .
```

Your existing `.env` file and database will work without changes.
