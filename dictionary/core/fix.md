# FIX

**Category**: Core Commands

**Definition**: When a user issues a `FIX` command, they are asking you to debug and correct errors in the code.

## Example Prompts

- `FIX the 'TypeError' that occurs on line 42 of 'user_controller.js' when the user is not logged in.`
- `FIX the memory leak in the data processing pipeline`
- `FIX the broken authentication flow that's returning 500 errors`

## Expected Output Format

```markdown
# Fix Applied: [Error/Issue Description]

## Problem Summary
Brief description of the issue and its impact.

## Root Cause
Explanation of what was causing the problem.

## Solution Applied
### Changes Made
```javascript
// Before (problematic code)
function problematicFunction() {
  // issue here
}

// After (fixed code)
function fixedFunction() {
  // solution applied
}
```markdown

### Files Modified

- `/path/to/file.ext` - Description of changes
- `/path/to/another.ext` - Description of changes

## Verification

- How to test that the fix works
- Expected behavior after the fix
- Regression testing recommendations

## Prevention

Suggestions to prevent similar issues in the future.

```markdown

## Usage Notes

- Identify the root cause, not just symptoms
- Provide complete, working solutions
- Include proper error handling
- Consider edge cases and side effects

## Fix Categories

- **Syntax Errors**: Typos, missing brackets, etc.
- **Logic Errors**: Incorrect algorithms or flow
- **Runtime Errors**: Null references, type mismatches
- **Performance Issues**: Inefficient code causing slowdowns
- **Security Issues**: Vulnerabilities and unsafe practices

## Related Commands

- [**debug this**](../development/debug-this.md) - For complex debugging scenarios
- [**test this**](../quality-assurance/test-this.md) - Create tests to prevent regression
- [**analyze this**](../development/analyze-this.md) - Analyze code for potential issues
