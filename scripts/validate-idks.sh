#!/bin/bash
# Basic validation script for IDK YAML files

# If a file path is provided, use it. Otherwise, use the idks directory.
if [ -n "$1" ]; then
  FILES="$1"
else
  FILES="idks/*.yaml"
fi

for file in $FILES; do
  if ! grep -q "meta:" "$file"; then
    echo "Error: $file is missing the 'meta' key."
    exit 1
  fi
  if ! grep -q "keyword:" "$file"; then
    echo "Error: $file is missing the 'keyword' key."
    exit 1
  fi
  if ! grep -q "namespace:" "$file"; then
    echo "Error: $file is missing the 'namespace' key."
    exit 1
  fi
  if ! grep -q "brief:" "$file"; then
    echo "Error: $file is missing the 'brief' key."
    exit 1
  fi
  if ! grep -q "definition:" "$file"; then
    echo "Error: $file is missing the 'definition' key."
    exit 1
  fi
done
echo "All IDK YAML files are valid."
