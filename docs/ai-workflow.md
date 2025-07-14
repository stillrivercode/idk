# AI Workflow Usage Guide

This guide explains how to use the AI task orchestration system to automate
development tasks using Claude Code and GitHub Actions.

## Quick Start

1. **Create an AI Task Issue**
   - Go to Issues → New Issue
   - Select "AI Task Request" template
   - Fill out the task details
   - Add the `ai-task` label (automatically added by template)

2. **Automatic Processing**
   - GitHub Actions will automatically detect the labeled issue
   - AI will create a feature branch `ai-task-{issue-number}`
   - Claude Code CLI will implement the requested feature
   - A pull request will be automatically created for review
   - The `ai-task` label is automatically removed and replaced with
     `ai-completed`

## Setting Up the System

### Prerequisites

- GitHub repository with Actions enabled
- OpenRouter API key (for multi-model AI support)
- GitHub Personal Access Token (for PR creation)

### Configuration

1. **Add API Key to Repository Secrets**

   ```text
   Settings → Secrets and variables → Actions → New repository secret
   Name: OPENROUTER_API_KEY
   Value: your-openrouter-api-key
   ```

   **Note**: The system now uses OpenRouter API for multi-model support instead
   of direct Anthropic API.

2. **GitHub Token Configuration**
   - **Required**: Set `GH_PAT` secret with a Personal Access Token (repo scope
     minimum)
   - **Advanced**: Add workflow, write:packages, read:org scopes for
     cross-workflow triggering
   - This token is required for PR creation and repository operations

3. **Verify GitHub Actions**
   - Ensure Actions are enabled in repository settings
   - The workflow file is at `.github/workflows/ai-task.yml`

## How to Create Effective AI Tasks

### Task Types Supported

- **New Features**: Add new functionality to the codebase
- **Bug Fixes**: Fix existing issues or errors
- **Refactoring**: Improve code structure and maintainability
- **Documentation**: Update or create documentation
- **Testing**: Add or improve test coverage
- **Performance**: Optimize existing code

### Writing Good Task Descriptions

### Be Specific

```markdown
❌ Bad: "Fix the login"
✅ Good: "Fix login form validation to properly handle email format errors and
show user-friendly messages"
```

### Provide Context

```markdown
❌ Bad: "Add a button"
✅ Good: "Add a 'Save Draft' button to the article editor that saves content to
localStorage without publishing"
```

### Include Technical Details

```markdown
- **Affected Files**: `src/components/Login.js`, `src/utils/validation.js`
- **Dependencies**: Uses React Hook Form library
- **Performance**: Should validate on blur, not on every keystroke
```

### Complexity Guidelines

### Simple Tasks (< 1 hour)

- Single file changes
- Minor bug fixes
- Documentation updates
- Simple styling changes

### Medium Tasks (1-4 hours)

- Multi-file features
- Database schema changes
- API endpoint creation
- Component refactoring

### Complex Tasks (> 4 hours)

- New feature modules
- Architecture changes
- Performance optimizations
- Integration with external services

## Review Process

### Automated Checks

The AI workflow includes several quality gates:

- Code style validation
- Test execution
- Security scanning
- Build verification

### Manual Review Requirements

Every AI-generated PR requires human review:

1. **Code Quality Review**
   - [ ] Follows project conventions
   - [ ] Implements requirements correctly
   - [ ] Handles edge cases appropriately
   - [ ] Includes appropriate error handling

2. **Security Review**
   - [ ] No sensitive data exposed
   - [ ] Input validation implemented
   - [ ] Authentication/authorization respected
   - [ ] No SQL injection or XSS vulnerabilities

3. **Testing Review**
   - [ ] Tests cover new functionality
   - [ ] Edge cases are tested
   - [ ] Tests are maintainable
   - [ ] Test names are descriptive

4. **Documentation Review**
   - [ ] Code is self-documenting
   - [ ] Complex logic is commented
   - [ ] API changes are documented
   - [ ] README updated if needed

## Label Management System

The AI workflow uses an automatic label management system to track task status:

### Label Lifecycle

1. **ai-task** 🟦
   - Applied manually or via issue template
   - Triggers the AI workflow
   - **Automatically removed** after processing

2. **ai-completed** 🟢
   - Added when PR is successfully created
   - Indicates task was implemented and ready for review
   - Remains until issue is closed

