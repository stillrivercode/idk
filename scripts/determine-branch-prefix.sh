#!/bin/bash

# Script to determine branch prefix based on issue labels
# Usage: ./determine-branch-prefix.sh
# Environment variables expected:
# - HAS_BUG_LABEL
# - HAS_REFACTORING_LABEL
# - HAS_DOCUMENTATION_LABEL
# - HAS_TESTING_LABEL

set -e

echo "Determining branch prefix based on issue labels..."

# Determine branch prefix based on issue labels
if [[ "$HAS_BUG_LABEL" == "true" ]]; then
  echo "branch_prefix=hotfix" >> "$GITHUB_OUTPUT"
  echo "Branch prefix: hotfix (bug label detected)"
elif [[ "$HAS_REFACTORING_LABEL" == "true" ]]; then
  echo "branch_prefix=refactor" >> "$GITHUB_OUTPUT"
  echo "Branch prefix: refactor (refactoring label detected)"
elif [[ "$HAS_DOCUMENTATION_LABEL" == "true" ]]; then
  echo "branch_prefix=docs" >> "$GITHUB_OUTPUT"
  echo "Branch prefix: docs (documentation label detected)"
elif [[ "$HAS_TESTING_LABEL" == "true" ]]; then
  echo "branch_prefix=test" >> "$GITHUB_OUTPUT"
  echo "Branch prefix: test (testing label detected)"
else
  echo "branch_prefix=feat" >> "$GITHUB_OUTPUT"
  echo "Branch prefix: feat (default - no specific labels detected)"
fi

echo "Branch prefix determination complete"
