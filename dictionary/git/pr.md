# pr

**Category**: Git Operations

**Definition**: When a user issues a `pr` command, they are asking you to perform pull request operations using GitHub CLI. This is shorthand for `gh pr` commands.

## Example Prompts

- `pr create a pull request for this feature with comprehensive description`
- `pr list all open pull requests that need review`
- `pr merge this pull request after checks pass`

## Expected Output Format

```markdown
# Pull Request: [Operation Description]

## PR Details
- **Title**: Add user authentication feature
- **Number**: #123
- **Branch**: feature/auth → main
- **Status**: Open
- **URL**: https://github.com/owner/repo/pull/123

## Description
```markdown

This PR implements OAuth2 authentication for the application.

Changes include:

- New login/logout components
- JWT token management
- Protected route middleware
- Comprehensive test coverage

Fixes #456
Closes #789

```markdown

## Command Executed
```bash
gh pr create --title "Add user authentication feature" --body-file pr-description.md
```markdown

## Checks

- **CI Status**: ✅ All checks passing
- **Reviews**: 👥 2 approvals required
- **Mergeable**: ✅ Ready to merge

## Actions Taken

- Created pull request successfully
- Requested reviews from team members
- Added appropriate labels and milestone

```markdown

## Common PR Operations

- **Create**: `gh pr create` - Create new pull request
- **List**: `gh pr list` - List pull requests with filters
- **View**: `gh pr view [number]` - Show PR details
- **Review**: `gh pr review` - Submit pull request review
- **Merge**: `gh pr merge` - Merge approved pull request
- **Close**: `gh pr close` - Close pull request without merging

## PR Creation Best Practices

- Write clear, descriptive titles
- Include comprehensive descriptions with context
- Reference related issues with "Fixes #123" syntax
- Add appropriate labels and reviewers
- Ensure CI checks are configured to run

## Review Process

- Request reviews from appropriate team members
- Respond to feedback promptly
- Update PR based on review comments
- Ensure all checks pass before merging

## Related Commands

- [**push**](push.md) - Push changes before creating PR
- [**gh**](gh.md) - Full GitHub CLI namespace
- [**commit**](commit.md) - Create commits for the PR
- [**comment**](comment.md) - Add comments to PRs
