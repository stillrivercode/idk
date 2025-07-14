# AI Development Workflow Guide

This guide provides a structured approach for using AI-powered development
workflows effectively.

## Recommended Workflow

For best results, follow this structured approach:

1. **Start with Research**: Create research documents to understand the problem
    space
2. **Update Roadmap**: Use `./shared-commands/commands/roadmap.sh` to plan your
    features
3. **Create Specifications**: Use
    `./shared-commands/commands/create-spec-issue.sh` for detailed technical
    specs
4. **Implement with AI**: Create implementation issues with the `ai-task` label

## Available Labels

- `ai-task` - General AI development tasks (use after creating specs)
- `ai-bug-fix` - AI-assisted bug fixes
- `ai-refactor` - Code refactoring requests
- `ai-test` - Test generation
- `ai-docs` - Documentation updates
- `research` - Research and analysis tasks (start here)
- `spec` - Technical specification issues

## Shared Commands for AI Assistants

This project includes a shared commands directory (`shared-commands/commands/`)
that provides consistent functionality across different AI assistants (Claude,
Gemini, etc.).

### Available Shared Commands

#### analyze-issue (Step 1: Research & Analysis)

Analyzes existing GitHub issue for requirements, scope, and implementation
considerations. Use this first to understand the problem space before planning.

Usage:

```bash
./shared-commands/commands/analyze-issue.sh --issue 25
./shared-commands/commands/analyze-issue.sh --issue 100 --generate-docs
```

This command:

1. Fetches and analyzes existing issue content
2. Extracts requirements and assesses complexity
3. Provides implementation recommendations
4. Identifies dependencies and potential challenges
5. Optionally generates missing documentation with `--generate-docs`

**Creating Research Documents**: The `--generate-docs` flag creates research
documents that can be referenced in later steps. These documents capture
analysis findings and serve as input for roadmap generation.

#### roadmap (Step 2: Plan Features)

Displays the latest project roadmap or generates a new one from a template. Use
this after creating research documents to plan your feature development.

Usage:

```bash
# Display the latest roadmap
./shared-commands/commands/roadmap.sh

# Generate a new roadmap from research insights
./shared-commands/commands/roadmap.sh --generate --input "New Feature A, Refactor B"

# Generate roadmap from research document created by analyze-issue
./shared-commands/commands/roadmap.sh --generate --research-doc path/to/research.md
```

**Using Research Documents**: When you use `analyze-issue --generate-docs`, the
created research documents can be fed into roadmap generation using the
`--research-doc` parameter. This creates a seamless flow from issue analysis to
roadmap planning.

#### create-spec-issue (Step 3: Create Technical Specs)

Creates a GitHub issue and detailed technical specification document in a
unified workflow. Use this after updating your roadmap to create detailed
specifications for features.

Usage:

```bash
./shared-commands/commands/create-spec-issue.sh --title "User Authentication Architecture"
./shared-commands/commands/create-spec-issue.sh --title "API Design" --labels "backend,api"
```

This command:

1. Creates GitHub issue for technical specification
2. Generates detailed technical spec in `specs/issue-NUMBER-title.md` from a
   template
3. **Automatically links spec document to GitHub issue** via comment with
   overview
4. Links to related user stories using `--user-story-issue` parameter
5. Adds cross-reference comments to linked issues

**Enhanced Linking**: The spec document is now automatically linked to the GitHub
issue via a detailed comment that includes an overview of the specification
contents, improving traceability between issues and technical documentation.

### Shared Command Structure

```text
shared-commands/
├── commands/           # Command implementations
├── lib/               # Shared utilities
└── templates/         # Document templates
```

### Benefits of Shared Commands

- **Consistency**: Same commands work across all AI assistants
- **Maintainability**: Single source of truth for command logic
- **Extensibility**: Easy to add new shared commands
- **Cross-AI Compatibility**: Claude, Gemini, and other AI assistants can use
  the same tools

## Best Practices

1. **Clear Issue Descriptions**: The better the description, the better the AI
    output
2. **Incremental Changes**: Break large features into smaller tasks
3. **Review AI Code**: Always review AI-generated code before merging
4. **Test Everything**: AI code should pass all tests before merging
5. **Cost Awareness**: Monitor your usage to avoid surprises
6. **Security Monitoring**: Review workflow logs for any unusual activity
