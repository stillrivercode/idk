# Issue Labels Guide

This document defines the standardized labeling system for GitHub issues in the agentic workflow template project.

## Label Categories

### Priority Labels 🔥

| Label      | Color            | Description               | When to Use                                    |
| ---------- | ---------------- | ------------------------- | ---------------------------------------------- |
| `critical` | #B60205 (Red)    | Must be fixed immediately | Security vulnerabilities, system-breaking bugs |
| `high`     | #D93F0B (Orange) | Should be fixed soon      | Important bugs, blocking features              |
| `medium`   | #FBCA04 (Yellow) | Normal priority           | Standard enhancements, non-blocking bugs       |
| `low`      | #0E8A16 (Green)  | Nice to have              | Minor improvements, cosmetic fixes             |

### Type Labels 🏷️

| Label           | Color                  | Description              | When to Use                              |
| --------------- | ---------------------- | ------------------------ | ---------------------------------------- |
| `bug`           | #D73A4A (Red)          | Something isn't working  | Code defects, errors, failures           |
| `enhancement`   | #A2EEEF (Light Blue)   | New feature or request   | Feature requests, improvements           |
| `documentation` | #0075CA (Blue)         | Improvements to docs     | Doc updates, guides, README changes      |
| `security`      | #B60205 (Red)          | Security-related issues  | Vulnerabilities, access control, secrets |
| `performance`   | #D4C5F9 (Purple)       | Performance improvements | Optimization, speed, efficiency          |
| `refactor`      | #FEF2C0 (Light Yellow) | Code restructuring       | Clean up, reorganization                 |

### Scope Labels 📋

| Label            | Color                  | Description             | When to Use                               |
| ---------------- | ---------------------- | ----------------------- | ----------------------------------------- |
| `phase-1`        | #1D76DB (Blue)         | Phase 1 roadmap items   | Issues related to quick start phase       |
| `phase-2`        | #0366D6 (Darker Blue)  | Phase 2 roadmap items   | Issues for optimization phase             |
| `workflow`       | #E4E669 (Yellow-Green) | GitHub Actions workflow | Workflow file changes, automation         |
| `ai-task`        | #C5DEF5 (Light Blue)   | AI task functionality   | AI task processing, Claude integration    |
| `testing`        | #D876E3 (Pink)         | Test-related changes    | Test suite, validation, quality assurance |
| `infrastructure` | #5319E7 (Purple)       | Infrastructure setup    | Deployment, configuration, setup          |

### Status Labels 📊

| Label         | Color            | Description                | When to Use                                  |
| ------------- | ---------------- | -------------------------- | -------------------------------------------- |
| `ready`       | #0E8A16 (Green)  | Ready for development      | Issue is well-defined and actionable         |
| `in-progress` | #FBCA04 (Yellow) | Currently being worked on  | Someone is actively working on this          |
| `blocked`     | #D93F0B (Orange) | Cannot proceed             | Waiting on dependencies or decisions         |
| `needs-info`  | #D876E3 (Pink)   | More information needed    | Requires clarification or additional details |
| `duplicate`   | #CFD3D7 (Gray)   | Duplicate of another issue | Already reported elsewhere                   |
| `wontfix`     | #CFD3D7 (Gray)   | Will not be implemented    | Decided against implementation               |

### Special Labels 🎯

| Label              | Color            | Description            | When to Use                               |
| ------------------ | ---------------- | ---------------------- | ----------------------------------------- |
| `good-first-issue` | #7057FF (Purple) | Good for newcomers     | Easy issues for new contributors          |
| `help-wanted`      | #008672 (Teal)   | Extra attention needed | Community help requested                  |
| `breaking-change`  | #B60205 (Red)    | Breaking API changes   | Changes that break existing functionality |
| `needs-review`     | #0366D6 (Blue)   | Needs code review      | PR or solution needs review               |

## Labeling Guidelines

### Mandatory Labels

Every issue should have:

1. **One priority label** (`critical`, `high`, `medium`, `low`)
2. **One type label** (`bug`, `enhancement`, `documentation`, etc.)

### Optional Labels

Add as appropriate:

- **Scope labels** to categorize by area of impact
- **Status labels** to track progress
- **Special labels** for community or process needs

### Labeling Examples

#### Security Issue

```text
Labels: critical, security, workflow, phase-1, ready
```

#### Documentation Enhancement

```text
Labels: medium, documentation, phase-1, good-first-issue
```

#### Performance Bug

```text
Labels: high, bug, performance, ai-task, needs-info
```

## Label Management

### Creating Labels

Use the GitHub CLI to create labels:

```bash
# Priority labels
gh label create "critical" --color "B60205" --description "Must be fixed immediately"
gh label create "high" --color "D93F0B" --description "Should be fixed soon"
gh label create "medium" --color "FBCA04" --description "Normal priority"
gh label create "low" --color "0E8A16" --description "Nice to have"

# Type labels
gh label create "security" --color "B60205" --description "Security-related issues"
gh label create "performance" --color "D4C5F9" --description "Performance improvements"
# ... (see scripts/create-labels.sh for complete list)
```

### Applying Labels

```bash
# Add labels to an issue
gh issue edit 20 --add-label "critical,security,workflow"

# Remove labels from an issue
gh issue edit 20 --remove-label "needs-info"
```

### Automated Labeling

The AI task workflow automatically applies labels:

- `ai-task` label is added to all AI-generated issues
- Branch prefix determines additional labels (e.g., `feat/` → `enhancement`)

## Best Practices

### For Issue Creators

1. **Always add priority and type labels**
2. **Use descriptive titles** that don't require reading the full issue
3. **Add scope labels** to help with project organization
4. **Update labels** as issue status changes

### For Maintainers

1. **Review labels weekly** to ensure consistency
2. **Clean up unused labels** periodically
3. **Document any new labels** added to this guide
4. **Use label filters** for project planning and triage

### For Contributors

1. **Check existing labels** before creating new ones
2. **Ask for label changes** if current labels don't fit
3. **Use `good-first-issue`** filter to find beginner-friendly tasks
4. **Watch for `help-wanted`** labels on issues you can assist with

## Label Analytics

Use GitHub's label filtering to track:

- **Critical issues**: `label:critical` - for urgent attention
- **Phase 1 work**: `label:phase-1` - roadmap tracking
- **Security items**: `label:security` - security audit
- **Documentation gaps**: `label:documentation` - content planning
- **Community contributions**: `label:good-first-issue OR label:help-wanted`

This labeling system helps maintain organization, improve discoverability, and facilitate effective
project management across all phases of development.
