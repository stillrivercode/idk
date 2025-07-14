# debug this

**Category**: Development Commands

**Definition**: When a user issues a `debug this` command, they are asking you to investigate an issue, trace the problem to its root cause, and provide a solution. Include explanations of why the issue occurs and how the fix addresses it.

## Example Prompts

- `debug this TypeError in the user registration flow`
- `debug this performance issue in the data processing pipeline`
- `debug this intermittent test failure`

## Expected Output Format

```markdown
# Debug Report: [Issue Description]

Systematic analysis of the issue with root cause identification and solution implementation.

## Problem Summary
Brief description of the issue and its symptoms.

## Root Cause Analysis
### Investigation Steps
- Step-by-step debugging process followed
- Evidence gathered and tools used

### Root Cause
Clear explanation of what's causing the issue and why it occurs.

## Solution
### Proposed Fix
- Detailed solution with code changes
- Explanation of how the fix addresses the root cause

### Alternative Approaches
- Other potential solutions considered
- Trade-offs and reasons for choosing the proposed fix

## Testing & Verification
- How to verify the fix works
- Test cases to prevent regression

## Prevention
Recommendations to avoid similar issues in the future.
```markdown

## Debugging Techniques

- **Log Analysis**: Examining application logs and error messages
- **Stack Trace Analysis**: Following execution paths and call stacks
- **Data Flow Tracing**: Tracking data through the system
- **Timing Analysis**: Identifying race conditions and timing issues
- **Memory Analysis**: Detecting leaks and allocation problems

## Common Issue Categories

- **Runtime Errors**: Null references, type mismatches, exceptions
- **Logic Errors**: Incorrect algorithms, conditional logic flaws
- **Integration Issues**: API failures, database connection problems
- **Performance Issues**: Slow queries, memory leaks, infinite loops
- **Concurrency Issues**: Race conditions, deadlocks, thread safety

## Usage Notes

- Start with reproducing the issue
- Gather comprehensive diagnostic information
- Use systematic elimination to isolate the problem
- Provide complete solutions, not just patches

## Related Commands

- [**analyze this**](analyze-this.md) - For broader code analysis
- [**fix**](../core/fix.md) - Apply simple fixes to known issues
- [**test this**](../quality-assurance/test-this.md) - Create tests to prevent regression
