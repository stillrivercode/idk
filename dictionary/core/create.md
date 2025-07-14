# CREATE

**Category**: Core Commands

**Definition**: When a user issues a `CREATE` command, they are asking you to generate new code, files, or other project assets.

## Example Prompts

- `CREATE a new React component called 'LoginButton' with a click handler that calls the 'handleLogin' function.`
- `CREATE a database migration script to add user preferences table`
- `CREATE unit tests for the authentication service`

## Expected Output Format

```markdown
# Created: [Asset Description]

## Files Created
- **Path**: `/path/to/new/file.ext`
- **Type**: [Component/Service/Test/Migration/etc.]

## Implementation
```javascript
// Complete code implementation with comments
```markdown

## Integration Notes

- How this integrates with existing code
- Dependencies that need to be installed
- Configuration changes required

## Next Steps

- Suggested follow-up actions
- Testing recommendations
- Documentation updates needed

```markdown

## Usage Notes

- Follow existing project conventions and patterns
- Include necessary imports and dependencies
- Provide complete, functional implementations
- Consider error handling and edge cases

## Related Commands

- [**test this**](../quality-assurance/test-this.md) - Generate tests for created code
- [**document this**](../documentation/document-this.md) - Document newly created components
