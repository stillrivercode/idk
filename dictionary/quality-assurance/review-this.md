# review this

**Category**: Quality Assurance Commands

**Definition**: When a user issues a `review this` command, they are asking you to perform a comprehensive code review including analysis of code quality, security, performance, maintainability, and adherence to best practices.

## Example Prompts

- `review this pull request for security vulnerabilities and code quality`
- `review this module for performance issues and optimization opportunities`
- `review this API implementation for proper error handling and documentation`

## Expected Output Format

```markdown
# Code Review: [Component/File Name]

Brief overview of findings and recommendations from the comprehensive code review.

## Summary
Brief overview of the review scope and overall assessment

## Findings

### ✅ Strengths
- Well-implemented patterns and good practices found
- Security measures properly implemented
- Performance optimizations noted

### ⚠️ Issues Found
- **High Priority**: Critical issues requiring immediate attention
- **Medium Priority**: Important improvements recommended
- **Low Priority**: Minor suggestions and style improvements

### 🔧 Recommendations
1. Specific actionable improvements
2. Best practice suggestions
3. Architectural considerations

## Code Examples

```javascript
// Example of reviewed code with annotations
function authenticateUser(credentials) {
  // ✅ Good: Input validation
  if (!credentials || !credentials.username) {
    throw new Error('Invalid credentials');
  }
  // ⚠️ Issue: Plain text credential comparison
  return credentials.secret === 'hardcoded'; // SECURITY RISK  # pragma: allowlist secret
}
```

## Security Review

- Authentication and authorization checks
- Input validation and sanitization
- Sensitive data handling
- Vulnerability assessment

## Performance Review

- Algorithmic complexity analysis
- Resource usage patterns
- Bottleneck identification
- Scalability considerations

## Code Quality

- Readability and maintainability
- Test coverage assessment
- Documentation completeness
- Code organization and structure

## Compliance

- Coding standards adherence
- Team conventions compliance
- Industry best practices

```

## Review Categories

- **Security Review**: Focus on vulnerabilities, authentication, data protection
- **Performance Review**: Analyze speed, memory usage, scalability
- **Quality Review**: Code structure, readability, maintainability
- **Architecture Review**: Design patterns, modularity, extensibility
- **Compliance Review**: Standards, conventions, regulatory requirements

## Review Methodology

1. **Static Analysis**: Code structure and pattern analysis
2. **Security Scanning**: Vulnerability and threat assessment
3. **Performance Analysis**: Bottleneck and optimization opportunities
4. **Best Practices**: Industry standards and team conventions
5. **Documentation**: Comments, README, and API documentation

## Review Criteria

- **Functionality**: Does the code work as intended?
- **Reliability**: Is the code robust and error-resistant?
- **Security**: Are there security vulnerabilities?
- **Performance**: Is the code efficient and scalable?
- **Maintainability**: Is the code easy to understand and modify?
- **Testability**: Is the code well-covered by tests?

## Related Commands

- [**test this**](test-this.md) - Generate tests for reviewed code
- [**debug this**](../development/debug-this.md) - Debug issues found in review
- [**analyze this**](../development/analyze-this.md) - Deep analysis of reviewed components
