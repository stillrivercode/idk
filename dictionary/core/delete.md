# DELETE

**Category**: Core Commands

**Definition**: When a user issues a `DELETE` command, they are asking you to remove code, files, or other project assets. You should always ask for confirmation before executing a `DELETE` command.

## Example Prompts

- `DELETE the unused 'old-styles.css' file and remove all references to it from the project.`
- `DELETE the deprecated user authentication functions`
- `DELETE the legacy API endpoints that are no longer used`

## Expected Output Format

```markdown
# Deletion Plan: [Target Description]

## ⚠️ Confirmation Required
**Are you sure you want to proceed with these deletions?** This action cannot be easily undone.

## Items to be Deleted
### Files
- `/path/to/file1.ext` - Reason for deletion
- `/path/to/file2.ext` - Reason for deletion

### Code Sections
- `function oldFunction()` in `/path/to/file.ext:lines` - Reason for deletion

## Impact Analysis
### Direct Impact
- Components that will be affected
- Features that will be removed

### Dependencies
- Files that reference the deleted items
- Required cleanup actions

## Cleanup Actions
1. Remove file references from imports
2. Update configuration files
3. Remove related tests
4. Update documentation

## Verification Steps
- How to confirm deletion was successful
- Tests to run to ensure system stability
```bash

## Usage Notes

- Always request explicit confirmation before deleting
- Identify all dependencies and references
- Provide a comprehensive cleanup plan
- Consider creating backups for important deletions

## Safety Guidelines

- **Never delete without confirmation**
- Analyze impact before proposing deletions
- Suggest alternatives when appropriate
- Recommend version control practices

## Related Commands

- [**analyze this**](../development/analyze-this.md) - Analyze dependencies before deletion
- [**review this**](../quality-assurance/review-this.md) - Review deletion impact
