#!/bin/bash
# Basic validation script for IDK YAML files

# If a file path is provided, use it. Otherwise, use the idks directory.
if [ -n "$1" ]; then
  FILES="$1"
else
  FILES="idks/*.yaml"
fi

for file in $FILES; do
  if ! grep -q "name:" "$file"; then
    echo "Error: $file is missing the 'name' key."
    exit 1
  fi
  if ! grep -q "description:" "$file"; then
    echo "Error: $file is missing the 'description' key."
    exit 1
  fi
  if ! grep -q "tags:" "$file"; then
    echo "Error: $file is missing the 'tags' key."
    exit 1
  fi
done
echo "All IDK YAML files are valid."
