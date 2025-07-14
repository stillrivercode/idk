# AI Command Dictionary

This document defines a set of commands and their meanings for a software development AI assistant. As an AI, you should understand and respond to these commands as described below.

---

## Core Commands

### SELECT

**Definition**: When a user issues a `SELECT` command, they are asking you to find, retrieve, or explain information from the codebase or other resources. This is your primary command for information retrieval.

**Example Prompt**:
`SELECT the user authentication logic from the 'auth.py' file and explain how it handles password hashing.`

---

### CREATE

**Definition**: When a user issues a `CREATE` command, they are asking you to generate new code, files, or other project assets.

**Example Prompt**:
`CREATE a new React component called 'LoginButton' with a click handler that calls the 'handleLogin' function.`

---

### DELETE

**Definition**: When a user issues a `DELETE` command, they are asking you to remove code, files, or other project assets. You should always ask for confirmation before executing a `DELETE` command.

**Example Prompt**:
`DELETE the unused 'old-styles.css' file and remove all references to it from the project.`

---

### FIX

**Definition**: When a user issues a `FIX` command, they are asking you to debug and correct errors in the code.

**Example Prompt**:
`FIX the 'TypeError' that occurs on line 42 of 'user_controller.js' when the user is not logged in.`

---

### gh

**Definition**: A namespace for interacting with the GitHub CLI (`gh`). When a user issues a `gh` command, they are asking you to perform a GitHub operation.

**Example Prompt**:
`gh CREATE a new pull request from the 'feature/new-login-flow' branch to 'main', with the title "feat: Add new login flow" and a body that summarizes the changes.`

---

### commit

**Definition**: When a user issues a `commit` command, they are asking you to create a git commit with a well-formatted message.

**Example Prompt**:
`commit the current staged changes with a conventional commit message of type 'feat' and the scope 'auth'. The message should describe the addition of the new login button.`

---

### push

**Definition**: When a user issues a `push` command, they are asking you to push changes to a remote repository.

**Example Prompt**:
`push the current branch to the 'origin' remote and set it up to track the remote branch.`

---

### pr

**Definition**: A shorthand for `gh pr`. When a user issues a `pr` command, they are asking you to perform a pull request operation.

**Example Prompt**:
`pr CREATE --base main --head feature/new-login-flow --title "feat: Add new login flow" --body "This PR adds a new login button and the associated authentication logic."`

---

### comment

**Definition**: When a user issues a `comment` command, they are asking you to add a comment to a GitHub issue or pull request.

**Example Prompt**:
`comment "Fixed the workflow script references and JSON construction issues" on this PR`
