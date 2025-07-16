# document this

**Category**: Documentation Commands

**Definition**: When a user issues a `document this` command, they are asking you to create comprehensive documentation including purpose, usage, examples, and API references where applicable. The documentation should be saved as a markdown file in the `docs/` directory with a descriptive filename.

## Example Prompts

- `document this API endpoint with request/response examples`
- `document this React component with props and usage examples`
- `document this configuration file with all available options`

## Expected Output Format

```markdown
# Documentation: [Component/Feature Name]

## Overview
Brief description of purpose and functionality.

## Usage
### Basic Usage
- Simple usage examples with code snippets
- Common use cases

### Advanced Usage
- Complex scenarios and configurations
- Integration patterns

## API Reference
### Parameters/Props
| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| param1 | string | Yes | - | Description of parameter |

### Methods/Functions
#### methodName(parameters)
- **Description**: What the method does
- **Parameters**: Detailed parameter descriptions
- **Returns**: Return value description
- **Example**: Code example

## Examples
### Example 1: [Scenario Name]
```javascript
// Code example with comments
```markdown

### Example 2: [Scenario Name]

```javascript
// Another code example
```markdown

## Notes

- Important considerations
- Limitations or known issues
- Related documentation links

```markdown

## Documentation Types

- **API Documentation**: Endpoints, parameters, responses
- **Component Documentation**: Props, methods, usage patterns
- **Configuration Documentation**: Settings, options, environment variables
- **Process Documentation**: Workflows, procedures, guidelines
- **Architecture Documentation**: System design, components, relationships

## Documentation Standards

- **Clear Structure**: Logical organization with consistent headings
- **Complete Examples**: Working code samples that can be copied
- **Accurate Information**: Up-to-date and tested content
- **User-Focused**: Written from the user's perspective
- **Searchable**: Good use of keywords and cross-references

## Best Practices

- Include both basic and advanced examples
- Provide troubleshooting sections for common issues
- Use consistent formatting and terminology
- Add diagrams or screenshots when helpful
- Keep documentation close to the code it describes
- Save documentation as `.md` files in `docs/` directory
- Use descriptive filenames (e.g., `api-authentication-guide.md`)
- Organize into subdirectories for complex projects (e.g., `docs/api/`, `docs/components/`)
- Create the `docs/` directory if it doesn't exist

## Related Commands

- [**explain this**](explain-this.md) - Provide detailed explanations
- [**research this**](research-this.md) - Gather background information
