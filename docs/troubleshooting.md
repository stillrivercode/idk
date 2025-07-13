# Troubleshooting Guide

This guide helps resolve common issues when using the AI-powered workflow template.

## Installation Issues

### NPM Package Installation

**Error: `npm install -g @stillrivercode/agentic-workflow-template` fails**

**Solution:**

```bash
# Check Node.js version (18.0.0+ required)
node --version

# Update npm
npm install -g npm@latest

# Clear npm cache
npm cache clean --force

# Try installation again
npm install -g @stillrivercode/agentic-workflow-template
```

#### Error: Permission denied during global installation

**Solution (Linux/macOS):**

```bash
# Option 1: Use npx (recommended)
npx @stillrivercode/agentic-workflow-template my-project

# Option 2: Configure npm prefix
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
npm install -g @stillrivercode/agentic-workflow-template

# Option 3: Use sudo (not recommended)
sudo npm install -g @stillrivercode/agentic-workflow-template
```

### Project Creation Issues

**Error: `Project name contains invalid characters`**

**Solution:**

- Use only lowercase letters, numbers, hyphens, and underscores
- Cannot start or end with hyphen
- Maximum 214 characters
- Examples: `my-project`, `ai_workflow`, `project123`

**Error: `Directory already exists`**

**Solution:**

```bash
# Use force flag to overwrite
npx @stillrivercode/agentic-workflow-template my-project --force

# Or choose a different name
npx @stillrivercode/agentic-workflow-template my-project-v2
```

## API Key Issues

### OpenRouter API Key Problems

**Error: `Invalid API key format`**

**Solution:**

