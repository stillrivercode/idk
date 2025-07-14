#!/bin/bash
# Basic CLI tool for expanding IDKs
idk_file=$1
if [ -f "$idk_file.yaml" ]; then
  awk '/expands_to:/ {sub(/.*expands_to: /, ""); print}' "$idk_file.yaml"
else
  echo "Error: IDK not found."
  exit 1
fi
