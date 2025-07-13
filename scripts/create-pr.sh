#!/bin/bash

# Script to create pull request with validation
# Usage: ./create-pr.sh
# Environment variables expected:
# - GITHUB_TOKEN
# - BRANCH_NAME
# - ISSUE_TITLE
# - ISSUE_NUMBER

set -e
# Note: Debug output (set -x) is disabled to prevent token exposure in logs

# Read from environment variables instead of command-line arguments
BRANCH_NAME="${BRANCH_NAME:?Error: BRANCH_NAME environment variable is required}"
ISSUE_TITLE="${ISSUE_TITLE:?Error: ISSUE_TITLE environment variable is required}"
ISSUE_NUMBER="${ISSUE_NUMBER:?Error: ISSUE_NUMBER environment variable is required}"

echo "Creating pull request for branch: $BRANCH_NAME"

# Function to extract PR number from URL using multiple methods
extract_pr_number() {
  local pr_url="$1"
  local branch_name="$2"
  local pr_number=""

  # Method 1: Try to extract from URL (e.g., https://github.com/owner/repo/pull/123)
  if [[ "$pr_url" =~ /pull/([0-9]+) ]]; then
    pr_number="${BASH_REMATCH[1]}"
    echo "Extracted PR number from URL: $pr_number" >&2
  fi

  # Method 2: If that fails, try getting the last number from the URL
  if [[ -z "$pr_number" ]] && [[ "$pr_url" =~ ([0-9]+)$ ]]; then
    pr_number="${BASH_REMATCH[1]}"
    echo "Extracted PR number from URL end: $pr_number" >&2
  fi

  # Method 3: If still no number, query GitHub API for the most recent PR
  if [[ -z "$pr_number" ]] && [[ -n "$branch_name" ]]; then
    echo "Warning: Could not extract PR number from URL, querying GitHub..." >&2
    pr_number=$(gh pr list --head "$branch_name" --json number --jq '.[0].number' 2>/dev/null || echo "")
    if [[ -n "$pr_number" ]]; then
      echo "Retrieved PR number from GitHub API: $pr_number" >&2
    fi
  fi

  # Return the PR number (empty if not found)
  echo "$pr_number"
}

# Check if PR already exists for this branch
EXISTING_PR=$(gh pr list --base main --head "$BRANCH_NAME" --json number --jq '.[0].number' || echo "")

if [[ -n "$EXISTING_PR" ]]; then
  echo "Pull request #$EXISTING_PR already exists for branch $BRANCH_NAME"
  echo "pull_request_number=$EXISTING_PR" >> "$GITHUB_OUTPUT"
