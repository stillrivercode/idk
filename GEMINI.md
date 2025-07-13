# Gemini Project Context

You are working with an AI-powered development workflow template.

## Table of Contents

- [Key Concepts](#key-concepts)
- [Architecture Context](#architecture-context)
- [Common Commands](#common-commands)
- [Workflow Context](#workflow-context)
- [Cross-References](#cross-references)

## Key Concepts

- **AI Tasks**: Issues labeled 'ai-task' trigger automated implementation
- **OpenRouter**: All AI operations use OpenRouter API (not direct CLI)
- **Shared Commands**: You share common commands with other agents. See the
  `.ai/commands/` directory for details.

## Architecture Context

### Technology Stack

- **Platform**: GitHub Actions with OpenRouter API integration
- **AI Models**: Multi-model support (Claude, Gemini, GPT-4, Llama via OpenRouter)
- **Automation**: Bash scripts with Python utilities for AI workflow orchestration
- **Version Control**: Git with automated semantic versioning
- **Package Management**: npm with pyproject.toml for Python dependencies

### Coding Conventions

- **Shell Scripts**: Use bash with proper error handling (`set -euo pipefail`)
- **Python**: Follow PEP 8 standards with pyproject.toml configuration
- **Documentation**: Markdown with consistent formatting and anchor links
- **Security**: Never commit secrets, use repository secrets for API keys
- **Branching**: Always create feature branches, never work directly on main

### Architectural Patterns

- **Event-Driven**: GitHub Actions workflows triggered by labels and events
- **Microservices**: Modular scripts in `scripts/` and `dev-scripts/` with shared libraries
- **Template-Based**: Reusable document templates in `shared-commands/templates/`
- **Cost-Controlled**: Built-in API usage monitoring and circuit breakers

## AI Development Workflow

> **📋 Complete Workflow Guide**: See [docs/ai-workflow-guide.md](docs/ai-workflow-guide.md) for the full structured approach to AI development workflows.

### Recommended Workflow

1. **Start with Research**: Use `analyze-issue` to understand the problem space
2. **Update Roadmap**: Use `roadmap` to plan your features
3. **Create Specifications**: Use `create-spec-issue` for detailed technical specs
4. **Implement with AI**: Create implementation issues with the `ai-task` label

### Common Commands

- `analyze-issue` - Research & analysis (Step 1)
- `roadmap` - Plan features (Step 2)
- `create-spec-issue` - Create technical specs (Step 3)

### Example Usage

```bash
# Step 1: Research & Analysis
analyze-issue --issue 123
analyze-issue --issue 123 --generate-docs  # Creates research docs

# Step 2: Plan Features
roadmap --generate --input "New Feature A, Refactor B"
roadmap --generate --research-doc research.md  # Use research docs

# Step 3: Create Technical Specs
create-spec-issue --title "Technical specification for user login"
```

- Standard git operations and file management

## Workflow Context

When working locally, you help developers with:

- Code generation and review
- Test creation
- Documentation
- Bug fixing

Remember: GitHub Actions use OpenRouter, not local CLI tools.

## Cross-References

### Related Documentation

- [docs/ai-workflow-guide.md](docs/ai-workflow-guide.md) - Complete AI development workflow guide
- [CLAUDE.md](CLAUDE.md) - Claude-specific context and instructions
- [README.md](README.md) - Main project documentation and setup guide
- [README-dev.md](README-dev.md) - Template development guide
- [docs/simplified-architecture.md](docs/simplified-architecture.md) - Quick start guide
- [dev-docs/architecture.md](dev-docs/architecture.md) - Advanced setup documentation

### Workflow Documentation

- [.github/workflows/](/.github/workflows/) - GitHub Actions workflow definitions
- [scripts/](scripts/) - Automation scripts and utilities
- [dev-scripts/](dev-scripts/) - Scripts for template development
- [shared-commands/](shared-commands/) - Cross-AI compatible commands
- [specs/](specs/) - Technical specification documents

### Key Configuration Files

- [pyproject.toml](pyproject.toml) - Python project configuration
- [package.json](package.json) - Node.js dependencies and scripts
- [.pre-commit-config.yaml](.pre-commit-config.yaml) - Code quality hooks
