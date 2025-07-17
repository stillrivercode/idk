# Information Dense Keywords Dictionary

A comprehensive, modular dictionary of commands for AI assistants in software development. This repository provides a shared, efficient vocabulary that makes human-AI collaboration more productive and consistent.

## 🎯 What You Get

A curated collection of action-oriented keywords organized in a modular structure. Each command compresses common prompts into memorable keywords with comprehensive definitions and expected output formats.

**Key Features:**

- 📚 **20+ command definitions** across Core, Development, Documentation, QA, Workflow, and Git categories
- 🏗️ **Modular architecture** with organized `dictionary/` structure for easy navigation
- 🔗 **Command chaining** support for complex workflows
- 📋 **Expected Output Formats** for consistent, predictable results
- 🔧 **GitHub integration** with automated workflows and validation
- 🛡️ **Quality assurance** with security scanning and emergency controls

## 📦 Installation & Updates

### Individual Users

```bash
# Install dictionary to docs/ directory
npx @stillrivercode/information-dense-keywords

# Or install to custom directory
npx @stillrivercode/information-dense-keywords /path/to/custom/docs

# Show help
npx @stillrivercode/information-dense-keywords --help
```

### Teams & Organizations

Add to your project's `package.json`:

```json
{
  "dependencies": {
    "@stillrivercode/information-dense-keywords": "^1.0.0"
  },
  "scripts": {
    "idk:install": "npx @stillrivercode/information-dense-keywords",
    "idk:update": "npm update @stillrivercode/information-dense-keywords"
  }
}
```

Then run:

```bash
npm install
npm run idk:install
```

### AI Assistant Configuration

When you run the installer, a file named `AI.md` is copied to your installation directory (e.g., `docs/AI.md`). This file contains shared instructions and context for any AI assistant you use, ensuring it understands the project's conventions and the "Information Dense Keywords" command set.

You are encouraged to customize this file with project-specific details.

## 📋 Quick Reference

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

## 🚀 Quick Start Examples

### Basic Commands

```bash
SELECT the authentication logic from auth.py
CREATE a React login component
FIX the validation error in user registration
DELETE the unused styling files
```

### Advanced Commands

```bash
analyze this database schema for performance issues
debug this memory leak in the payment processor
optimize this query that's taking 10 seconds
test this user service with comprehensive unit tests
review this pull request for security vulnerabilities
```

### Command Chaining

```bash
research this OAuth2 patterns then spec this authentication system then plan this implementation
analyze this API performance then optimize this bottleneck then test this solution
```

## 📁 Dictionary Structure

```text
information-dense-keywords.md     # Main index with links to all commands
dictionary/
├── core/                        # SELECT, CREATE, DELETE, FIX
├── development/                 # analyze this, debug this, optimize this
├── documentation/               # document this, explain this, research this
├── quality-assurance/          # test this, review this
├── workflow/                   # plan this, spec this
└── git/                       # commit, push, pr, gh, comment
```

## 🎓 Learning Path

1. **Start with Core Commands**: Master SELECT, CREATE, DELETE, FIX
2. **Explore by Category**: Pick a category that matches your workflow
3. **Practice Command Chaining**: Combine commands for complex tasks
4. **Customize for Your Team**: Add domain-specific commands as needed

## 💡 Usage Tips

- **Be Specific**: `analyze this authentication flow for security vulnerabilities` vs `analyze this`
- **Chain Logically**: Use "then" for sequential operations, "and" for parallel
- **Reference Files**: Include file paths and line numbers when possible
- **Use Expected Formats**: Each command specifies its expected output structure

## 🤝 Contributing

We welcome contributions! Here's how to help:

1. **Add New Commands**: Create files in appropriate `dictionary/` subdirectories
2. **Improve Definitions**: Enhance existing command documentation
3. **Report Issues**: Use GitHub issues for bugs or feature requests
4. **Share Usage Patterns**: Help us understand how teams use the dictionary

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 🔗 Related Resources

- [AI Usage Guide](examples/ai-usage-guide.md) - Detailed implementation guidance
- [Command Definitions](information-dense-keywords.md) - Complete command index
- [Architecture Decision Records](adrs/) - Design decisions and evolution
- [Roadmap](docs/roadmaps/) - Future development plans

## 📄 License

MIT License - free for personal and commercial use.
