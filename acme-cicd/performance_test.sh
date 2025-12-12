#!/bin/sh

# Performance tests for URL Shortener REST API using K6

set -e

# Store the script directory before changing directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Change to parent directory
cd "$(dirname "$0")/.."

# Check if k6 is installed
if ! command -v k6 >/dev/null 2>&1; then
    echo "Installing K6..."
    
    # Determine OS and install K6
    if [ "$(uname)" = "Darwin" ]; then
        # macOS installation
        if command -v brew >/dev/null 2>&1; then
            brew install k6
        else
            echo "ERROR: Homebrew not found. Please install K6 manually from https://k6.io/docs/getting-started/installation/"
            exit 1
        fi
    elif [ "$(uname)" = "Linux" ]; then
        # Linux installation
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        
        # Add K6 repository
        apt-get install dirmngr --install-recommends -y
        apt-get install -y gnupg ca-certificates
        gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
        echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | tee /etc/apt/sources.list.d/k6.list
        apt-get update -y
        apt-get install -y k6
    else
        echo "ERROR: Unsupported OS. Please install K6 manually from https://k6.io/docs/getting-started/installation/"
        exit 1
    fi
else
    echo "K6 already installed"
fi

# Verify K6 installation
k6 version

# Read API endpoint from deployment output
if [ ! -f "deployment_output.json" ]; then
    echo "ERROR: deployment_output.json not found. Run deploy.sh first."
    exit 1
fi

API_ENDPOINT=$(cat deployment_output.json | grep -o '"endpoint": "[^"]*"' | cut -d'"' -f4)

if [ -z "$API_ENDPOINT" ]; then
    echo "ERROR: Could not extract API endpoint from deployment_output.json"
    exit 1
fi

echo "=========================================="
echo "Performance Testing URL Shortener API"
echo "API Endpoint: $API_ENDPOINT"
echo "=========================================="
echo ""
echo "Performance Requirements:"
echo "  - CREATE: 60 requests/minute"
echo "  - READ:   120 requests/minute"
echo "  - UPDATE: 30 requests/minute"
echo "  - DELETE: 15 requests/minute"
echo ""
echo "Starting K6 performance tests..."
echo "=========================================="

# Use the stored script directory to find the K6 script
K6_SCRIPT="$SCRIPT_DIR/performance_test.js"

if [ ! -f "$K6_SCRIPT" ]; then
    echo "ERROR: K6 script not found at $K6_SCRIPT"
    exit 1
fi

# Get the absolute path to the workspace root
WORKSPACE_ROOT="$(pwd)"

# Run K6 tests with path relative to workspace root (for Docker volume mount)
# The k6 wrapper mounts PWD to /src in the container
k6 run \
    --out json=performance_results.json \
    -e API_ENDPOINT="$API_ENDPOINT" \
    /src/acme-cicd/performance_test.js

K6_EXIT_CODE=$?

echo ""
echo "=========================================="
echo "Performance Test Results"
echo "=========================================="

if [ $K6_EXIT_CODE -eq 0 ]; then
    echo "✓ All performance tests PASSED"
    echo ""
    echo "The API successfully handled:"
    echo "  ✓ CREATE: 60 requests/minute"
    echo "  ✓ READ:   120 requests/minute"
    echo "  ✓ UPDATE: 30 requests/minute"
    echo "  ✓ DELETE: 15 requests/minute"
    echo ""
    echo "Results saved to: performance_results.json"
    echo "=========================================="
    exit 0
else
    echo "✗ Performance tests FAILED"
    echo ""
    echo "One or more performance thresholds were not met."
    echo "Check the output above for details."
    echo ""
    echo "Results saved to: performance_results.json"
    echo "=========================================="
    exit 1
fi
