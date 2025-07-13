# CLI Usage Guide

## Overview

The Agentic Workflow Template CLI provides both interactive and non-interactive modes
for creating AI-powered GitHub workflow automation projects.

## Installation & Usage

### NPM Package Usage

```bash
# Interactive mode (prompts for configuration)
npx @stillrivercode/agentic-workflow-template my-project

# Non-interactive mode (automated)
npx @stillrivercode/agentic-workflow-template my-project \
  --non-interactive \
  --github-org myorg \
  --repo-name my-project \
  --description "My AI workflow project"
```

### Local Development

```bash
# Interactive mode
npm run create-project

# Or directly
node cli/index.js my-project
```

## Command Line Options

### Basic Options

| Option           | Description                   | Default    |
| ---------------- | ----------------------------- | ---------- |
| `[project-name]` | Name of the project to create | _prompted_ |
| `-f, --force`    | Overwrite existing directory  | `false`    |
| `--skip-install` | Skip npm install step         | `false`    |
| `--git-init`     | Initialize git repository     | `false`    |
| `-h, --help`     | Display help information      | -          |
| `-V, --version`  | Show version number           | -          |

### Template Options

| Option                  | Description              | Values                             | Default   |
| ----------------------- | ------------------------ | ---------------------------------- | --------- |
| `--template <template>` | Project template variant | `default`, `minimal`, `enterprise` | `default` |

### Non-Interactive Options

| Option                  | Description                  | Example                        | Default               |
| ----------------------- | ---------------------------- | ------------------------------ | --------------------- |
| `--non-interactive`     | Run without prompts          | -                              | `false`               |
| `--github-org <org>`    | GitHub organization/username | `--github-org mycompany`       | _prompted_            |
| `--repo-name <name>`    | Repository name              | `--repo-name my-app`           | _project-name_        |
| `--description <desc>`  | Project description          | `--description "My app"`       | _default description_ |
| `--features <features>` | Comma-separated feature list | `--features ai-tasks,security` | _all features_        |

### Available Features

- `ai-tasks` - AI Task Automation
- `ai-pr-review` - AI PR Review
- `cost-monitoring` - Cost Monitoring
- `security` - Security Scanning

## Usage Examples

### Interactive Mode

```bash
# Basic interactive setup
npx @stillrivercode/agentic-workflow-template my-project

# Interactive with some options pre-set
npx @stillrivercode/agentic-workflow-template my-project \
  --template minimal \
  --git-init
```

### Non-Interactive Mode

```bash
# Minimal non-interactive setup
npx @stillrivercode/agentic-workflow-template my-project \
  --non-interactive \
  --github-org myorg

# Full non-interactive setup
npx @stillrivercode/agentic-workflow-template my-project \
  --force \
  --non-interactive \
  --github-org mycompany \
  --repo-name my-awesome-app \
  --description "An awesome AI-powered application" \
  --template enterprise \
  --features "ai-tasks,ai-pr-review,security" \
  --git-init
```

### CI/CD Usage

```bash
# Perfect for automated environments
npx @stillrivercode/agentic-workflow-template $PROJECT_NAME \
  --force \
  --non-interactive \
  --github-org $GITHUB_ORG \
  --repo-name $REPO_NAME \
  --description "$PROJECT_DESCRIPTION" \
  --template default \
  --skip-install
```

## Template Types

### Default (Recommended)

- Full feature set with all AI workflows
- Cost monitoring and security scanning
- Suitable for most use cases
- **Files**: 24 template files

### Minimal

- Basic AI task automation only
- Lightweight setup
- Good for simple projects
- **Files**: Subset of default template

### Enterprise

- Advanced features and monitoring
- Additional security controls
- Multi-environment support
- **Files**: Extended template set

## Output

The CLI creates a complete project structure with:

- **Configuration files**: `.github/repo-config.json`
- **Documentation**: `README.md`, `CLAUDE.md`, `docs/`
- **Scripts**: `scripts/` directory with automation tools
- **Workflows**: `.github/workflows/` (if applicable to template)
- **Development tools**: ESLint, Prettier, pre-commit hooks

## Troubleshooting

### Common Issues

1. **NPX not working locally**: Use `npm run create-project` for local development
2. **Permission errors**: Ensure you have write access to the target directory
3. **Template not found**: Verify the template name is one of: `default`, `minimal`, `enterprise`
4. **Interactive mode stuck**: Use `--non-interactive` with required options

### Debug Mode

```bash
# Enable debug output
DEBUG=true npx @stillrivercode/agentic-workflow-template my-project
```

### Getting Help

```bash
# Show all available options
npx @stillrivercode/agentic-workflow-template --help

# Check version
npx @stillrivercode/agentic-workflow-template --version
```

## Integration Examples

### GitHub Actions

```yaml
- name: Create AI Project
  run: |
    npx @stillrivercode/agentic-workflow-template ${{ github.event.repository.name }} \
      --force \
      --non-interactive \
      --github-org ${{ github.repository_owner }} \
      --repo-name ${{ github.event.repository.name }} \
      --description "Auto-generated AI workflow project"
```

### Shell Scripts

```bash
#!/bin/bash
set -e

PROJECT_NAME="my-ai-project"
GITHUB_ORG="mycompany"

npx @stillrivercode/agentic-workflow-template "$PROJECT_NAME" \
  --force \
  --non-interactive \
  --github-org "$GITHUB_ORG" \
  --repo-name "$PROJECT_NAME" \
  --description "AI-powered workflow automation" \
  --template default \
  --features "ai-tasks,ai-pr-review,cost-monitoring,security" \
  --git-init

echo "✅ Project created successfully at ./$PROJECT_NAME"
cd "$PROJECT_NAME"
echo "📁 Current directory: $(pwd)"
echo "📋 Next: Configure GitHub secrets and create first AI task"
```

## API Reference

For programmatic usage, see the exported functions in `cli/create-project.js`:

```javascript
const {
  createProject,
} = require('@stillrivercode/agentic-workflow-template/cli/create-project');

await createProject('my-project', {
  force: true,
  nonInteractive: true,
  githubOrg: 'myorg',
  repoName: 'my-project',
  description: 'My project',
  template: 'default',
  features: 'ai-tasks,ai-pr-review',
});
```
