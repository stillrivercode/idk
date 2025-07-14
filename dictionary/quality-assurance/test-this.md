# test this

**Category**: Quality Assurance Commands

**Definition**: When a user issues a `test this` command, they are asking you to generate appropriate tests including unit tests, integration tests, or end-to-end tests as needed. Include edge cases and error scenarios.

## Example Prompts

- `test this user service with unit tests covering all methods`
- `test this API endpoint with integration tests`
- `test this React component with various prop combinations`

## Expected Output Format

```markdown
# Test Suite: [Component/Feature Name]

## Test Strategy
- **Test Types**: Unit/Integration/E2E tests planned
- **Coverage Goals**: What functionality will be tested
- **Test Framework**: Recommended testing tools and setup

## Test Cases

### Happy Path Tests
```javascript
describe('[Component Name] - Happy Path', () => {
  test('should handle normal operation correctly', () => {
    // Test implementation
  });
});
```markdown

### Edge Cases

```javascript
describe('[Component Name] - Edge Cases', () => {
  test('should handle empty input gracefully', () => {
    // Test implementation
  });

  test('should handle maximum input values', () => {
    // Test implementation
  });
});
```markdown

### Error Scenarios

```javascript
describe('[Component Name] - Error Handling', () => {
  test('should throw appropriate error for invalid input', () => {
    // Test implementation
  });
});
```markdown

## Test Data & Mocks

- Sample data for testing
- Mock setup requirements
- Test environment configuration

## Coverage Report

- Expected coverage metrics
- Areas requiring special attention
- Integration points to verify

```markdown

## Test Types

- **Unit Tests**: Test individual functions/methods in isolation
- **Integration Tests**: Test component interactions and data flow
- **End-to-End Tests**: Test complete user workflows
- **Performance Tests**: Test response times and resource usage
- **Security Tests**: Test authentication, authorization, input validation

## Testing Frameworks

### JavaScript/TypeScript
- **Jest**: Unit and integration testing
- **React Testing Library**: React component testing
- **Cypress**: End-to-end testing
- **Playwright**: Cross-browser testing

### Python
- **pytest**: Unit and integration testing
- **unittest**: Built-in testing framework
- **Selenium**: Web application testing

### Other Languages
- **JUnit** (Java), **NUnit** (C#), **RSpec** (Ruby), **Go test** (Go)

## Test Best Practices

- **AAA Pattern**: Arrange, Act, Assert
- **Descriptive Names**: Test names should explain what's being tested
- **Single Responsibility**: One assertion per test when possible
- **Independent Tests**: Tests should not depend on each other
- **Mock External Dependencies**: Isolate code under test

## Coverage Guidelines

- Aim for 80%+ code coverage
- Focus on critical business logic
- Test both success and failure paths
- Include boundary value testing
- Test error handling and edge cases

## Related Commands

- [**debug this**](../development/debug-this.md) - Debug failing tests
- [**review this**](review-this.md) - Review test quality and coverage
