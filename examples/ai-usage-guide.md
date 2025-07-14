# AI Usage Guide for the Information Dense Keywords Dictionary

This document outlines how an AI assistant should use the Information Dense Keywords Dictionary to interpret and execute user commands.

## Important: Read AI Instructions First

Before using this guide, AI assistants should first read [AI.md](../AI.md) for comprehensive shared instructions, then refer to their specific instruction file (CLAUDE.md, GEMINI.md, etc.).

## Core Principle

The `information-dense-keywords.md` file is your primary source of truth for understanding the user's intent. When a user issues a command, you should first try to match it to one of the keywords in the dictionary.

## Usage Pattern

1. **Identify the Keyword**: Parse the user's prompt to identify the core command (e.g., `SELECT`, `CREATE`, `FIX`).

2. **Understand the Definition**: Refer to the `Definition` for that keyword in the `information-dense-keywords.md` to understand the user's high-level goal.

3. **Extract Entities**: Identify the specific entities in the user's prompt. For example, in the prompt `CREATE a new React component called 'LoginButton'`, the entities are:
    - **Component Type**: React component
    - **Component Name**: LoginButton

4. **Execute the Command**: Based on the keyword and the extracted entities, perform the requested action. This may involve:
    - Searching for files in the codebase
    - Generating new code
    - Modifying existing code
    - Running shell commands

## Example Walkthrough

**User Prompt**: `FIX the 'TypeError' that occurs on line 42 of 'user_controller.js' when the user is not logged in.`

**AI's Thought Process**:

1. **Keyword**: `FIX`
2. **Definition**: The user wants me to debug and correct an error.
3. **Entities**:
    - **Error Type**: `TypeError`
    - **Line Number**: 42
    - **File Name**: `user_controller.js`
    - **Condition**: When the user is not logged in.
4. **Action**:
    1. Read the file `user_controller.js`
    2. Examine the code on line 42
    3. Identify the cause of the `TypeError`
    4. Propose a fix that addresses the error under the specified condition
    5. Apply the fix to the file

## Additional Examples

### Example 1: CREATE Command

**User Prompt**: `CREATE a REST API endpoint for user registration with email validation`

**AI Process**:

1. **Keyword**: `CREATE`
2. **Entities**: REST API endpoint, user registration, email validation
3. **Action**: Generate new API endpoint code with validation logic

### Example 2: SELECT Command

**User Prompt**: `SELECT all database migration files and show their status`

**AI Process**:

1. **Keyword**: `SELECT`
2. **Entities**: database migration files, status information
3. **Action**: Find migration files and display their current state

## Integration with Project Structure

When working with this dictionary project specifically:

- Reference `information-dense-keywords.md` for command definitions
- Check `docs/roadmaps/ROADMAP.md` for development priorities
- Follow guidelines in `AI.md` for consistent behavior across AI assistants
- Contribute improvements based on real usage patterns

## Best Practices

1. **Be Precise**: Always identify the exact keyword from the dictionary
2. **Extract All Entities**: Don't miss important details in the user's request
3. **Confirm Understanding**: When commands are ambiguous, ask for clarification
4. **Document Patterns**: Help improve the dictionary by noting common usage patterns
5. **Test Commands**: Validate that dictionary commands work effectively in practice
