# Offline Usage Guide

This guide explains how to use the AI-powered workflow template in environments with limited or no
internet connectivity.

## Overview

While the AI workflows require internet access for OpenRouter API calls, many template features can work
offline or with limited connectivity:

- Local development and testing
- Workflow validation and syntax checking
- Code formatting and linting
- Git operations and branch management
- Manual script execution

## Offline Installation

### 1. Download Template Archive

**Online Method (when internet is available):**

```bash
# Download and extract template
npx @stillrivercode/agentic-workflow-template my-project --offline-mode
cd my-project
```

**Offline Method (from cached package):**

```bash
# If package is already cached
npm pack @stillrivercode/agentic-workflow-template
tar -xzf stillrivercode-agentic-workflow-template-*.tgz
cp -r package/* my-project/
cd my-project
```

### 2. Offline Dependencies

**Pre-install Dependencies:**

```bash
# While online, cache dependencies
npm install --prefer-offline
npm cache verify

# For Python dependencies (if using Python scripts)
pip download -r requirements.txt -d ./offline-packages
pip install --find-links ./offline-packages -r requirements.txt --no-index
```

## Offline Development Workflow

### Local Validation and Testing

**1. Workflow Syntax Validation:**

```bash
# Validate GitHub Actions workflows
./scripts/validate-workflows.sh

# Check YAML syntax
yamllint .github/workflows/

# Validate shell scripts
shellcheck scripts/*.sh
```

**2. Code Quality Checks:**

```bash
# Python linting (if applicable)
black --check .
isort --check-only .
ruff check .

# Security scanning
bandit -r scripts/ -f json

# Shell script linting
shellcheck scripts/*.sh
```

**3. Local Testing:**

```bash
# Test individual scripts
bash scripts/determine-branch-prefix.sh

# Test cost monitoring logic
bash scripts/cost-monitor.sh --dry-run

# Validate emergency controls
bash scripts/emergency-audit.sh --local
```

### Git Operations

All git operations work offline:

```bash
# Create branches
git checkout -b feature/offline-dev

# Commit changes
git add .
git commit -m "Offline development changes"

# View history
git log --oneline
git branch -a
```

## Limited Connectivity Usage

### Batch Operations

When you have intermittent connectivity, batch your operations:

**1. Prepare Work Offline:**

```bash
# Create multiple branches for different tasks
git checkout -b feature/task-1
git checkout -b feature/task-2
git checkout -b feature/task-3

# Prepare commit messages and documentation
echo "feat: add user authentication" > commit-msg-1.txt
echo "fix: resolve login validation bug" > commit-msg-2.txt
```

**2. Sync When Online:**

```bash
# Push all branches when connected
git push origin --all

# Sync with remote
git fetch origin
git merge origin/main
```

### Selective AI Usage

**Configure for Limited Usage:**

```bash
# Set conservative cost limits
export AI_DAILY_COST_LIMIT=5
export AI_MONTHLY_COST_LIMIT=50

# Use faster, cheaper models
export AI_DEFAULT_MODEL="anthropic/claude-3-haiku"
```

**Manual AI Prompts:**
When connectivity is limited, prepare prompts offline:

```bash
# Create prompt files
cat > task-prompt.txt << 'EOF'
Create a Python function that validates email addresses.
Requirements:
- Use regex for validation
- Return boolean
- Handle edge cases
- Include docstring
EOF

# Execute when online
scripts/openrouter-ai-helper.sh \
  --prompt-file task-prompt.txt \
  --output-file task-response.txt \
  --model "anthropic/claude-3.5-sonnet"
```

## Offline Configuration

### Environment Setup

**Create Offline Configuration:**

```bash
# .env.offline
GITHUB_ACTIONS=false
OFFLINE_MODE=true
AI_ENABLED=false
COST_TRACKING_ENABLED=false
```

**Load Configuration:**

