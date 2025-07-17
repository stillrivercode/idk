# Information Dense Keywords Dictionary

This document serves as an index to a comprehensive vocabulary of commands for AI assistants in software development. Each command compresses common prompts into memorable keywords that save time and improve consistency.

## Command Chaining

Commands can be chained together to create complex workflows. When chaining commands, separate them with "then" or "and" to indicate sequential or parallel operations.

### Chaining Examples

**Sequential Chain**:
`analyze this authentication system then spec this improved version then plan this implementation`

**Parallel Operations**:
`test this user service and document this API endpoint`

**Complex Workflow**:
`debug this performance issue then optimize this query then test this solution and document this change`

---

## Core Commands

Basic operations that form the foundation of the command vocabulary.

- [**SELECT**](dictionary/core/select.md) - Find, retrieve, or explain information from codebase
- [**CREATE**](dictionary/core/create.md) - Generate new code, files, or project assets
- [**DELETE**](dictionary/core/delete.md) - Remove code, files, or project assets (with confirmation)
- [**FIX**](dictionary/core/fix.md) - Debug and correct errors in code

## Git Operations

Commands for version control and GitHub interactions.

- [**gh**](dictionary/git/gh.md) - GitHub CLI namespace for GitHub operations
- [**commit**](dictionary/git/commit.md) - Create git commits with well-formatted messages
- [**push**](dictionary/git/push.md) - Push changes to remote repository
- [**pr**](dictionary/git/pr.md) - Pull request operations (shorthand for `gh pr`)
- [**comment**](dictionary/git/comment.md) - Add comments to GitHub issues or pull requests

## Development Commands

Commands for code analysis, debugging, and optimization.

- [**analyze this**](dictionary/development/analyze-this.md) - Examine code/architecture for patterns and issues
- [**debug this**](dictionary/development/debug-this.md) - Investigate issues and provide root cause solutions
- [**optimize this**](dictionary/development/optimize-this.md) - Improve performance and efficiency

## Documentation Commands

Commands for creating and maintaining project documentation.

- [**document this**](dictionary/documentation/document-this.md) - Create comprehensive documentation with examples
- [**explain this**](dictionary/documentation/explain-this.md) - Provide clear, structured explanations
- [**research this**](dictionary/documentation/research-this.md) - Investigate and gather comprehensive information

## Quality Assurance Commands

Commands for testing and code review.

- [**test this**](dictionary/quality-assurance/test-this.md) - Generate comprehensive test suites
- [**review this**](dictionary/quality-assurance/review-this.md) - Perform thorough code reviews

## Workflow Commands

Commands for project planning and specification.

- [**plan this**](dictionary/workflow/plan-this.md) - Break down complex tasks into implementation plans
- [**spec this**](dictionary/workflow/spec-this.md) - Create detailed technical specifications
- [**roadmap**](dictionary/workflow/roadmap.md) - Create strategic development roadmaps with phases and milestones

---

## Quick Reference

| Command          | Purpose                           | Category           |
|------------------|-----------------------------------|--------------------|
| **SELECT**       | Information retrieval             | Core               |
| **CREATE**       | Generate new assets               | Core               |
| **DELETE**       | Remove assets                     | Core               |
| **FIX**          | Debug and correct                 | Core               |
| **analyze this** | Code analysis                     | Development        |
| **debug this**   | Issue investigation               | Development        |
| **optimize this**| Performance improvement           | Development        |
| **document this**| Create documentation              | Documentation      |
| **explain this** | Provide explanations              | Documentation      |
| **research this**| Investigate topics                | Documentation      |
| **test this**    | Generate tests                    | Quality Assurance  |
| **review this**  | Code review                       | Quality Assurance  |
| **plan this**    | Implementation planning           | Workflow           |
| **spec this**    | Technical specifications          | Workflow           |
| **roadmap**      | Strategic development roadmaps    | Workflow           |
| **gh**           | GitHub operations                 | Git                |
| **commit**       | Git commits                       | Git                |
| **push**         | Push to remote                    | Git                |
| **pr**           | Pull requests                     | Git                |
| **comment**      | GitHub comments                   | Git                |

---

## Contributing

To add or modify commands:

1. Add new commands to the appropriate `dictionary/` subdirectory
2. Update this index file with a link to the new command
3. Follow the established format for command definitions
4. Include comprehensive Expected Output Formats

## Dictionary Structure

```bash
dictionary/
├── core/                    # Core CRUD operations
├── development/            # Development and analysis commands
├── documentation/          # Documentation commands
├── quality-assurance/      # Testing and review commands
├── workflow/              # Planning and specification commands
└── git/                   # Git and GitHub operations
```bash
