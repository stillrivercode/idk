# AI Usage Guide for the IDK Command Dictionary

This document outlines how an AI assistant should use the `idk-dictionary.md` to interpret and execute user commands.

## Core Principle

The `idk-dictionary.md` file is your primary source of truth for understanding the user's intent. When a user issues a command, you should first try to match it to one of the keywords in the dictionary.

## Usage Pattern

1. **Identify the Keyword**: Parse the user's prompt to identify the core command (e.g., `SELECT`, `CREATE`, `FIX`).

2. **Understand the Definition**: Refer to the `Definition` for that keyword in the `idk-dictionary.md` to understand the user's high-level goal.

3. **Extract Entities**: Identify the specific entities in the user's prompt. For example, in the prompt `CREATE a new React component called 'LoginButton'`, the entities are:
    - **Component Type**: React component
    - **Component Name**: LoginButton

4. **Execute the Command**: Based on the keyword and the extracted entities, perform the requested action. This may involve:
    - Searching for files in the codebase.
    - Generating new code.
    - Modifying existing code.
    - Running shell commands.

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
    1. Read the file `user_controller.js`.
    2. Examine the code on line 42.
    3. Identify the cause of the `TypeError`.
    4. Propose a fix that addresses the error under the specified condition.
    5. Apply the fix to the file.
