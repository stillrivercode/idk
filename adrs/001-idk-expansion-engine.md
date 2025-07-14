# ADR 001: IDK Dictionary Architecture Evolution

**Status**: Superseded by Modular Architecture

**Context**:

The project has evolved through several iterations:

1. A collection of structured YAML files.
2. A CLI tool with a programmatic syntax (`expand Keyword[param=value]`).
3. A CLI tool with a natural language syntax (`SELECT Keyword with feature`).
4. **[Previous]** A single, well-structured Markdown file named `information-dense-keywords.md`.
5. **[Current]** A modular dictionary with an index file and organized command definitions.

The single-file approach served well initially but became unwieldy as the dictionary grew. With comprehensive Expected Output Formats and detailed definitions, the file became too large for easy navigation and maintenance.

**Updated Decision**:

We will restructure the project to use a **modular dictionary architecture**:

- `information-dense-keywords.md` becomes an **index** with links to command definitions
- Individual command definitions are stored in `dictionary/` subdirectories organized by category
- Each command gets its own markdown file with complete definition, examples, and expected output format

**New Structure**:

```yaml
information-dense-keywords.md          # Index with links
dictionary/
├── core/                             # Core CRUD operations
│   ├── select.md
│   ├── create.md
│   ├── delete.md
│   └── fix.md
├── development/                      # Development commands
│   ├── analyze-this.md
│   ├── debug-this.md
│   └── optimize-this.md
├── documentation/                    # Documentation commands
│   ├── document-this.md
│   └── explain-this.md
├── quality-assurance/               # QA commands
│   ├── test-this.md
│   └── review-this.md
├── workflow/                        # Workflow commands
│   ├── plan-this.md
│   └── spec-this.md
└── git/                            # Git operations
    ├── commit.md
    ├── push.md
    ├── pr.md
    └── gh.md
```yaml

**Benefits of Modular Architecture**:

- **Maintainability**: Each command can be edited independently
- **Scalability**: Easy to add new commands without bloating the index
- **Navigation**: Quick reference via index, detailed definitions in dedicated files
- **Organization**: Logical grouping by functionality
- **Collaboration**: Multiple contributors can work on different commands simultaneously
- **Reusability**: Individual command definitions can be referenced or imported separately

**Consequences**:

- Improved organization and maintainability of the growing dictionary
- Better separation of concerns between overview (index) and detailed definitions
- Enhanced contributor experience with focused, manageable file sizes
- Maintained simplicity while supporting growth and complexity
- Preserved ease of use through clear index structure with direct links
