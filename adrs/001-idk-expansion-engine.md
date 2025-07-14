# ADR 001: IDK Dictionary as a Single Markdown File

**Status**: Accepted

**Context**:

The project has gone through several iterations:
1.  A collection of structured YAML files.
2.  A CLI tool with a programmatic syntax (`expand Keyword[param=value]`).
3.  A CLI tool with a natural language syntax (`SELECT Keyword with feature`).

All of these approaches were deemed overly complex for the core goal of the project: to provide a simple, shared vocabulary for human-AI communication.

**Decision**:

We will simplify the project to a single, well-structured Markdown file named `idk-dictionary.md`. This file will contain a curated list of commands and their definitions, intended to be used as a reference for constructing prompts for an AI assistant.

This approach prioritizes simplicity, maintainability, and ease of use over technical complexity.

**Consequences**:

*   The project is significantly simplified, with no need for a CLI tool, a complex file structure, or a validation script.
*   The focus is shifted from building a tool to curating a high-quality dictionary of commands.
*   The barrier to entry for contributors is lowered, as they only need to edit a single Markdown file.
*   The project is more flexible, as users can easily copy, paste, and modify the commands to fit their specific needs.
