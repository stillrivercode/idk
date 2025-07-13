#!/bin/bash

# Script to commit changes made by AI task
# Usage: ./commit-changes.sh
# Requires environment variables: ISSUE_TITLE, ISSUE_NUMBER

set -e

# Read from environment variables instead of command-line arguments
ISSUE_TITLE="${ISSUE_TITLE:?Error: ISSUE_TITLE environment variable is required}"
ISSUE_NUMBER="${ISSUE_NUMBER:?Error: ISSUE_NUMBER environment variable is required}"

echo "Checking for changes to commit..."

# Stage all changes first
if ! git diff --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo "Changes detected, staging files..."
  git add -A
  echo "Files staged successfully"
fi

# Commit any changes made
if ! git diff --cached --quiet; then
  CLEAN_TITLE=$(echo "$ISSUE_TITLE" | sed 's/\[AI Task\] //')
  echo "Committing changes with title: $CLEAN_TITLE"

  git commit -m "AI Task: $CLEAN_TITLE" \
             -m "" \
             -m "Implemented via AI task orchestration workflow." \
             -m "Addresses issue #$ISSUE_NUMBER." \
             -m "" \
             -m "Generated with Claude Code" \
             -m "Co-Authored-By: Claude <noreply@anthropic.com>"

  echo "Changes committed successfully"
else
  echo "No changes to commit"
fi
