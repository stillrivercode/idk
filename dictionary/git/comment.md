# comment

**Category**: Git Operations

**Definition**: When a user issues a `comment` command, they are asking you to add comments to GitHub issues or pull requests using the GitHub CLI.

## Example Prompts

- `comment on this pull request with feedback about the implementation`
- `comment on issue #42 asking for more details about the bug`
- `comment with approval and merge suggestion`

## Expected Output Format

```markdown
# GitHub Comment: [Target Description]

## Target
- **Type**: Issue/Pull Request
- **Number**: #123
- **Title**: Target title
- **URL**: GitHub URL

## Comment Added
```markdown

Comment content with proper formatting

This addresses the concerns raised in the code review.
The implementation follows our team's coding standards.

@reviewer-name please review when convenient.

```markdown

## Command Executed
```bash
gh issue comment 123 --body "Your comment text here"
```markdown

## Status

- **Posted**: Successfully
- **Visibility**: Public comment on the thread
- **Notifications**: Sent to subscribers

```markdown

## Comment Types

- **General Comments**: Questions, suggestions, status updates
- **Review Comments**: Code-specific feedback on pull requests
- **Approval Comments**: LGTM, approval with suggestions
- **Request Changes**: Comments requesting modifications
- **Status Updates**: Progress reports, blockers, resolutions

## Comment Best Practices

- Be clear and constructive in feedback
- Use proper markdown formatting for code snippets
- Reference specific lines or files when relevant
- Tag relevant team members with @mentions
- Include actionable suggestions when possible

## GitHub Mentions and References

- **Users**: @username to notify specific people
- **Issues**: #123 to reference other issues/PRs
- **Commits**: SHA references for specific commits
- **Code**: Use backticks for inline code or triple backticks for blocks

## Usage Notes

- Comments are immediately visible to all repository watchers
- Can trigger email notifications to subscribed users
- Supports full GitHub Flavored Markdown
- Can include attachments and images

## Related Commands

- [**pr**](pr.md) - Pull request operations that may need comments
- [**gh**](gh.md) - Full GitHub CLI namespace for issue management
