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
* `docs/roadmaps/ROADMAP.md` - Development priorities and future plans
* `examples/` - Usage examples and guides
* `adrs/` - Architecture decision records
* `AI.md` - This shared AI instruction file
* `CLAUDE.md` - Claude-specific instructions
* `GEMINI.md` - Gemini-specific instructions

## Cross-References

* [information-dense-keywords.md](information-dense-keywords.md) - The core command dictionary
* [README.md](README.md) - Main project documentation
* [docs/roadmaps/ROADMAP.md](docs/roadmaps/ROADMAP.md) - Development roadmap and priorities
* [examples/ai-usage-guide.md](examples/ai-usage-guide.md) - AI usage examples
* [CLAUDE.md](CLAUDE.md) - Claude-specific context and instructions
* [GEMINI.md](GEMINI.md) - Gemini-specific context and instructions

## Core Principles

Remember: This project focuses on creating a clear, actionable vocabulary for human-AI collaboration in software development. Prioritize:

* **Clarity**: Make definitions unambiguous and easy to understand
* **Practical Utility**: Focus on commands that solve real development problems
* **Broad Applicability**: Ensure commands work across different technologies and contexts
* **Consistency**: Maintain consistent patterns and structures throughout the dictionary

## AI-Specific Considerations

Each AI assistant should reference this file for common guidance, then refer to their specific instruction file (CLAUDE.md, GEMINI.md, etc.) for platform-specific considerations and capabilities.
