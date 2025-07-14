# gh

**Category**: Git Operations

**Definition**: When a user issues a `gh` command, they are asking you to perform GitHub CLI operations such as managing issues, pull requests, repositories, and other GitHub-specific tasks.

## Example Prompts

- `gh create a new issue titled "Fix authentication bug" with the bug label`
- `gh list all open pull requests in this repository`
- `gh check the status of GitHub Actions workflows`

## Expected Output Format

```markdown
# GitHub Operation: [Operation Description]

## Command Executed
```bash
gh issue create --title "Fix authentication bug" --label bug --assignee @username
```markdown

## Results

- **Status**: Success
- **Output**: Issue #123 created successfully
- **URL**: <https://github.com/owner/repo/issues/123>

## Issue Details

```markdown
Title: Fix authentication bug
Number: #123
State: Open
Assignee: @username
Labels: bug
Created: 2024-01-15 10:30:00
```markdown

## Follow-up Actions

- Add detailed description and reproduction steps
- Link to related pull requests when available
- Monitor progress and update status as needed

```markdown

## Common Operations

- **Issues**: Create, list, view, close GitHub issues
- **Pull Requests**: Create, list, merge, review pull requests
- **Repositories**: Clone, fork, create repositories
- **Actions**: Check workflow status, view logs
- **Releases**: Create and manage releases

## Usage Notes

- Requires GitHub CLI installation and authentication
- Operates on the current repository context when applicable
- Can target specific repositories with owner/repo syntax
- Supports both interactive and non-interactive modes

## Related Commands

- [**commit**](commit.md) - Create commits before pushing
- [**push**](push.md) - Push changes before creating PRs
- [**pr**](pr.md) - Shorthand for GitHub pull request operations
