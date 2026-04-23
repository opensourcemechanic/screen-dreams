#!/bin/bash
# Screen Dreams - Quick Start
# Tries uvx (recommended), then podman, then plain Python as fallback.
# Usage: ./start.sh [dev]
#   (no args) - production mode on port 5000
#   dev        - development mode with auto-reload

set -e

MODE=${1:-prod}
PORT=${PORT:-5000}

echo "Screen Dreams Screenwriter"
echo "=========================="

if command -v uvx &>/dev/null; then
    echo "Starting with uvx on port $PORT..."
    # Create temporary env file for uvx
    env_file=$(mktemp)
    echo "PORT=$PORT" > "$env_file"
    if [ "$MODE" = "dev" ]; then
        exec uvx --from . --env-file "$env_file" screen-dreams --debug
    else
        exec uvx --from . --env-file "$env_file" screen-dreams
    fi
    rm -f "$env_file"  # Cleanup (shouldn't be reached due to exec)

elif command -v podman &>/dev/null; then
    echo "uvx not found. Starting with Podman on port $PORT..."
    exec podman run --rm -it \
        -p "${PORT}:5000" \
        -e SECRET_KEY="${SECRET_KEY:-change-me-in-production}" \
        -e FLASK_DEBUG="$([ "$MODE" = "dev" ] && echo True || echo False)" \
        -v "$(pwd)/instance:/app/instance" \
        ghcr.io/opensourcemechanic/screen-dreams:latest

elif command -v python3 &>/dev/null; then
    echo "uvx and podman not found. Starting with Python directly..."
    if [ ! -f ".venv/bin/python3" ]; then
        python3 -m venv .venv
        .venv/bin/pip install -e . -q
    fi
    if [ "$MODE" = "dev" ]; then
        exec .venv/bin/python3 run_dev.py
    else
        exec .venv/bin/python3 run.py
    fi

else
    echo "Error: No suitable runtime found."
    echo "Please install uvx (recommended): pip install uvx"
    echo "Or see UVX-QUICK-START.md for full instructions."
    exit 1
fi
