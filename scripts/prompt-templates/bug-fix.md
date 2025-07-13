# Bug Fix Prompt Template

## Task: Fix Bug

### Bug Details

- **Bug Description**: {BUG_DESCRIPTION}
- **Steps to Reproduce**: {REPRODUCTION_STEPS}
- **Expected Behavior**: {EXPECTED_BEHAVIOR}
- **Actual Behavior**: {ACTUAL_BEHAVIOR}
- **Affected Files**: {AFFECTED_FILES}
- **Error Messages**: {ERROR_MESSAGES}

### Investigation Guidelines

1. **Root Cause Analysis**
   - Identify the underlying cause of the bug
   - Trace the issue through the codebase
   - Check for similar issues in related code
   - Review recent changes that might have introduced the bug

2. **Fix Strategy**
   - Implement the minimal necessary change
   - Avoid introducing breaking changes
   - Ensure fix doesn't create new issues
   - Consider backwards compatibility

3. **Testing Requirements**
   - Write tests that reproduce the bug
   - Verify fix resolves the issue
   - Test related functionality for regressions
   - Add edge case tests to prevent recurrence

4. **Code Quality**
   - Follow existing code patterns
   - Maintain readability and maintainability
   - Add comments explaining complex fixes
   - Remove any debugging code before committing

### Validation Checklist

- [ ] Bug is reproducible and understood
- [ ] Root cause identified
- [ ] Fix implemented with minimal changes
- [ ] Tests added to prevent regression
- [ ] Related functionality tested
- [ ] No new issues introduced
- [ ] Code follows project conventions
- [ ] Documentation updated if needed

### Additional Context

{ADDITIONAL_CONTEXT}
