#!/bin/bash
# Screen Dreams - Quick Start
# Usage: ./start.sh [dev]
#   (no args)  production mode, binds to PORT (default 5000)
#   dev        development mode with Flask auto-reload on port 5000
#
# Flask always runs internally on port 5000.
# In production mode, gunicorn binds to $PORT so you can use any port.
# In dev mode, Flask debug server runs on port 5000 (auto-reload requires this).

set -e

MODE=${1:-prod}
PORT=${PORT:-5000}

echo "Screen Dreams Screenwriter"
echo "=========================="

run_gunicorn() {
    echo "Starting with gunicorn on port $PORT..."
    exec gunicorn \
        --bind "0.0.0.0:${PORT}" \
        --workers 2 \
        --timeout 30 \
        --access-logfile - \
        "app:create_app()"
}

run_flask_dev() {
    echo "Starting Flask dev server on port 5000..."
    exec python3 -c "
import os, sys
os.environ['FLASK_DEBUG'] = 'True'
sys.path.insert(0, '.')
from app import create_app
app = create_app()
print('Server: http://localhost:5000')
app.run(debug=True, host='0.0.0.0', port=5000)
"
}

if command -v uvx &>/dev/null; then
    if [ "$MODE" = "dev" ]; then
        exec uvx --from . screen-dreams --debug
    else
        # Use gunicorn via uvx for production port binding
        exec uvx --from . --with gunicorn -- gunicorn \
            --bind "0.0.0.0:${PORT}" \
            --workers 2 \
            --timeout 30 \
            --access-logfile - \
            "app:create_app()"
    fi

elif command -v podman &>/dev/null; then
    echo "Starting with Podman, mapping host:$PORT -> container:5000..."
    exec podman run --rm -it \
        -p "${PORT}:5000" \
        -e SECRET_KEY="${SECRET_KEY:-change-me-in-production}" \
        -e FLASK_DEBUG="$([ "$MODE" = "dev" ] && echo True || echo False)" \
        -v "$(pwd)/instance:/app/instance" \
        ghcr.io/opensourcemechanic/screen-dreams:latest

elif command -v gunicorn &>/dev/null; then
    if [ "$MODE" = "dev" ]; then
        run_flask_dev
    else
        run_gunicorn
    fi

elif command -v python3 &>/dev/null; then
    echo "Installing dependencies..."
    if [ ! -f ".venv/bin/activate" ]; then
        python3 -m venv .venv
        .venv/bin/pip install -e . -q
    fi
    source .venv/bin/activate
    if [ "$MODE" = "dev" ]; then
        run_flask_dev
    else
        run_gunicorn
    fi

else
    echo "Error: No suitable runtime found."
    echo "Please install uvx (recommended): pip install uvx"
    echo "Or see UVX-QUICK-START.md for full instructions."
    exit 1
fi
