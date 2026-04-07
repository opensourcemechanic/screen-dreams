#!/bin/bash
# Debug script to test Docker detection

echo "=== Docker Detection Debug ==="
echo

echo "Current PATH: $PATH"
echo

echo "=== Testing which docker ==="
if which docker; then
    echo "SUCCESS: which docker found"
    echo "Location: $(which docker)"
else
    echo "FAILED: which docker not found"
fi
echo

echo "=== Testing command -v docker ==="
if command -v docker; then
    echo "SUCCESS: command -v docker found"
else
    echo "FAILED: command -v docker not found"
fi
echo

echo "=== Testing docker info ==="
if docker info >/dev/null 2>&1; then
    echo "SUCCESS: docker info works"
else
    echo "FAILED: docker info failed"
    echo "Error output:"
    docker info 2>&1 | head -5
fi
echo

echo "=== Testing which docker-compose ==="
if which docker-compose; then
    echo "SUCCESS: which docker-compose found"
    echo "Location: $(which docker-compose)"
else
    echo "FAILED: which docker-compose not found"
fi
echo

echo "=== Testing docker compose version ==="
if docker compose version >/dev/null 2>&1; then
    echo "SUCCESS: docker compose version works"
else
    echo "FAILED: docker compose version failed"
fi
echo

echo "=== Testing docker-compose --version ==="
if docker-compose --version >/dev/null 2>&1; then
    echo "SUCCESS: docker-compose --version works"
else
    echo "FAILED: docker-compose --version failed"
fi
echo

echo "=== Environment Variables ==="
echo "SHELL: $SHELL"
echo "BASH_VERSION: $BASH_VERSION"
echo

echo "=== Docker executables in PATH ==="
echo $PATH | tr ':' '\n' | while read dir; do
    if [ -d "$dir" ]; then
        echo "Checking $dir:"
        ls -la "$dir"/docker* 2>/dev/null || echo "  No docker executables found"
    fi
done
