# CLAUDE.md

This file provides guidance to Claude Code when working with AI-powered development workflows in your repository.

## Overview

You are working in a repository that uses AI-powered development workflows. This enables automated coding assistance
through GitHub issues and pull requests.

## Key Features

- **AI Task Automation**: Create issues with `ai-task` label to trigger AI implementation
- **Automatic PR Generation**: AI creates pull requests with implemented solutions
- **Cost Monitoring**: Built-in tracking to prevent unexpected API costs
- **Multiple Architecture Options**: Choose between simplified or enterprise setup

## Getting Started

### 1. Initial Setup

```bash
# Install the template (includes upstream setup)
./install.sh

# Activate virtual environment
source venv/bin/activate
```

### 2. Configure GitHub Secrets

Required secrets in your repository settings:

- `OPENROUTER_API_KEY` - Your OpenRouter API key (enables multi-model AI support)
- `GH_PAT` - GitHub Personal Access Token (required for PR creation, needs repo scope minimum)

Optional secrets (only needed for advanced workflows that require cross-workflow triggering):

- Additional scopes for `GH_PAT`: workflow, write:packages, read:org (if cross-workflow triggering is needed)

### 3. Setup Repository Labels

```bash
./scripts/setup-labels.sh
```

## Using AI Workflows

> **📋 Complete Workflow Guide**: See [docs/ai-workflow-guide.md](docs/ai-workflow-guide.md) for the full structured approach to AI development workflows.

### Quick Start

For best results, follow this structured approach:

1. **Start with Research**: Create research documents to understand the problem space
2. **Update Roadmap**: Use `./shared-commands/commands/roadmap.sh` to plan your features
3. **Create Specifications**: Use `./shared-commands/commands/create-spec-issue.sh` for detailed technical specs
4. **Implement with AI**: Create implementation issues with the `ai-task` label

### Creating AI Tasks

1. Create a GitHub issue with clear requirements:
   - **Manual creation**: Use GitHub web interface
   - **Script creation**: Use `./scripts/create-issue.sh` with `--ai-task` flag for explicit opt-in
2. **Manually add the `ai-task` label** (no longer added automatically)
3. AI will automatically process and create a PR

**Note:** As of the latest update, the `ai-task` label is no longer automatically added to new issues.
You must manually add it to trigger AI processing.

Example issue:

```text
Title: Add user authentication endpoint
Labels: ai-task

Description:
- Create POST /api/auth/login endpoint
- Validate email and password
- Return JWT token on success
- Add appropriate error handling
```

### Available Labels

