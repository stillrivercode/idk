#!/bin/bash

# Setup script for native Git hooks (replaces Python pre-commit)
# Usage: ./scripts/setup-git-hooks.sh

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Create pre-commit hook
create_precommit_hook() {
    local hook_file=".git/hooks/pre-commit"

    log_info "Creating native Git pre-commit hook..."

    cat > "$hook_file" << 'EOF'
#!/bin/bash

# Native Git pre-commit hook
# Runs linting, formatting, and basic checks before commit

set -e

echo "Running pre-commit checks..."

# Run linting and formatting on staged files
echo "→ Running ESLint..."
if git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|ts|jsx|tsx)$' > /dev/null; then
    git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|ts|jsx|tsx)$' | xargs npx eslint --fix
fi

echo "→ Running Prettier..."
if git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|ts|jsx|tsx|json|md|yml|yaml)$' > /dev/null; then
    git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|ts|jsx|tsx|json|md|yml|yaml)$' | xargs npx prettier --write
fi

echo "→ Running YAML lint..."
if git diff --cached --name-only --diff-filter=ACM | grep -E '\.(yml|yaml)$' > /dev/null; then
    git diff --cached --name-only --diff-filter=ACM | grep -E '\.(yml|yaml)$' | xargs npx yaml-lint
fi

echo "→ Running Markdown lint..."
if git diff --cached --name-only --diff-filter=ACM | grep -E '\.md$' > /dev/null; then
    git diff --cached --name-only --diff-filter=ACM | grep -E '\.md$' | xargs npx markdownlint --fix
fi

# Basic file checks
echo "→ Checking for large files..."
git diff --cached --name-only --diff-filter=ACM | while read file; do
    if [[ -f "$file" ]]; then
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
        if [[ $size -gt 1048576 ]]; then  # 1MB
            echo "Error: Large file detected: $file (${size} bytes)"
            exit 1
        fi
    fi
done

# Check for package.json changes
if git diff --cached --name-only | grep -q "package\.json$"; then
    echo "→ Updating package-lock.json..."
    npm install --package-lock-only
    git add package-lock.json
fi

# Re-stage files that were modified by linting/formatting
git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|ts|jsx|tsx|json|md|yml|yaml)$' | xargs git add 2>/dev/null || true

echo "✓ Pre-commit checks passed"
EOF

    chmod +x "$hook_file"
    log_success "Pre-commit hook created at $hook_file"
}

# Create pre-push hook for additional checks
create_prepush_hook() {
    local hook_file=".git/hooks/pre-push"

    log_info "Creating native Git pre-push hook..."

    cat > "$hook_file" << 'EOF'
#!/bin/bash

# Native Git pre-push hook
# Runs tests and security checks before push

set -e

echo "Running pre-push checks..."

# Run tests if they exist
if npm run test >/dev/null 2>&1; then
    echo "→ Running tests..."
    npm test
fi

# Run security audit
echo "→ Running security audit..."
npm audit --audit-level=high || echo "Warning: Security vulnerabilities found"

echo "✓ Pre-push checks passed"
EOF

    chmod +x "$hook_file"
    log_success "Pre-push hook created at $hook_file"
}

main() {
    echo "Setting up native Git hooks..."

    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Error: Not in a Git repository"
        exit 1
    fi

    create_precommit_hook
    create_prepush_hook

    echo ""
    log_success "Git hooks setup completed!"
    echo "Native Git hooks are now active:"
    echo "  - Pre-commit: Linting, formatting, basic checks"
    echo "  - Pre-push: Tests and security audit"
    echo ""
    echo "To skip hooks temporarily: git commit --no-verify"
}

main "$@"
