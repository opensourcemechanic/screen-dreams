#!/bin/bash

# Quick start script for the Awen Screenplay Editor
# Usage: ./start.sh [dev|prod]

MODE=${1:-prod}

echo "🎬 Awen Screenplay Editor - Quick Start"
echo "======================================"

case $MODE in
    "dev"|"debug")
        echo "🔧 Starting in DEVELOPMENT mode (debug enabled)..."
        export FLASK_DEBUG=True
        python3 run_dev.py
        ;;
    "prod"|"production")
        echo "🚀 Starting in PRODUCTION mode (debug disabled)..."
        export FLASK_DEBUG=False
        python3 run.py
        ;;
    *)
        echo "❌ Unknown mode: $MODE"
        echo "Usage: $0 [dev|prod]"
        echo ""
        echo "  dev   - Development mode with debug enabled"
        echo "  prod  - Production mode with debug disabled (default)"
        exit 1
        ;;
esac
