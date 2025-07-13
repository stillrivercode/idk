#!/bin/bash
set -e

# Create a temporary directory for testing
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Create a valid IDK file
cat > "$TEMP_DIR/valid.yaml" <<EOL
name: "Valid IDK"
description: "This is a valid IDK."
tags:
  - "valid"
EOL

# Create an invalid IDK file (missing description)
cat > "$TEMP_DIR/invalid.yaml" <<EOL
name: "Invalid IDK"
tags:
  - "invalid"
EOL

# Test case 1: Valid IDK file
echo "Running test case 1: Valid IDK file"
if ! ./scripts/validate-idks.sh "$TEMP_DIR/valid.yaml"; then
  echo "Test case 1 failed: Validation of a valid IDK file should succeed."
  exit 1
fi
echo "Test case 1 passed."

# Test case 2: Invalid IDK file
echo "Running test case 2: Invalid IDK file"
if ./scripts/validate-idks.sh "$TEMP_DIR/invalid.yaml" 2>/dev/null; then
  echo "Test case 2 failed: Validation of an invalid IDK file should fail."
  exit 1
fi
echo "Test case 2 passed."

# Test case 3: Run against the actual idks directory
echo "Running test case 3: Actual idks directory"
if ! ./scripts/validate-idks.sh; then
    echo "Test case 3 failed: Validation of the actual idks directory should succeed."
    exit 1
fi
echo "Test case 3 passed."

echo "All tests passed."
