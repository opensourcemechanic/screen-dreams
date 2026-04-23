#!/bin/bash
# Screen Dreams - Stop Script
# Stops all running Screen Dreams instances regardless of how they were started:
#   - uvx (screen-dreams entry point)
#   - gunicorn (production)
#   - Flask dev server (run_dev.py)
#   - Podman containers
#   - Docker containers
# Usage: ./stop.sh

STOPPED=0

echo "Screen Dreams - Stop"
echo "===================="

# Gracefully terminate matching processes, force-kill if needed
stop_processes() {
    local label="$1"
    local pattern="$2"
    local pids
    pids=$(pgrep -f "$pattern" 2>/dev/null || true)
    if [ -n "$pids" ]; then
        echo "Stopping $label..."
        echo "$pids" | xargs kill -TERM 2>/dev/null || true
        sleep 1
        # Force-kill any survivors
        pids=$(pgrep -f "$pattern" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            echo "$pids" | xargs kill -KILL 2>/dev/null || true
        fi
        echo "  Stopped $label"
        STOPPED=$((STOPPED + 1))
    fi
}

# uvx / screen-dreams entry point
stop_processes "uvx screen-dreams"     "uvx.*screen-dreams"
stop_processes "screen-dreams (entry)" "screen-dreams"

# gunicorn workers
stop_processes "gunicorn (screen-dreams)" "gunicorn.*app:create_app"

# Flask dev server
stop_processes "Flask dev server" "python.*run_dev\.py"
stop_processes "Flask server"     "python.*run\.py"

# Podman containers
if command -v podman &>/dev/null; then
    containers=$(podman ps -q --filter "ancestor=ghcr.io/opensourcemechanic/screen-dreams" 2>/dev/null || true)
    # Also catch containers started by name or compose
    named=$(podman ps -q --filter "name=screen-dreams" 2>/dev/null || true)
    containers=$(echo -e "$containers\n$named" | sort -u | grep -v '^$' || true)
    if [ -n "$containers" ]; then
        echo "Stopping Podman containers..."
        echo "$containers" | xargs podman stop 2>/dev/null || true
        echo "  Stopped Podman containers"
        STOPPED=$((STOPPED + 1))
    fi
fi

# Docker containers
if command -v docker &>/dev/null; then
    containers=$(docker ps -q --filter "ancestor=ghcr.io/opensourcemechanic/screen-dreams" 2>/dev/null || true)
    named=$(docker ps -q --filter "name=screen-dreams" 2>/dev/null || true)
    containers=$(echo -e "$containers\n$named" | sort -u | grep -v '^$' || true)
    if [ -n "$containers" ]; then
        echo "Stopping Docker containers..."
        echo "$containers" | xargs docker stop 2>/dev/null || true
        echo "  Stopped Docker containers"
        STOPPED=$((STOPPED + 1))
    fi
fi

# Docker Compose (if compose files exist)
if command -v docker &>/dev/null && [ -f docker-compose.yml ]; then
    if docker compose ps -q 2>/dev/null | grep -q .; then
        echo "Stopping Docker Compose services..."
        docker compose down 2>/dev/null || true
        echo "  Stopped Docker Compose services"
        STOPPED=$((STOPPED + 1))
    fi
fi

echo ""
if [ "$STOPPED" -eq 0 ]; then
    echo "No running Screen Dreams instances found."
else
    echo "Done. All Screen Dreams instances stopped."
fi