```bash
# Source offline config
source .env.offline

# Or use in scripts
if [ "$OFFLINE_MODE" = "true" ]; then
  echo "Running in offline mode"
  # Skip AI operations
fi
```

### Workflow Modifications

**Create Offline Workflow Variants:**

```yaml
# .github/workflows/offline-validation.yml
name: Offline Validation
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  offline-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate Workflows
        run: ./scripts/validate-workflows.sh

      - name: Lint Code
        run: |
          black --check .
          isort --check-only .
          ruff check .

      - name: Security Scan
        run: bandit -r scripts/ -f json

      - name: Test Scripts
        run: |
          bash scripts/determine-branch-prefix.sh
          bash scripts/cost-monitor.sh --dry-run
```

## Offline Tools and Utilities

### 1. Local Script Testing

**Test Runner Script:**

```bash
#!/bin/bash
# test-offline.sh

echo "Running offline tests..."

# Test workflow validation
echo "✓ Testing workflow validation..."
./scripts/validate-workflows.sh

# Test branch prefix logic
echo "✓ Testing branch prefix logic..."
./scripts/determine-branch-prefix.sh

# Test emergency controls
echo "✓ Testing emergency controls..."
./scripts/emergency-audit.sh --local

echo "All offline tests completed!"
```

### 2. Workflow Preview

**Preview AI Task Workflow:**

```bash
#!/bin/bash
# preview-workflow.sh

ISSUE_TITLE="$1"
ISSUE_BODY="$2"

echo "AI Task Workflow Preview"
echo "========================"
echo "Issue Title: $ISSUE_TITLE"
echo "Issue Body: $ISSUE_BODY"
echo ""

# Determine branch prefix
BRANCH_PREFIX=$(./scripts/determine-branch-prefix.sh "$ISSUE_TITLE")
echo "Branch Prefix: $BRANCH_PREFIX"

# Generate branch name
BRANCH_NAME="${BRANCH_PREFIX}/ai-task-$(date +%s)"
echo "Branch Name: $BRANCH_NAME"

echo ""
echo "Workflow would:"
echo "1. Create branch: $BRANCH_NAME"
echo "2. Execute AI task (requires online)"
echo "3. Create pull request"
echo "4. Add labels and comments"
```

### 3. Cost Estimation

**Offline Cost Calculator:**

```bash
#!/bin/bash
# estimate-costs.sh

TASK_COMPLEXITY="$1"  # simple, medium, complex
ESTIMATED_TOKENS="$2"

case $TASK_COMPLEXITY in
  "simple")
    TOKENS=1000
    COST=0.003
    ;;
  "medium")
    TOKENS=5000
    COST=0.015
    ;;
  "complex")
    TOKENS=15000
    COST=0.045
    ;;
esac

if [ -n "$ESTIMATED_TOKENS" ]; then
  TOKENS=$ESTIMATED_TOKENS
  COST=$(echo "scale=4; $TOKENS * 0.000003" | bc)
fi

echo "Estimated cost for $TASK_COMPLEXITY task:"
echo "Tokens: $TOKENS"
echo "Cost: \$$COST"
```

## Offline Documentation

### Generate Offline Docs

**Create Offline Documentation Package:**

````bash
#!/bin/bash
# generate-offline-docs.sh

mkdir -p offline-docs

