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
    
    # Determine OS and architecture
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    # Map architecture names to k6 naming convention
    case "$ARCH" in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        arm64)
            ARCH="arm64"
            ;;
        *)
            echo "ERROR: Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    K6_VERSION="v1.4.2"
    K6_TARBALL="k6-${K6_VERSION}-${OS}-${ARCH}.tar.gz"
    K6_URL="https://github.com/grafana/k6/releases/download/${K6_VERSION}/${K6_TARBALL}"
    
    echo "Downloading K6 for ${OS}-${ARCH}..."
    echo "URL: ${K6_URL}"
    
    # Download k6
    if command -v wget >/dev/null 2>&1; then
        wget -q "${K6_URL}" -O "${K6_TARBALL}"
    elif command -v curl >/dev/null 2>&1; then
        curl -sL "${K6_URL}" -o "${K6_TARBALL}"
    else
        echo "ERROR: Neither wget nor curl found. Cannot download k6."
        exit 1
    fi
    
    # Extract k6
    echo "Extracting K6..."
    tar -xzf "${K6_TARBALL}"
    
    # Move k6 binary to a location in PATH
    K6_DIR="k6-${K6_VERSION}-${OS}-${ARCH}"
    if [ -d "$K6_DIR" ]; then
        mv "${K6_DIR}/k6" /usr/local/bin/k6 2>/dev/null || sudo mv "${K6_DIR}/k6" /usr/local/bin/k6 || cp "${K6_DIR}/k6" ./k6
        chmod +x /usr/local/bin/k6 2>/dev/null || chmod +x ./k6
        rm -rf "${K6_DIR}" "${K6_TARBALL}"
    else
        echo "ERROR: K6 extraction failed"
        exit 1
    fi
    
    echo "K6 installed successfully"
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
    acme-cicd/performance_test.js

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
