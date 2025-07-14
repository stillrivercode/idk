#!/bin/bash
set -e

# Create a temporary directory for testing
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Create a valid IDK file
cat > "$TEMP_DIR/valid.yaml" <<EOL
meta:
  id: "test.ValidIdk"
  version: "0.1.0"
  status: "draft"
  authors: ["@stillrivercode"]
keyword: "ValidIdk"
namespace: "test"
brief: "This is a valid IDK."
definition:
  description: "This is a valid IDK."
EOL

# Create an invalid IDK file (missing brief)
cat > "$TEMP_DIR/invalid.yaml" <<EOL
meta:
  id: "test.InvalidIdk"
  version: "0.1.0"
  status: "draft"
  authors: ["@stillrivercode"]
keyword: "InvalidIdk"
namespace: "test"
definition:
  description: "This is an invalid IDK."
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