- Ensure key starts with `sk-or-`
- Check for extra spaces or newlines
- Verify key is 20-200 characters long
- Get a new key from [OpenRouter Dashboard](https://openrouter.ai/keys)

**Error: `API key not working in workflows`**

**Solution:**

1. **Check GitHub Secrets:**

   ```bash
   # Verify secret exists
   gh secret list

   # Update secret if needed
   gh secret set OPENROUTER_API_KEY --body "your-key-here"
   ```

2. **Verify workflow permissions:**
   - Go to Settings → Actions → General
   - Ensure "Read and write permissions" is enabled
   - Check "Allow GitHub Actions to create and approve pull requests"

3. **Test API key manually:**

   ```bash
   curl -X POST "https://openrouter.ai/api/v1/chat/completions" \
     -H "Authorization: Bearer your-key-here" \
     -H "Content-Type: application/json" \
     -d '{"model": "anthropic/claude-3.5-sonnet", "messages": [{"role": "user", "content": "test"}]}'
   ```

### API Rate Limiting

**Error: `Rate limit exceeded`**

**Solution:**

- Wait for rate limit reset (usually 1 minute)
- Implement exponential backoff in custom scripts
- Upgrade OpenRouter plan for higher limits
- Use different models with higher rate limits

## Workflow Issues

### GitHub Actions Not Triggering

#### Error: Workflows don't run when issues are created

**Troubleshooting Steps:**

1. **Check Labels:**

   ```bash
   # Verify ai-task label exists
   gh label list | grep ai-task

   # Create missing labels
   ./scripts/setup-labels.sh
   ```

2. **Check Workflow Files:**

   ```bash
   # Validate workflow syntax
   ./scripts/validate-workflows.sh

   # Check for YAML syntax errors
   yamllint .github/workflows/
   ```

3. **Check Repository Settings:**
   - Go to Settings → Actions → General
   - Ensure Actions are enabled
   - Check workflow permissions

4. **Check Issue Labels:**

   ```bash
   # Manually add ai-task label to issue
   gh issue edit 123 --add-label "ai-task"
   ```

### Workflow Execution Failures

**Error: `Permission denied` in workflows**

**Solution:**

```yaml
# Add to workflow permissions
permissions:
  contents: write
  issues: write
  pull-requests: write
  actions: read
```

**Error: `Command not found: gh`**

**Solution:**
Most workflows include GitHub CLI installation, but if missing:

```yaml
- name: Install GitHub CLI
  run: |
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh
```

### AI Task Execution Issues

**Error: `No AI model response`**

**Troubleshooting:**

1. **Check Cost Limits:**

   ```bash
   # Check current usage
   grep -r "Cost tracking" .github/workflows/

   # Review cost monitoring logs
   gh run list --workflow="AI Task Orchestration"
   ```

2. **Check Circuit Breaker:**

   ```bash
   # Reset circuit breaker if needed
   gh workflow run emergency-controls.yml -f action=circuit_breaker_reset
   ```

3. **Check Model Availability:**

   ```bash
   # Test different models
   curl -X GET "https://openrouter.ai/api/v1/models" \
     -H "Authorization: Bearer your-key-here"
   ```

**Error: `AI generates incorrect code`**

**Solutions:**

- Improve issue descriptions with more context
- Add specific requirements and examples
- Use smaller, focused tasks instead of large features
- Review and iterate on AI-generated code

## Security Scan Issues

### Bandit Security Scanning

**Error: `Bandit found security issues`**

**Solution:**

```bash
# Run bandit locally to see issues
bandit -r . -f json -o bandit-report.json

# Fix common issues:
# B101: assert_used - Use proper error handling instead of assert
# B602: subprocess_popen_with_shell_equals_true - Use shell=False
# B608: hardcoded_sql_expressions - Use parameterized queries
```

### Dependency Vulnerabilities

**Error: `Safety found vulnerable dependencies`**

**Solution:**

```bash
# Check vulnerabilities locally
safety check --json

# Update dependencies
pip-review --local --auto

# For specific vulnerabilities, update individual packages
pip install --upgrade package-name
```

## Git and Branch Issues

### Branch Creation Problems

**Error: `Failed to create feature branch`**

**Solution:**

```bash
# Check git configuration
git config user.name
git config user.email

# Set if missing
git config user.name "GitHub Actions"
git config user.email "actions@github.com"

# Check for branch naming conflicts
git branch -a | grep feature/ai-task
```

### Merge Conflicts

**Error: `Merge conflicts in pull request`**

**Solution:**

```bash
# Fetch latest changes
git fetch origin main

# Rebase feature branch
git checkout feature/ai-task-123
git rebase origin/main

# Resolve conflicts manually
# Then force push (workflows have permission)
git push --force-with-lease origin feature/ai-task-123
```

## Performance Issues

### Slow Workflow Execution

**Symptoms:**

- Workflows taking longer than expected
- Timeout errors

**Solutions:**

1. **Optimize Dependencies:**

   ```yaml
   # Cache dependencies
   - uses: actions/cache@v3
     with:
       path: ~/.cache/pip
       key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
   ```

2. **Parallel Execution:**

   ```yaml
   # Run independent steps in parallel
   strategy:
     matrix:
       task: [lint, test, security]
   ```

3. **Reduce Model Complexity:**
   - Use faster models for simple tasks
   - Switch from Claude to GPT-3.5 for basic operations

### Memory Issues

**Error: `Runner out of memory`**

**Solution:**

```yaml
# Use ubuntu-latest-4-cores or self-hosted runners
runs-on: ubuntu-latest-4-cores

# Or optimize memory usage
env:
  NODE_OPTIONS: --max-old-space-size=4096
```

## Cost Management Issues

### Unexpected High Costs

**Symptoms:**

- Higher than expected OpenRouter bills
- Cost alerts triggering frequently

**Solutions:**

1. **Review Usage Patterns:**

   ```bash
   # Check workflow run frequency
   gh run list --limit 50

   # Review cost tracking in logs
   gh run view --log | grep "Cost tracking"
   ```

2. **Implement Stricter Limits:**

   ```bash
   # Update repository variables
   gh variable set AI_DAILY_COST_LIMIT --body "25"
   gh variable set AI_MONTHLY_COST_LIMIT --body "200"
   ```

3. **Use Cost-Effective Models:**
   - Switch default model to GPT-3.5 Turbo
   - Use Claude Haiku for simple tasks
   - Implement model selection based on task complexity

## Debugging Tips

### Enable Debug Mode

```bash
# Set repository variable for debug logging
gh variable set AI_DEBUG_MODE --body "true"

# Check debug logs
gh run view --log | grep DEBUG
```

### Common Debug Commands

```bash
# Check workflow status
gh workflow list
gh workflow view "AI Task Orchestration"

# View recent runs
gh run list --workflow="AI Task Orchestration" --limit 10

# Download run logs
gh run download 1234567890

# Check repository secrets
gh secret list

# Verify repository labels
gh label list | grep ai-

# Test GitHub CLI authentication
gh auth status
```

### Manual Testing

```bash
# Test AI helper script manually
echo "Write a hello world function" > /tmp/prompt.txt
scripts/openrouter-ai-helper.sh \
  --prompt-file /tmp/prompt.txt \
  --output-file /tmp/response.txt \
  --model "anthropic/claude-3.5-sonnet"
cat /tmp/response.txt
```

## Getting Help

### Check Existing Issues

Search for similar problems:

- [Template Repository Issues](https://github.com/YOUR_ORG/YOUR_REPO/issues)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [OpenRouter Support](https://openrouter.ai/docs)

### Create a Support Issue

When creating a support issue, include:

1. **Environment Information:**

   ```bash
   node --version
   npm --version
   git --version
   ```

2. **Error Details:**
   - Full error message
   - Workflow run URL
   - Steps to reproduce

3. **Configuration:**
   - Repository settings
   - Workflow file contents (sanitized)
   - Environment variables (without secrets)

### Emergency Procedures

**Immediate Actions for Critical Issues:**

1. **Stop All Workflows:**

   ```bash
   gh workflow run emergency-controls.yml -f action=emergency_stop
   ```

2. **Revoke API Keys:**
   - OpenRouter Dashboard → Keys → Revoke
   - GitHub → Settings → Secrets → Delete

3. **Contact Support:**
   - Repository maintainers
   - OpenRouter support: <support@openrouter.ai>
   - GitHub support (if GitHub Actions issue)

## FAQ

**Q: Can I use this template with private repositories?**
A: Yes, all features work with private repositories. Ensure your GitHub plan supports Actions.

**Q: How do I migrate from an older version?**
A: Use the update script: `./dev-scripts/update-from-template.sh`

**Q: Can I customize the AI prompts?**
A: Yes, modify the prompt files in `.github/workflows/` or create custom scripts.

**Q: How do I reduce AI costs?**
A: Use smaller models, implement stricter cost controls, and optimize prompts for efficiency.

**Q: Can I use different AI providers?**
A: Currently OpenRouter only, but you can modify scripts to support other providers.

**Q: How do I backup my workflow configurations?**
A: All configurations are in git. Regular git backups preserve everything.

Remember: When in doubt, check the workflow logs first - they contain detailed information about what
went wrong and why.
