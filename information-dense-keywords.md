# Information Dense Keywords Dictionary

This document defines a comprehensive vocabulary of commands for AI assistants in software development. Each command compresses common prompts into memorable keywords that save time and improve consistency.

## Command Chaining

Commands can be chained together to create complex workflows. When chaining commands, separate them with "then" or "and" to indicate sequential or parallel operations.

### Chaining Examples

**Sequential Chain**:
`analyze this authentication system then spec this improved version then plan this implementation`

**Parallel Operations**:
`test this user service and document this API endpoint`

**Complex Workflow**:
`debug this performance issue then optimize this query then test this solution and document this change`

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

---

### spec this

**Definition**: When a user issues a `spec this` command, they are asking you to create a detailed technical specification. You should analyze the current context, requirements, or problem and produce a comprehensive specification document that will be saved in the `/specs` directory.

The specification should include:

- Clear objectives and scope
- Detailed requirements (functional and non-functional)
- Technical constraints and considerations
- Implementation approach
- Success criteria
- Optional: User stories, acceptance criteria, or API specifications

**File Location**: All specifications should be saved in `/specs/` with descriptive filenames like:

- `/specs/auth-system-oauth2.md`
- `/specs/data-migration-mysql-postgres.md`
- `/specs/realtime-notifications.md`

**Example Prompts**:

- `spec this authentication system with OAuth2 support`
- `spec this data migration from MySQL to PostgreSQL`
- `spec this new feature for real-time notifications`

**Expected Output Format**:

```markdown
# Technical Specification: [Title]

## Overview
Brief description of what needs to be built and why.

## Requirements
### Functional Requirements
- Detailed list of what the system must do

### Non-functional Requirements
- Performance, security, scalability requirements

## Technical Design
- Architecture overview
- Component breakdown
- Data models
- API contracts (if applicable)

## Implementation Plan
- Phases or milestones
- Dependencies
- Risk considerations

## Success Criteria
- How to measure completion
- Testing approach
```

---

## Development Commands

### analyze this

**Definition**: When a user issues an `analyze this` command, they are asking you to examine code, system architecture, or a specific component to identify patterns, potential issues, and suggest improvements. Provide a thorough analysis with actionable insights.

**Example Prompts**:

- `analyze this authentication flow for security vulnerabilities`
- `analyze this database schema for performance bottlenecks`
- `analyze this React component for code smells`

---

### debug this

**Definition**: When a user issues a `debug this` command, they are asking you to investigate an issue, trace the problem to its root cause, and provide a solution. Include explanations of why the issue occurs and how the fix addresses it.

**Example Prompts**:

- `debug this TypeError in the user registration flow`
- `debug this performance issue in the data processing pipeline`
- `debug this intermittent test failure`

---

### optimize this

**Definition**: When a user issues an `optimize this` command, they are asking you to improve performance, efficiency, or resource utilization. Provide specific optimizations with expected improvements and any trade-offs.

**Example Prompts**:

- `optimize this database query that's taking 5 seconds`
- `optimize this React component that's re-rendering too often`
- `optimize this algorithm for better time complexity`

---

## Documentation Commands

### document this

**Definition**: When a user issues a `document this` command, they are asking you to create comprehensive documentation including purpose, usage, examples, and API references where applicable.

**Example Prompts**:

- `document this API endpoint with request/response examples`
- `document this React component with props and usage examples`
- `document this configuration file with all available options`

---

### explain this

**Definition**: When a user issues an `explain this` command, they are asking you to provide a clear, structured explanation of how something works, breaking down complex concepts into understandable parts.

**Example Prompts**:

- `explain this authentication middleware and how it validates tokens`
- `explain this recursive algorithm step by step`
- `explain this design pattern and why it's used here`

---

## Quality Assurance Commands

### test this

**Definition**: When a user issues a `test this` command, they are asking you to generate appropriate tests including unit tests, integration tests, or end-to-end tests as needed. Include edge cases and error scenarios.

**Example Prompts**:

- `test this user service with unit tests covering all methods`
- `test this API endpoint with integration tests`
- `test this React component with various prop combinations`

---

### review this

**Definition**: When a user issues a `review this` command, they are asking you to perform a thorough code review examining code quality, security, performance, and adherence to best practices. Provide specific feedback with suggestions for improvement.

**Example Prompts**:

- `review this pull request for security issues`
- `review this architecture design for scalability`
- `review this code for adherence to SOLID principles`

---

## Workflow Commands

### plan this

**Definition**: When a user issues a `plan this` command, they are asking you to break down a complex task or project into manageable steps, creating a structured implementation plan with clear milestones.

**Example Prompts**:

- `plan this migration from monolith to microservices`
- `plan this new feature implementation with 2-week sprints`
- `plan this refactoring of the legacy codebase`
