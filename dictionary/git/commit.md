# commit

**Category**: Git Operations

**Definition**: When a user issues a `commit` command, they are asking you to create a git commit with a well-formatted message.

## Example Prompts

- `commit the current staged changes with a conventional commit message of type 'feat' and the scope 'auth'. The message should describe the addition of the new login button.`
- `commit these bug fixes with appropriate commit message`
- `commit the refactoring changes with descriptive message`

## Expected Output Format

```markdown
# Git Commit Created

Complete summary of the git commit operation including message, files, and verification status.

## Commit Message

```text

feat(auth): add new login button component

- Implement LoginButton React component with click handler
- Add authentication flow integration
- Include proper error handling and loading states

Fixes #123

```

## Files Included

- `src/components/LoginButton.jsx` - New login button component
- `src/services/auth.js` - Updated authentication service
- `src/styles/components.css` - Button styling

## Commit Details

- **Branch**: feature/auth-improvements
- **Hash**: `abc123def456`
- **Author**: Developer Name
- **Files Changed**: 3 modified, 1 added

## Pre-commit Checks

✅ Tests passed
✅ Linting successful
✅ Build completed
✅ No conflicts detected

```

## Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/) specification:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: New features
- **fix**: Bug fixes
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Build process or auxiliary tool changes

### Examples

- `feat(auth): implement OAuth2 login flow`
- `fix(api): resolve null reference in user endpoint`
- `docs(readme): update installation instructions`
- `refactor(utils): extract common validation functions`

## Best Practices

- Keep the first line under 50 characters
- Use imperative mood ("add" not "added")
- Include scope when applicable
- Provide detailed body for complex changes
- Reference issue numbers when relevant

## Related Commands

- [**push**](push.md) - Push commits to remote repository
- [**pr**](pr.md) - Create pull requests with commits