else
  echo "Creating new pull request..."

  # Additional validation: Check if branch has meaningful changes
  COMMIT_COUNT=$(git rev-list --count HEAD ^main 2>/dev/null || echo "0")
  if [[ "$COMMIT_COUNT" -eq "0" ]]; then
    echo "Error: No commits found on branch relative to main"
    echo "This indicates an empty PR would be created. Skipping PR creation."
    exit 0
  fi

  # Check if the branch has any file changes
  CHANGED_FILES=$(git diff --name-only main...HEAD 2>/dev/null | wc -l)
  if [[ "$CHANGED_FILES" -eq "0" ]]; then
    echo "Error: No file changes detected between main and current branch"
    echo "This would result in an empty PR. Skipping PR creation."
    exit 0
  fi

  echo "Validation passed: $COMMIT_COUNT commits, $CHANGED_FILES files changed"

  # Create PR
  echo "Attempting to create pull request..."
  PR_CREATE_OUTPUT=$(gh pr create \
    --base main \
    --head "$BRANCH_NAME" \
    --title "AI Task: $ISSUE_TITLE" \
    --body "$(cat <<EOF
## AI-Generated Implementation

This PR was automatically generated to address issue #$ISSUE_NUMBER.

**Original Issue:** $ISSUE_TITLE

### Changes Made
- Implemented requested feature/fix using AI assistance
- Followed existing code patterns and conventions
- Added appropriate tests and documentation

### Review Checklist
- [ ] Code follows project conventions
- [ ] Tests pass
- [ ] Documentation is updated
- [ ] Security considerations addressed
- [ ] Performance impact assessed

**Note:** This is an AI-generated implementation. Please review thoroughly before merging.

Closes #$ISSUE_NUMBER
EOF
)" 2>&1)

  PR_CREATE_EXIT_CODE=$?

  # Check if command succeeded
  if [[ $PR_CREATE_EXIT_CODE -ne 0 ]]; then
    echo "Error: Failed to create pull request (exit code: $PR_CREATE_EXIT_CODE)"
    echo "Command output: $PR_CREATE_OUTPUT"
    echo "Branch: $BRANCH_NAME"

    # Check for specific permission error
    if [[ "$PR_CREATE_OUTPUT" == *"GitHub Actions is not permitted to create"* ]] || [[ "$PR_CREATE_OUTPUT" == *"Bad credentials"* ]] || [[ "$PR_CREATE_OUTPUT" == *"authentication"* ]] || [[ "$PR_CREATE_OUTPUT" == *"Resource not accessible by integration"* ]] || [[ "$PR_CREATE_OUTPUT" == *"403"* ]]; then
      echo ""
      echo "=========================================="
      echo "GITHUB ACTIONS PERMISSION ERROR"
      echo ""
      echo "This workflow requires a Personal Access Token named 'GH_PAT'"
      echo ""
      echo "To fix this:"
      echo "1. Create a Personal Access Token at https://github.com/settings/tokens"
      echo "2. Grant it 'repo' scope permissions (and 'workflow' if cross-workflow triggering is needed)"
      echo "3. Add it as a secret named 'GH_PAT' in repository Settings > Secrets and variables > Actions"
      echo "4. Ensure the PAT hasn't expired"
      echo ""
      echo "Error details: $PR_CREATE_OUTPUT"
      echo "=========================================="
    elif [[ "$PR_CREATE_OUTPUT" == *"already exists"* ]]; then
      echo ""
      echo "Note: A PR may already exist for this branch"
      echo "Check existing PRs before retrying"
    fi

    exit 1
  fi

  # Store the output as PR_URL
  PR_URL="$PR_CREATE_OUTPUT"

  # Validate PR creation succeeded
  if [[ -z "$PR_URL" ]]; then
    echo "Error: PR creation returned empty URL despite successful exit code"
    echo "This may indicate:"
    echo "  - Authentication issues with GitHub token"
    echo "  - Branch configuration problems"
    echo "  - Network connectivity issues"
    echo ""
    echo "Debug information:"
    echo "  - Branch: $BRANCH_NAME"
    echo "  - Exit code: $PR_CREATE_EXIT_CODE"
    echo "  - Has output: $([[ -n "$PR_CREATE_OUTPUT" ]] && echo "yes" || echo "no")"
    exit 1
  fi

  # Additional validation: check if URL looks valid
  if [[ ! "$PR_URL" =~ ^https://github.com/.+/pull/[0-9]+$ ]]; then
    echo "Warning: PR URL format looks unusual: $PR_URL"
    echo "Expected format: https://github.com/owner/repo/pull/123"
    # Don't exit here, but flag it for debugging
  fi

  # Try to add labels after PR creation (ignore errors if labels don't exist)
  if [[ -n "$PR_URL" ]]; then
    PR_NUM=$(echo "$PR_URL" | grep -oE '[0-9]+$' || echo "")
    if [[ -n "$PR_NUM" ]]; then
      echo "Attempting to add labels to PR #$PR_NUM..."
      gh pr edit "$PR_NUM" --add-label "ai-generated" 2>/dev/null || echo "Note: 'ai-generated' label not found"
      gh pr edit "$PR_NUM" --add-label "needs-review" 2>/dev/null || echo "Note: 'needs-review' label not found"
    fi
  fi

  echo "Successfully created pull request: $PR_URL"

  # Extract PR number using our dedicated function
  PR_NUMBER=$(extract_pr_number "$PR_URL" "$BRANCH_NAME")

  if [[ -n "$PR_NUMBER" ]]; then
    echo "PR number: $PR_NUMBER"
    echo "pull_request_number=$PR_NUMBER" >> "$GITHUB_OUTPUT"
    echo "pr_url=$PR_URL" >> "$GITHUB_OUTPUT"
  else
    echo "Error: Could not determine PR number from URL: $PR_URL"
    echo "This may cause issues with subsequent workflow steps"
    # Still output the URL even if we couldn't extract the number
    echo "pr_url=$PR_URL" >> "$GITHUB_OUTPUT"
    exit 1
  fi
fi

echo "PR creation process complete"