3. **ai-no-changes** 🟡
   - Added when AI determines no changes are needed
   - Indicates task was analyzed but no implementation required
   - May happen if request is already implemented or invalid

4. **ai-generated** 🟣
   - Added to PRs created by the AI workflow
   - Helps identify automated contributions
   - Used for tracking and metrics

### Benefits

- **Clear Status Tracking**: Always know the state of AI tasks
- **Prevents Duplicate Processing**: Completed tasks won't be re-triggered
- **Workflow Organization**: Easy filtering and project management
- **Metrics and Reporting**: Track AI workflow success rates

### Manual Label Management

You can manually manage labels if needed:

```bash
# Remove ai-task label to prevent processing
gh issue edit 123 --remove-label "ai-task"

# Re-add to restart processing
gh issue edit 123 --add-label "ai-task"

# View all AI-related issues
gh issue list --label "ai-completed"
```

## Troubleshooting

### Common Issues

### Workflow Not Triggering

- Verify `ai-task` label is applied to the issue
- Check that ANTHROPIC_API_KEY is set in repository secrets
- Ensure GitHub Actions are enabled

### AI Task Fails

- Check GitHub Actions logs for error details
- Verify OpenRouter API key is set correctly
- Check API rate limits and quotas
- Verify Claude Code CLI installation in workflow

### Pull Request Not Created

- Verify workflow permissions are sufficient (GH_PAT only needed for
  cross-workflow triggering)
- Check if branch already exists
- Review GitHub Actions permissions settings

### Manual Trigger

You can manually trigger an AI task by commenting on an issue:

```text
/ai-task
```

## Cost Management

### Monitoring Usage

- Track API calls in OpenRouter dashboard
- Monitor GitHub Actions usage (2000 free minutes/month)
- Set up spending alerts for budget control
- Multiple AI models available (Claude, GPT-4, Gemini)

### Optimization Tips

- Use precise task descriptions to reduce AI iterations
- Break complex tasks into smaller chunks
- Cache common patterns and templates
- Review and optimize prompt templates regularly

## Best Practices

### For Developers

1. **Start Small**: Begin with simple tasks to test the workflow
2. **Be Specific**: Provide detailed requirements and context
3. **Review Thoroughly**: AI-generated code needs careful review
4. **Iterate**: Use feedback to improve task descriptions

### For Teams

1. **Establish Standards**: Define code quality expectations
2. **Train Users**: Ensure team knows how to write effective AI tasks
3. **Monitor Costs**: Track usage and set appropriate limits
4. **Gather Feedback**: Regularly assess AI workflow effectiveness

## Shared Commands System

### NPM Package Distribution

The template now includes a shared commands system distributed as an NPM
package:

- **Package**: `@stillrivercode/shared-commands`
- **Installation**: `npm install -g @stillrivercode/shared-commands`
- **Usage**: `npx @stillrivercode/shared-commands <command>`

### Available Commands

- **analyze-issue**: Analyze existing GitHub issues for requirements and
  complexity
- **create-spec-issue**: Create GitHub issues with detailed technical
  specifications
- **roadmap**: Display or generate project roadmaps with title-based naming and
  automatic template generation

### Automated Publishing

The shared commands are automatically published to NPM via the
`publish-shared-commands.yml` workflow when:

- PRs affecting `shared-commands/` are merged to main
- The PR has the `release` label
- Uses conventional commits to determine version bumps (major/minor/patch)
- Automatically checks if version is already published to prevent duplicates
- Runs tests before publishing to ensure quality
- Pushes git tags back to repository for version tracking

**Required Secrets**:

- `NPM_TOKEN` - NPM authentication token for publishing
- `GH_PAT` - GitHub Personal Access Token for repository operations

## Advanced Usage

### Custom Prompt Templates

Create specialized templates for different task types:

- Feature implementation prompts
- Bug fix investigation prompts
- Refactoring guidelines
- Testing strategy prompts

### Integration with Other Tools

- Connect with project management tools
- Integrate with code quality tools
- Set up notifications for team collaboration

### Metrics and Analytics

Track success metrics:

- Task completion rates
- Review cycle times
- Developer satisfaction
- Code quality improvements

## Getting Help

- **Documentation Issues**: Check the issue templates
- **Workflow Problems**: Review GitHub Actions logs
- **AI Quality**: Improve task descriptions and context
- **Team Adoption**: Provide training and examples

For more advanced features and enterprise setup, see the full
[roadmap documentation](../dev-docs/roadmap.md).
