# SELECT

**Category**: Core Commands

**Definition**: When a user issues a `SELECT` command, they are asking you to find, retrieve, or explain information from the codebase or other resources. This is your primary command for information retrieval.

## Example Prompts

- `SELECT the user authentication logic from the 'auth.py' file and explain how it handles password hashing.`
- `SELECT all functions that handle user input validation`
- `SELECT the database connection configuration and explain the security settings`

## Expected Output Format

```markdown
# Selected Information: [Target Description]

## Location
- **File(s)**: Path references with line numbers
- **Function/Class**: Specific code elements identified

## Code Extract
```javascript
// Relevant code with annotations
```markdown

## Explanation

Clear explanation of what the code does, how it works, and any important considerations.

## Related Components

- Other files or functions that interact with this code
- Dependencies and relationships

```markdown

## Usage Notes

- Always provide file paths and line numbers when possible
- Include context about how the selected code fits into the larger system
- Explain any security, performance, or architectural implications

## Related Commands

- [**explain this**](../documentation/explain-this.md) - For detailed explanations of selected code
- [**analyze this**](../development/analyze-this.md) - For deeper analysis of selected components
