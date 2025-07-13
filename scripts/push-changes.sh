#!/bin/bash

# Script to push changes to remote repository
# Usage: ./push-changes.sh
# Environment variables expected:
# - BRANCH_NAME

set -e

# Read from environment variable instead of command-line argument
BRANCH_NAME="${BRANCH_NAME:?Error: BRANCH_NAME environment variable is required}"

echo "Preparing to push changes for branch: $BRANCH_NAME"

# Always set the branch name for PR creation
echo "branch_name=$BRANCH_NAME" >> "$GITHUB_OUTPUT"

# Check if there are changes to push
if git diff --quiet HEAD~1 HEAD 2>/dev/null || [[ $(git rev-list --count HEAD) -eq 1 ]]; then
  echo "No changes to push"
else
  echo "Pushing changes to origin..."

  # Check if remote branch exists
  if git ls-remote --exit-code --heads origin "$BRANCH_NAME" >/dev/null 2>&1; then
    echo "Remote branch exists, attempting to pull and merge..."

    # Try to pull remote changes first
    if git pull origin "$BRANCH_NAME" --no-edit; then
      echo "Successfully merged remote changes"
      git push origin "$BRANCH_NAME"
    else
      echo "Pull failed, creating new branch with timestamp suffix..."
      TIMESTAMP=$(date +%Y%m%d-%H%M%S)
      NEW_BRANCH_NAME="${BRANCH_NAME}-${TIMESTAMP}"
      git checkout -b "$NEW_BRANCH_NAME"
      git push --set-upstream origin "$NEW_BRANCH_NAME"

      # Update the output for the PR step
      echo "branch_name=$NEW_BRANCH_NAME" >> "$GITHUB_OUTPUT"
    fi
  else
    echo "New branch, pushing with --set-upstream..."
    git push --set-upstream origin "$BRANCH_NAME"
    echo "branch_name=$BRANCH_NAME" >> "$GITHUB_OUTPUT"
  fi
fi

echo "Push operation complete"
