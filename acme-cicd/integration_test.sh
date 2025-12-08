#!/bin/bash

# Script to execute functional tests for URL Shortener API

set -e

# Change to script directory
cd "$(dirname "$0")"

echo "=========================================="
echo "Running URL Shortener Functional Tests"
echo "=========================================="

# Execute the functional test script
./functional_test.sh

echo ""
echo "=========================================="
echo "Functional tests completed successfully"
echo "=========================================="

echo ""
echo "=========================================="
echo "Running Performance Tests"
echo "=========================================="

# Execute the performance test script
./performance_test.sh

echo ""
echo "=========================================="
echo "All tests completed successfully"
echo "=========================================="
