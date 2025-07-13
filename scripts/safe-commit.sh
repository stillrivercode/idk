#!/bin/bash

# Safe commit script - runs pre-commit hooks and only commits if they pass

set -e

echo "🔍 Running pre-commit hooks..."

# Run pre-commit on staged files
if ! pre-commit run; then
    echo "❌ Pre-commit hooks failed!"
    echo "🔧 Attempting to auto-fix issues..."

    # Try auto-fixing common issues
    pre-commit run --all-files 2>/dev/null || true

    echo "📝 Please review the changes and stage them if they look correct:"
    echo "   git add ."
    echo "   ./scripts/safe-commit.sh"
    exit 1
fi

echo "✅ All pre-commit hooks passed!"

# If we have a commit message argument, use it
if [ $# -eq 0 ]; then
    echo "💬 No commit message provided. Opening editor..."
    git commit
else
    echo "📝 Committing with message: $1"
    git commit -m "$1"
fi

echo "🚀 Ready to push!"
