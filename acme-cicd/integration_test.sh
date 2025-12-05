#!/bin/sh

# Integration tests for URL Shortener REST API

set -e

# Change to parent directory
cd "$(dirname "$0")/.."

# Check if curl is installed, install if missing
if ! command -v curl >/dev/null 2>&1; then
    echo "Installing curl..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y curl
else
    echo "curl already installed"
fi

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

echo "Testing URL Shortener API at: $API_ENDPOINT"
echo "=========================================="

# Test user ID
USER_ID="test-user@example.com"

# Generate a unique link ID for testing
LINK_ID="test-$(date +%s)"
TEST_URL="https://www.example.com/test/page"

echo ""
echo "Test 1: Create a new short URL"
echo "-------------------------------"
CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "shortener-user-id: $USER_ID" \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"$LINK_ID\",\"url\":\"$TEST_URL\"}" \
  "$API_ENDPOINT/app")

HTTP_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$CREATE_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ CREATE passed (HTTP $HTTP_CODE)"
    echo "  Response: $RESPONSE_BODY"
else
    echo "✗ CREATE failed (HTTP $HTTP_CODE)"
    echo "  Response: $RESPONSE_BODY"
    exit 1
fi

echo ""
echo "Test 2: Get all links for user"
echo "-------------------------------"
GET_ALL_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "shortener-user-id: $USER_ID" \
  "$API_ENDPOINT/app")

HTTP_CODE=$(echo "$GET_ALL_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$GET_ALL_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ GET ALL passed (HTTP $HTTP_CODE)"
    echo "  Response: $RESPONSE_BODY"
else
    echo "✗ GET ALL failed (HTTP $HTTP_CODE)"
    echo "  Response: $RESPONSE_BODY"
    exit 1
fi

echo ""
echo "Test 3: Redirect to full URL"
echo "-----------------------------"
REDIRECT_RESPONSE=$(curl -s -w "\n%{http_code}" -I -L "$API_ENDPOINT/$LINK_ID")

HTTP_CODE=$(echo "$REDIRECT_RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ] || echo "$REDIRECT_RESPONSE" | grep -q "301"; then
    echo "✓ REDIRECT passed"
    echo "$REDIRECT_RESPONSE" | head -n-1 | grep -E "^(HTTP|Location):"
else
    echo "✗ REDIRECT failed (HTTP $HTTP_CODE)"
    echo "$REDIRECT_RESPONSE"
    exit 1
fi

echo ""
echo "Test 4: Update existing link"
echo "-----------------------------"
UPDATED_URL="https://www.example.com/updated/page"
UPDATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT \
  -H "shortener-user-id: $USER_ID" \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"$LINK_ID\",\"url\":\"$UPDATED_URL\",\"timestamp\":\"$(date -u +"%a, %d %b %Y %H:%M:%S GMT")\",\"owner\":\"$USER_ID\"}" \
  "$API_ENDPOINT/app/$LINK_ID")

HTTP_CODE=$(echo "$UPDATE_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$UPDATE_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ UPDATE passed (HTTP $HTTP_CODE)"
    echo "  Response: $RESPONSE_BODY"
else
    echo "✗ UPDATE failed (HTTP $HTTP_CODE)"
    echo "  Response: $RESPONSE_BODY"
    exit 1
fi

echo ""
echo "Test 5: Delete link"
echo "-------------------"
DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE \
  -H "shortener-user-id: $USER_ID" \
  "$API_ENDPOINT/app/$LINK_ID")

HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$DELETE_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ DELETE passed (HTTP $HTTP_CODE)"
    echo "  Response: $RESPONSE_BODY"
else
    echo "✗ DELETE failed (HTTP $HTTP_CODE)"
    echo "  Response: $RESPONSE_BODY"
    exit 1
fi

echo ""
echo "Test 6: Verify link is deleted"
echo "-------------------------------"
VERIFY_DELETE=$(curl -s -w "\n%{http_code}" -I "$API_ENDPOINT/$LINK_ID")

HTTP_CODE=$(echo "$VERIFY_DELETE" | tail -n1)

if echo "$VERIFY_DELETE" | grep -q "301"; then
    # Link still exists (redirects), deletion may have failed
    echo "✗ VERIFY DELETE failed - link still exists"
    exit 1
else
    echo "✓ VERIFY DELETE passed - link no longer exists"
fi

echo ""
echo "=========================================="
echo "All integration tests passed! ✓"
echo "=========================================="
