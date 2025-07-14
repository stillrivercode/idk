# Contributing to Information Dense Keywords Dictionary

Thank you for your interest in contributing to the IDK project! This dictionary aims to create a shared vocabulary for efficient human-AI collaboration in software development.

## 🎯 Project Goals

- Create action-oriented keywords that AI assistants can understand consistently
- Develop a natural language syntax for common development tasks
- Maintain clarity and efficiency in human-AI communication

## 📝 How to Contribute

### 1. Dictionary Entries

The core dictionary is in [`information-dense-keywords.md`](information-dense-keywords.md). When adding or modifying commands:

- **Be Clear**: Each command should have an unambiguous definition
- **Provide Examples**: Include realistic example prompts showing usage
- **Follow Format**: Use the established structure with Definition and Example sections
- **Consider Scope**: Ensure commands are generally applicable, not project-specific

### 2. Documentation

- Update the [AI Usage Guide](examples/ai-usage-guide.md) when adding new patterns
- Keep examples realistic and practical
- Ensure documentation reflects current dictionary state

### 3. AI Instructions

- [`AI.md`](AI.md) contains shared instructions for all AI assistants
- [`CLAUDE.md`](CLAUDE.md) and [`GEMINI.md`](GEMINI.md) contain model-specific guidance
- Update these files when dictionary changes affect AI behavior

## 🔧 Development Workflow

1. **Fork and Clone**: Fork the repository and clone your fork
2. **Create Branch**: Use conventional branch names with prefixes:
   - `feat/` for new features: `feat/database-commands`
   - `fix/` for bug fixes: `fix/definition-clarity`
   - `docs/` for documentation: `docs/usage-examples`
   - `refactor/` for refactoring: `refactor/command-structure`
3. **Make Changes**: Edit the dictionary or documentation
4. **Test Changes**: Run `npm test` to validate markdown formatting
5. **Commit**: Use conventional commit messages (e.g., `feat: add DATABASE command set`)
6. **Submit PR**: Create a pull request with a clear description

## ✅ Quality Standards

### Command Definitions

- **Actionable**: Commands should trigger specific behaviors
- **Consistent**: Similar commands should follow similar patterns
- **Complete**: Include all necessary context for AI understanding

### Code Quality

```bash
# Lint markdown files
npm run lint:markdown

# Format all files
npm run format

# Check formatting
npm run format:check

# Run all tests
npm test
```

### Examples

Good command definition:

```markdown
### CREATE

**Definition**: When a user issues a `CREATE` command, they are asking you to generate new code, files, or other project assets.

**Example Prompt**:
`CREATE a new React component called 'LoginButton' with a click handler that calls the 'handleLogin' function.`
```

## 🚀 Submitting Changes

1. **Pull Request Title**: Use conventional commit format
   - `feat: add new command set for database operations`
   - `fix: clarify SELECT command definition`
   - `docs: update usage examples`

2. **PR Description**: Include:
   - What commands/changes you're adding
   - Why these changes are needed
   - Any breaking changes or considerations

3. **Review Process**:
   - Maintainers will review for clarity and consistency
   - May request changes to align with project goals
   - Focus on creating a cohesive vocabulary

## 🐛 Reporting Issues

- Use GitHub Issues for bugs, suggestions, or questions
- Include specific examples when reporting unclear definitions
- Tag issues appropriately (enhancement, bug, documentation)

## 📚 Resources

- [AI Usage Guide](examples/ai-usage-guide.md) - How AIs should use the dictionary
- [Project Roadmap](docs/roadmaps/ROADMAP.md) - Future development plans
- [ADRs](adrs/) - Architectural decision records

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Questions? Feel free to open an issue or start a discussion!
