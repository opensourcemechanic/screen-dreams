#!/bin/bash
# Screen Dreams - Stop Script
# Stops all running instances of Screen Dreams

set -e

echo "Screen Dreams - Stop"
echo "===================="

# Function to stop processes by name
stop_by_name() {
    local process_name="$1"
    local pids=$(pgrep -f "$process_name" 2>/dev/null || true)
    
    if [ -n "$pids" ]; then
        echo "Stopping $process_name processes..."
        echo "$pids" | xargs kill -TERM 2>/dev/null || true
        sleep 2
        
        # Force kill if still running
        pids=$(pgrep -f "$process_name" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            echo "Force stopping remaining $process_name processes..."
            echo "$pids" | xargs kill -KILL 2>/dev/null || true
        fi
        echo "✓ Stopped $process_name"
    else
        echo "No $process_name processes found"
    fi
}

# Stop uvx processes
stop_by_name "uvx.*screen-dreams"

# Stop python processes running screen dreams
stop_by_name "python.*run_dev.py"
stop_by_name "python.*run.py"

# Stop podman containers
echo "Checking for Podman containers..."
containers=$(podman ps -q --filter "name=screen-dreams" 2>/dev/null || true)
if [ -n "$containers" ]; then
    echo "Stopping Podman containers..."
    echo "$containers" | xargs podman stop 2>/dev/null || true
    echo "✓ Stopped Podman containers"
else
    echo "No Podman containers found"
fi

# Stop docker containers
echo "Checking for Docker containers..."
containers=$(docker ps -q --filter "name=screen-dreams" 2>/dev/null || true)
if [ -n "$containers" ]; then
    echo "Stopping Docker containers..."
    echo "$containers" | xargs docker stop 2>/dev/null || true
    echo "✓ Stopped Docker containers"
else
    echo "No Docker containers found"
fi

echo ""
echo "All Screen Dreams instances stopped."
echo "Ports 5000, 8080, 3000 should now be free."
