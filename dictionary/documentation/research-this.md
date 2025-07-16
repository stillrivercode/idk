# research this

**Category**: Documentation Commands

**Definition**: When a user issues a `research this` command, they are asking you to investigate and gather comprehensive
information about a topic, technology, pattern, or concept. This includes collecting information from multiple sources,
analyzing current best practices, and providing a thorough research summary. The research should be saved as a markdown
file in the `docs/research/` directory with a descriptive filename.

## Example Prompts

- `research this OAuth2 implementation patterns for microservices`
- `research this React state management solutions for large applications`
- `research this database indexing strategies for time-series data`
- `research this security best practices for API authentication`

## Expected Output Format

```markdown
# Research Report: [Topic/Technology Name]

## Executive Summary
High-level overview of the research findings and key insights.

## Background & Context
- What this technology/pattern/concept is
- Why it's important or relevant
- Current industry adoption and trends

## Key Findings
### Approach 1: [Method/Tool/Pattern Name]
- **Description**: What it is and how it works
- **Pros**: Advantages and benefits
- **Cons**: Limitations and drawbacks
- **Use Cases**: When to use this approach
- **Examples**: Real-world implementations

### Approach 2: [Method/Tool/Pattern Name]
- **Description**: What it is and how it works
- **Pros**: Advantages and benefits
- **Cons**: Limitations and drawbacks
- **Use Cases**: When to use this approach
- **Examples**: Real-world implementations

## Best Practices
- Industry-standard recommendations
- Common pitfalls to avoid
- Implementation guidelines
- Performance considerations

## Comparison Matrix
| Criteria | Approach 1 | Approach 2 | Approach 3 |
|----------|------------|------------|------------|
| Performance | High | Medium | Low |
| Complexity | Low | High | Medium |
| Maintenance | Easy | Complex | Moderate |

## Recommendations
### For Small Projects
- Recommended approach with rationale

### For Medium Projects
- Recommended approach with rationale

### For Large/Enterprise Projects
- Recommended approach with rationale

## Implementation Resources
- Official documentation links
- Tutorials and guides
- Code examples and repositories
- Community resources and forums

## Conclusion
Summary of key takeaways and next steps for implementation.
```markdown

## Research Categories

- **Technology Research**: Frameworks, libraries, tools
- **Pattern Research**: Design patterns, architectural patterns
- **Best Practice Research**: Industry standards, methodologies
- **Security Research**: Vulnerabilities, security practices
- **Performance Research**: Optimization techniques, benchmarking

## Research Sources

- **Official Documentation**: Authoritative source material
- **Industry Publications**: Technical blogs, whitepapers
- **Community Resources**: Stack Overflow, GitHub, forums
- **Academic Papers**: Research studies and analyses
- **Case Studies**: Real-world implementation examples

## Research Process

1. **Define Scope**: Clarify what specifically needs to be researched
2. **Gather Sources**: Collect information from multiple reliable sources
3. **Analyze & Compare**: Evaluate different approaches and solutions
4. **Synthesize**: Combine findings into coherent recommendations
5. **Validate**: Cross-reference information for accuracy

## Usage Notes

- Always cite sources and provide links when possible
- Focus on current, up-to-date information
- Include practical implementation considerations
- Provide balanced analysis of pros and cons
- Consider the specific context and requirements
- Save research as `.md` files in `docs/research/` directory
- Use descriptive filenames (e.g., `oauth2-microservices-patterns.md`)
- Create the `docs/research/` directory if it doesn't exist

## Related Commands

- [**analyze this**](../development/analyze-this.md) - Analyze specific implementations
- [**document this**](document-this.md) - Document research findings
- [**spec this**](../workflow/spec-this.md) - Create specifications based on research
