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
examples:
  - input: "ValidIdk"
    expands_to: "This is the expanded version of the valid IDK."
EOL

# Test case 1: Valid IDK
echo "Running test case 1: Valid IDK"
expanded_text=$(./scripts/idk.sh "$TEMP_DIR/valid")
expected_text='"This is the expanded version of the valid IDK."'
if [ "$expanded_text" != "$expected_text" ]; then
  echo "Test case 1 failed: Expansion of a valid IDK should succeed."
  echo "Expected: $expected_text"
  echo "Got: $expanded_text"
  exit 1
fi
echo "Test case 1 passed."

# Test case 2: Invalid IDK
echo "Running test case 2: Invalid IDK"
if ./scripts/idk.sh "$TEMP_DIR/invalid" 2>/dev/null; then
  echo "Test case 2 failed: Expansion of an invalid IDK should fail."
  exit 1
fi
echo "Test case 2 passed."

echo "All tests passed."
