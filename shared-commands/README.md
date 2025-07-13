# Shared Commands

This directory contains commands that can be shared between different AI assistants
(Claude, Gemini, etc.) to provide consistent functionality across the project.

## Prerequisites

Before using these commands, you must have the following software installed on your system:

- **GitHub CLI (`gh`)**: For interacting with the GitHub API.
- **jq**: For processing JSON data.

## Installation

You can install the shared commands using npm:

```bash
npm install -g @stillrivercode/shared-commands
```

Or you can use them directly with npx:

```bash
npx @stillrivercode/shared-commands <command> [options]
```

## Usage

### Available Commands

1. **`analyze-issue`**: Analyzes existing GitHub issues for requirements and scope.
2. **`create-spec-issue`**: Creates GitHub issue and detailed technical specifications in unified workflow.
3. **`roadmap`**: Displays the latest project roadmap or generates a new one from a template.

### Examples

```bash
# Analyze an existing GitHub issue
npx @stillrivercode/shared-commands analyze-issue --issue 25

# Create a technical specification issue
npx @stillrivercode/shared-commands create-spec-issue --title "User Authentication Architecture"

# Display or generate project roadmap
npx @stillrivercode/shared-commands roadmap
npx @stillrivercode/shared-commands roadmap --generate --input "New Feature A, Refactor B"
```

## AI Task Format Requirements

When creating issues that will be processed by AI workflows, the generated documents
must follow specific formatting requirements for code blocks:

### Code Block Format

All code blocks in issue descriptions and generated documentation must include file paths:

```markdown
✅ CORRECT: `language filepath
❌ WRONG: `language
```

### Examples

**Correct format:**

````markdown
```javascript src/components/Login.js
export function Login() {
  return <div>Login Component</div>;
}
```
````

**Incorrect format:**

````markdown
```javascript
export function Login() {
  return <div>Login Component</div>;
}
```
````

### Why This Matters

- AI workflows require file paths to determine where to write code
- Issues without proper file paths in code blocks will fail AI processing
- The `create-spec-issue` command templates have been updated to include file paths

### Common Format Mistakes

❌ **Missing file path:**

````markdown
```javascript
function example() {}
```
````

✅ **Correct format:**

````markdown
```javascript src/utils/example.js
function example() {}
```
````

❌ **Using relative path prefixes:**

````markdown
```javascript ./src/component.js

```
````

✅ **Use repository root paths:**

````markdown
```javascript src/component.js

```
````

❌ **Quoted file paths:**

````markdown
```javascript "src/component.js"

```
````

✅ **No quotes needed:**

````markdown
```javascript src/component.js

```
````

### Template Updates

The `spec-template.md` has been updated to include file paths in all code blocks:

- Mermaid diagrams: `docs/architecture-diagram.mmd`
- JSON examples: `docs/api-response-example.json`
- GraphQL schemas: `docs/schema.graphql`
- SQL migrations: `migrations/001_create_users_table.sql`
- Algorithm pseudocode: `docs/algorithms.txt`

## Development

To work on the shared commands, you can clone this repository and then run the commands
directly from the `shared-commands` directory:

```bash
# Analyze an issue
./commands/analyze-issue.sh --issue 25

# Create a spec issue
./commands/create-spec-issue.sh --title "User Authentication Architecture"

# Work with roadmap
./commands/roadmap.sh
```

<!-- Last updated: 2025-07-12 UTC -->
