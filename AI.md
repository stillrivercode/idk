# AI.md - Shared Instructions for All AI Assistants

This file provides common guidance for all AI assistants working with the Information Dense Keywords Dictionary project.

## Project Overview

This is the Information Dense Keywords Dictionary - a curated vocabulary for instructing AI assistants. The project provides a shared, efficient vocabulary for common software development tasks using natural language.

## How to Use This Dictionary

As an AI assistant, you should use the `information-dense-keywords.md` file as your primary reference for understanding user intent. When a user issues a command, follow this pattern:

### Usage Pattern

1. **Identify the Keyword**: Parse the user's prompt to identify the core command (e.g., `SELECT`, `CREATE`, `FIX`).

2. **Understand the Definition**: Refer to the `Definition` for that keyword in `information-dense-keywords.md` to understand the user's high-level goal.

3. **Extract Entities**: Identify the specific entities in the user's prompt. For example, in "CREATE a new React component called 'LoginButton'":
   * **Component Type**: React component
   * **Component Name**: LoginButton

4. **Execute the Command**: Based on the keyword and entities, perform the requested action through:
   * Searching for files in the codebase
   * Generating new code
   * Modifying existing code
   * Running shell commands

## Dictionary Commands

The core commands in `information-dense-keywords.md` include:

* **SELECT** - Choose or filter items from a collection
* **CREATE** - Generate new code, files, or components
* **FIX** - Resolve bugs, errors, or issues
* **UPDATE** - Modify existing code or configurations
* **DELETE** - Remove code, files, or configurations
* **ANALYZE** - Examine and understand code or systems
* **DEPLOY** - Release or publish applications

## Working with This Project

When helping users with this dictionary project:

1. **Content Updates**: Help users add new commands or improve existing definitions
2. **Example Enhancement**: Assist in adding practical usage examples
3. **Quality Assurance**: Ensure definitions are clear and actionable
4. **Validation**: Test that commands work effectively with AI assistants

## File Structure

Key files you'll work with:

* `information-dense-keywords.md` - The core dictionary content
* `README.md` - Project documentation and usage guide
* `docs/roadmaps/` - Directory for roadmap documents (e.g., `q4-roadmap.md`)
* `docs/plans/` - Directory for planning documents (e.g., `new-feature-plan.md`)
* `docs/specs/` - Directory for specifications (e.g., `api-spec-v2.md`)
* `docs/research/` - Directory for research notes (e.g., `competitor-analysis.md`)
* `examples/` - Usage examples and guides
* `adrs/` - Architecture decision records
* `AI.md` - This shared AI instruction file

## Cross-References

* [information-dense-keywords.md](information-dense-keywords.md) - The core command dictionary
* [README.md](README.md) - Main project documentation
* [docs/roadmaps/](docs/roadmaps/) - Directory for roadmap documents
* [docs/plans/](docs/plans/) - Directory for planning documents
* [docs/specs/](docs/specs/) - Directory for specifications
* [docs/research/](docs/research/) - Directory for research notes
* [examples/ai-usage-guide.md](examples/ai-usage-guide.md) - AI usage examples

## Core Principles

Remember: This project focuses on creating a clear, actionable vocabulary for human-AI collaboration in software development. Prioritize:

* **Clarity**: Make definitions unambiguous and easy to understand
* **Practical Utility**: Focus on commands that solve real development problems
* **Broad Applicability**: Ensure commands work across different technologies and contexts
* **Consistency**: Maintain consistent patterns and structures throughout the dictionary

## AI-Specific Considerations

Each AI assistant should reference this file for common guidance, then refer to their specific instruction file for platform-specific considerations and capabilities.