# Copy documentation
cp -r docs/* offline-docs/

# Generate workflow documentation
echo "# Workflow Reference" > offline-docs/workflows.md
for workflow in .github/workflows/*.yml; do
  echo "## $(basename $workflow)" >> offline-docs/workflows.md
  echo '```yaml' >> offline-docs/workflows.md
  cat $workflow >> offline-docs/workflows.md
  echo '```' >> offline-docs/workflows.md
  echo "" >> offline-docs/workflows.md
done

# Generate script documentation
echo "# Script Reference" > offline-docs/scripts.md
for script in scripts/*.sh; do
  echo "## $(basename $script)" >> offline-docs/scripts.md
  echo '```bash' >> offline-docs/scripts.md
  head -20 $script | grep "^#" >> offline-docs/scripts.md
  echo '```' >> offline-docs/scripts.md
  echo "" >> offline-docs/scripts.md
done

echo "Offline documentation generated in ./offline-docs/"
````

## Connectivity Testing

### Network Availability Check

**Connection Test Script:**

```bash
#!/bin/bash
# check-connectivity.sh

check_connection() {
  local url="$1"
  local timeout=5

  if curl --connect-timeout $timeout --silent --head "$url" > /dev/null; then
    return 0
  else
    return 1
  fi
}

echo "Checking connectivity..."

# Check GitHub API
if check_connection "https://api.github.com"; then
  echo "✓ GitHub API: Available"
  GITHUB_AVAILABLE=true
else
  echo "✗ GitHub API: Unavailable"
  GITHUB_AVAILABLE=false
fi

# Check OpenRouter API
if check_connection "https://openrouter.ai/api/v1/models"; then
  echo "✓ OpenRouter API: Available"
  OPENROUTER_AVAILABLE=true
else
  echo "✗ OpenRouter API: Unavailable"
  OPENROUTER_AVAILABLE=false
fi

# Determine mode
if [ "$GITHUB_AVAILABLE" = true ] && [ "$OPENROUTER_AVAILABLE" = true ]; then
  echo "Mode: Full functionality available"
  export CONNECTIVITY_MODE="full"
elif [ "$GITHUB_AVAILABLE" = true ]; then
  echo "Mode: Git operations only"
  export CONNECTIVITY_MODE="git-only"
else
  echo "Mode: Offline development only"
  export CONNECTIVITY_MODE="offline"
fi
```

## Best Practices for Offline Development

### 1. Preparation

- Download all dependencies while online
- Cache npm packages and Python dependencies
- Create offline documentation copies
- Test all scripts in offline mode

### 2. Development Workflow

- Use offline validation extensively
- Batch operations for online sync
- Maintain detailed commit messages
- Document changes for later review

### 3. Quality Assurance

- Run all offline tests before going online
- Use local linting and formatting tools
- Validate workflow syntax offline
- Test emergency procedures locally

### 4. Sync Strategy

- Prepare all changes offline
- Sync in batches when connected
- Monitor costs during online operations
- Use selective AI features based on connectivity

## Troubleshooting Offline Issues

### Common Problems

**1. Missing Dependencies:**

```bash
# Check cached packages
npm cache ls
pip cache list

# Verify offline installation
npm install --offline --no-audit
```

**2. Workflow Validation Errors:**

```bash
# Install workflow validation tools
npm install -g @actions/toolkit

# Use local YAML validation
python -c "import yaml; yaml.safe_load(open('.github/workflows/ai-task.yml'))"
```

**3. Script Execution Issues:**

```bash
# Check permissions
chmod +x scripts/*.sh

# Verify shell compatibility
bash -n scripts/script-name.sh
```

## Resources

### Offline-Compatible Tools

- **YAML Validation:** yamllint, python yaml module
- **Shell Linting:** shellcheck
- **Git Operations:** All standard git commands
- **Code Formatting:** black, isort, prettier (local)
- **Documentation:** Local markdown renderers

### Emergency Procedures

If you're offline and need to make urgent changes:

1. **Disable AI Workflows:**

   ```bash
   # Temporarily disable workflows
   mv .github/workflows .github/workflows.disabled
   ```

2. **Manual Operations:**

   ```bash
   # Manual branch creation and management
   git checkout -b emergency/critical-fix
   # Make changes
   git commit -m "emergency: critical fix"
   ```

3. **Restore When Online:**

   ```bash
   # Re-enable workflows
   mv .github/workflows.disabled .github/workflows

   # Push emergency changes
   git push origin emergency/critical-fix
   ```

Remember: Always test offline procedures while online to ensure they work when you need them!
