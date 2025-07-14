# analyze this

**Category**: Development Commands

**Definition**: When a user issues an `analyze this` command, they are asking you to examine code, system architecture, or a specific component to identify patterns, potential issues, and suggest improvements. Provide a thorough analysis with actionable insights.

## Example Prompts

- `analyze this authentication flow for security vulnerabilities`
- `analyze this database schema for performance bottlenecks`
- `analyze this React component for code smells`

## Expected Output Format

```markdown
# Analysis Report: [Component/System Name]

## Summary of Findings
High-level overview of the analysis including key observations and overall assessment.

## Potential Issues
### Security
- List of security concerns with severity levels

### Performance
- Performance bottlenecks and inefficiencies

### Code Quality
- Code smells, maintainability issues, and design problems

### Architecture
- Structural concerns and design pattern violations

## Actionable Recommendations
### High Priority
- Critical fixes with code examples where applicable

### Medium Priority
- Important improvements with implementation guidance

### Low Priority
- Nice-to-have enhancements and optimizations

## Conclusion
Summary of next steps and overall recommendations for improvement.
```markdown

## Analysis Categories

- **Security Analysis**: Vulnerabilities, authentication, authorization
- **Performance Analysis**: Bottlenecks, inefficiencies, scalability
- **Code Quality**: Maintainability, readability, design patterns
- **Architecture**: Structure, dependencies, separation of concerns

## Usage Notes

- Provide specific, actionable recommendations
- Include severity levels for identified issues
- Reference best practices and industry standards
- Consider the broader system context

## Related Commands

- [**debug this**](debug-this.md) - For specific issue investigation
- [**optimize this**](optimize-this.md) - For performance improvements
- [**review this**](../quality-assurance/review-this.md) - For code review analysis