> **📋 Complete Label Guide**: See [docs/ai-workflow-guide.md#available-labels](docs/ai-workflow-guide.md#available-labels) for the full list and usage guidance.

- `ai-task` - General AI development tasks (use after creating specs)
- `ai-bug-fix` - AI-assisted bug fixes
- `ai-refactor` - Code refactoring requests
- `ai-test` - Test generation
- `ai-docs` - Documentation updates
- `research` - Research and analysis tasks (start here)
- `spec` - Technical specification issues

### AI Fix Orchestration Labels

- `ai-fix-all` - Triggers comprehensive AI fixes for all detected issues
- `ai-orchestrate` - Alternative trigger for coordinated AI fixes
- `ai-fix-lint` - Automatically added when lint checks fail
- `ai-fix-security` - Automatically added when security scans fail
- `ai-fix-tests` - Automatically added when test suites fail

### Orchestration Features

The AI Orchestrator automatically:

- Waits for quality checks to complete before triggering fixes
- Only runs AI fixes for actual failures (cost-efficient)
- Executes fixes in dependency order (lint → security/tests → docs)
- Provides comprehensive status reporting
- Manages cost controls and circuit breakers

### Debug Mode

Enable debug logging by setting the repository variable `AI_DEBUG_MODE` to `true`:

```bash
gh variable set AI_DEBUG_MODE --body "true" --repo <your-repo>
```

This adds detailed debugging information to workflow logs to help troubleshoot trigger issues.

### Emergency Controls

Repository administrators can trigger emergency actions through GitHub Actions:

- **Emergency Stop**: Immediately halt all AI workflows and cancel running jobs
- **Resume Operations**: Restore normal AI workflow operations
- **Maintenance Mode**: Temporarily disable AI workflows for system maintenance
- **Circuit Breaker Reset**: Reset circuit breaker after addressing failures
- **Cost Limit Override**: Temporarily increase cost limits during emergencies

To use emergency controls:

1. Go to Actions tab → Emergency Controls workflow
2. Click "Run workflow"
3. Select desired action and provide a reason
4. Confirm execution (admin permissions required)

### Timeout Configuration

Centralized timeout settings are now used across all workflows:

- **Workflow timeout**: 30 minutes (emergency controls: 10 minutes)
- **OpenRouter API setup**: Instant (no installation required)
- **AI execution tasks**: 20 minutes
- **AI operations**: 15 minutes

These can be modified by updating the `env` section in workflow files.

## OpenRouter API Configuration

### Supported Models

The AI workflows now use OpenRouter API for multi-model support:

- **anthropic/claude-3.5-sonnet** (default) - Best for complex coding tasks
- **anthropic/claude-3-haiku** - Cost-effective for simple tasks
- **openai/gpt-4-turbo** - Alternative for specialized use cases
- **google/gemini-pro** - Multilingual and vision tasks

### Model Configuration

Set the AI model via repository variables:

```bash
# Set via GitHub CLI
gh variable set AI_MODEL --body "anthropic/claude-3.5-sonnet"

# Or via GitHub web interface: Settings → Secrets and variables → Actions → Variables
```

### Dynamic Context Loading

The AI workflows automatically load model-specific context files:

- **Claude models** (`anthropic/*`) → loads `CLAUDE.md` context
- **Gemini models** (`google/gemini-*`) → loads `GEMINI.md` context
- **GPT models** (`openai/gpt-*`) → loads `GPT.md` context
- **Llama models** (`meta-llama/*`) → loads `LLAMA.md` context
- **Unknown models** → falls back to `CLAUDE.md` context

To use different AI models:

1. **Switch to Gemini**: `gh variable set AI_MODEL --body "google/gemini-pro"`
2. **Switch to GPT-4**: `gh variable set AI_MODEL --body "openai/gpt-4-turbo"`
3. **Switch back to Claude**: `gh variable set AI_MODEL --body "anthropic/claude-3.5-sonnet"`

The system will automatically use the appropriate context file (`GEMINI.md`, `GPT.md`, etc.)
if it exists, or fall back to `CLAUDE.md`.

### Performance Improvements

OpenRouter integration provides:

- **2-5 minute faster execution** (no CLI installation)
- **Automatic model failover** for reliability
- **Cost optimization** through model selection
- **Real-time usage tracking**

### API Key Setup

1. Create an OpenRouter account at <https://openrouter.ai>
2. Generate an API key from your dashboard
3. Add `OPENROUTER_API_KEY` secret to your repository
4. Remove old `ANTHROPIC_API_KEY` (no longer needed)

### GitHub Personal Access Token Setup

1. Create a Personal Access Token at <https://github.com/settings/tokens>
2. Grant it `repo` scope permissions (required for PR creation)
3. Add it as a secret named `GH_PAT` in repository Settings > Secrets and variables > Actions
4. Optionally add `workflow` scope if cross-workflow triggering is needed

**⚠️ Security Considerations:**

- Store `GH_PAT` as a repository secret (never commit to code)
- Use minimum required scopes (`repo` only unless cross-workflow triggering needed)
- Regularly rotate tokens (recommended: every 90 days)
- Monitor token usage in GitHub Settings > Personal access tokens
- Revoke immediately if compromised

## Cost Management

### Estimated Costs

- **Simple tasks**: $0.10 - $0.50 per issue
- **Complex features**: $1.00 - $5.00 per issue
- **Monthly estimates**:
  - Light usage (10-20 tasks): $20-50
  - Heavy usage (100+ tasks): $150-500

### Cost Controls

- Set spending limits in workflow configuration
- Monitor usage through GitHub Actions logs
- Use `ai-task-small` label for simple tasks

### Advanced Configuration

#### MAX_PROMPT_SIZE (GitHub Secret)

Control the maximum allowed prompt size for AI tasks:

```bash
# Set via GitHub CLI (recommended for large prompts)
gh secret set MAX_PROMPT_SIZE --body "100000"

# Or via GitHub web interface:
# Settings → Secrets and variables → Actions → New repository secret
```

- **Default**: 50,000 characters
- **Use cases**:
  - Increase for complex issues with large file contexts
  - Decrease to limit AI costs on simple tasks
- **Note**: Larger prompts may increase API costs

## Architecture Options

### Simplified Architecture (Default)

- GitHub Actions only
- No external dependencies
- Best for teams of 1-10 developers
- Estimated cost: $20-150/month

### Enterprise Architecture

- Requires additional setup (see dev-docs/architecture.md)
- Supports multiple AI providers
- Advanced monitoring and controls
- Best for teams of 15+ developers
- Estimated cost: $1,000-3,000/month

## Workflow Commands

```bash
# Create GitHub issue (with optional AI automation)
./scripts/create-issue.sh -t "Issue title" -b "Description"
./scripts/create-issue.sh -t "Issue title" --ai-task  # Explicit AI opt-in

# Run an AI task manually
./scripts/execute-ai-task.sh ISSUE_NUMBER

# Create a PR from AI changes
./scripts/create-pr.sh

# Check AI usage costs
./scripts/check-costs.sh
```

## Security Features

### Workflow Security Controls

The AI task workflow includes several security measures:

- **Permission Restrictions**: Limited to minimal required permissions (contents, issues, pull-requests, actions)
- **Timeout Controls**:
  - Job-level timeout: 30 minutes maximum
  - Step-level timeouts for long-running operations (AI execution: 20 min, no installation delays)
- **Concurrency Protection**: Prevents parallel runs of the same workflow using issue-specific groups
- **Token Scope Limitation**: Uses explicit permission declarations to restrict workflow capabilities

### Security Best Practices

- Workflows automatically timeout to prevent runaway processes
- Concurrent executions are blocked to prevent resource conflicts
- Minimal permissions reduce potential security exposure
- All operations are logged for audit purposes

## Best Practices

1. **Clear Issue Descriptions**: The better the description, the better the AI output
2. **Incremental Changes**: Break large features into smaller tasks
3. **Review AI Code**: Always review AI-generated code before merging
4. **Test Everything**: AI code should pass all tests before merging
5. **Cost Awareness**: Monitor your usage to avoid surprises
6. **Security Monitoring**: Review workflow logs for any unusual activity

## Code Quality Requirements

### Pre-commit Hooks

This project uses pre-commit hooks to ensure code quality. **All commits must pass pre-commit checks.**

#### Setup (One-time)

**Requirements:**

- **Pre-commit**: Version 2.15.0+ (recommended: latest)
- **Python**: 3.8+ (for hook execution)
- **Git**: Any recent version (2.10+)

```bash
# Install pre-commit (if not already installed)
pip install pre-commit>=2.15.0

# Install pre-commit hooks
pre-commit install

# Run on all files to test
pre-commit run --all-files
```

**Verification:**

```bash
# Check pre-commit version
pre-commit --version

# Check if hooks are installed
ls -la .git/hooks/pre-commit
```

#### Claude Code Workflow

When using Claude Code, it should:

1. **Always run pre-commit before committing**
2. **Fix any issues found** by the hooks
3. **Re-run pre-commit** until all checks pass
4. **Only then commit and push**

#### Manual Usage

```bash
# Run pre-commit on staged files
pre-commit run

# Run on all files
pre-commit run --all-files

# Skip hooks (emergency only)
git commit --no-verify
```

#### Skipping Pre-commit Hooks

**⚠️ Warning**: Skipping pre-commit hooks should be done sparingly and only in emergency situations.

##### When to Skip

- **Emergency hotfixes** that need immediate deployment
- **Non-code commits** (documentation-only changes where formatting is acceptable)
- **Temporary commits** in feature branches that will be squashed later
- **CI system issues** where hooks are failing due to infrastructure problems

##### How to Skip

```bash
# Skip all hooks for a single commit
git commit --no-verify -m "Emergency fix"

# Skip specific hooks only
SKIP=black,isort git commit -m "Commit with selective hook skipping"

# Skip hooks temporarily and fix later
git commit --no-verify -m "WIP: temporary commit"
# Later: fix issues and recommit
pre-commit run --all-files
git add -A
git commit --amend -m "Fixed and formatted commit"
```

##### Best Practices for Skipping

1. **Always document why** you skipped hooks in the commit message
2. **Fix issues in the next commit** if possible
3. **Use selective skipping** (`SKIP=hook1,hook2`) rather than full bypass when possible
4. **Never skip on main branch** - only on feature branches
5. **Review carefully** before merging any commits that bypassed hooks

##### Alternative: Staged Hook Execution

Instead of skipping entirely, you can run specific hooks manually:

```bash
# Run only formatting hooks
pre-commit run black isort ruff --all-files

# Run only security hooks
pre-commit run detect-secrets bandit --all-files

# Run everything except slow hooks
SKIP=bandit pre-commit run --all-files
```

## Troubleshooting

### Common Issues

1. **Workflow not triggering**
   - Check that labels are correctly applied
   - Verify GitHub secrets are set
   - Check Actions tab for errors

2. **AI produces incorrect code**
   - Improve issue description
   - Add examples or specifications
   - Use smaller, focused tasks

3. **High costs**
   - Review task complexity
   - Use simplified architecture
   - Set spending limits

## Project Structure

- **scripts/** - User-facing automation scripts for AI workflows
- **dev-scripts/** - Template development and testing scripts (for template maintainers)
- **docs/** - Detailed documentation and guides
- **.github/workflows/** - GitHub Actions workflows (if implemented)

## Need Help?

- Check `docs/simplified-architecture.md` for quick start guide
- See `dev-docs/architecture.md` for advanced setup
- Review workflow logs in GitHub Actions tab
- Create an issue with `help` label for support

## Workflow Specific Memory

- Update @docs/workflow-diagram.md when gha workflow files change
- `@README-dev.md` is for template related development
- `@README.md` is for those using the template

## Shared Commands for AI Assistants

> **📋 Complete Commands Guide**: See [docs/ai-workflow-guide.md#shared-commands-for-ai-assistants](docs/ai-workflow-guide.md#shared-commands-for-ai-assistants) for detailed usage instructions and examples.

This project includes shared commands that provide consistent functionality across different AI assistants (Claude, Gemini, etc.):

- **`analyze-issue`** - Research & analysis (Step 1)
- **`roadmap`** - Plan features (Step 2)
- **`create-spec-issue`** - Create technical specs (Step 3)

### Quick Reference

```bash
# Step 1: Research & Analysis
./shared-commands/commands/analyze-issue.sh --issue 25
./shared-commands/commands/analyze-issue.sh --issue 25 --generate-docs  # Creates research docs

# Step 2: Plan Features
./shared-commands/commands/roadmap.sh --generate --input "Feature A, Refactor B"
./shared-commands/commands/roadmap.sh --generate --research-doc research.md  # Use research docs

# Step 3: Create Technical Specs
./shared-commands/commands/create-spec-issue.sh --title "Authentication Architecture"
```

## Development Best Practices

- Use pyproject.toml instead of requirements.txt
- Always remove temporary files
- **Always create a feature branch when working on main** - Never make direct changes to main branch

## Version Management

This project uses **automated semantic versioning** via the release-generator.yml workflow:

- **Manual version bumps**: NOT needed - fully handled by release-generator.yml workflow
- **package-lock.json sync issues**: During development, run `npm install` to sync when dependencies change
- **Creating releases**: Use GitHub's "Run workflow" button on release-generator.yml workflow
- **Emergency version fixes**: Use workflow dispatch with specific version type parameter
- **NEVER use `npm version` commands manually** - this bypasses the sophisticated automated system
- **The automated system**: Analyzes conventional commits, calculates semantic versions, updates
  package.json/package-lock.json atomically, creates tags, generates release notes, and publishes to npm

**Key insight**: If you encounter package-lock.json inconsistency during development, this is normal
dependency sync friction - NOT a release versioning issue. Simply run `npm install` to resolve.

### NPM Dependency Management

To prevent npm ci failures in GitHub Actions:

- **Always run `npm install` after modifying package.json** - This updates package-lock.json
- **Always commit package-lock.json changes** - GitHub Actions uses `npm ci` which requires lock file consistency
- **Run `npm install` after pulling changes** - If package.json was modified by others
- **Pre-commit hook validation** - The project includes a hook that validates package-lock.json consistency
- **Never bypass the pre-commit hook** - Use `git commit --no-verify` only in emergencies
