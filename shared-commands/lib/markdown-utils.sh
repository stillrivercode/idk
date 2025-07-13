#!/bin/bash

# Markdown utility functions for shared commands
# Source this file in other scripts: source ./shared-commands/lib/markdown-utils.sh

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-utils.sh"

# Generate markdown header
generate_header() {
    local level="$1"
    local title="$2"
    local prefix=""

    for ((i=1; i<=level; i++)); do
        prefix+="#"
    done

    echo "$prefix $title"
    echo
}

# Generate markdown table of contents
generate_toc() {
    local -a headers=("$@")

    echo "## Table of Contents"
    echo

    for header in "${headers[@]}"; do
        local anchor=$(echo "$header" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//g')
        echo "- [$header](#$anchor)"
    done
    echo
}

# Generate metadata section
generate_metadata() {
    local issue_number="$1"
    local issue_title="$2"
    local issue_url="$3"
    local created_date="$4"
    local doc_type="${5:-Document}"

    cat << EOF
## Metadata

- **Issue**: [#$issue_number - $issue_title]($issue_url)
- **Created**: $created_date
- **Document Type**: $doc_type
- **Status**: Draft

EOF
}

# Generate issue reference section
generate_issue_reference() {
    local issue_number="$1"
    local issue_title="$2"
    local issue_body="$3"
    local issue_url="$4"
    local labels="$5"

    cat << EOF
## Issue Reference

**Issue**: [#$issue_number - $issue_title]($issue_url)

### Original Description

$issue_body

### Labels

EOF

    if [[ -n "$labels" ]]; then
        while IFS= read -r label; do
            echo "- \`$label\`"
        done <<< "$labels"
    else
        echo "- None"
    fi

    echo
}

# Generate acceptance criteria template
generate_acceptance_criteria() {
    cat << EOF
## Acceptance Criteria

### Functional Requirements

- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Requirement 3

### Non-Functional Requirements

- [ ] Performance requirements met
- [ ] Security requirements satisfied
- [ ] Accessibility standards followed
- [ ] Browser compatibility verified

### Definition of Done

- [ ] Code implemented and tested
- [ ] Unit tests written and passing
- [ ] Integration tests passing
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Ready for deployment

EOF
}

# Generate test scenarios template
generate_test_scenarios() {
    cat << EOF
## Test Scenarios

### Happy Path

1. **Scenario**: Normal operation
   - **Given**: Initial state
   - **When**: User action
   - **Then**: Expected result

### Edge Cases

1. **Scenario**: Edge case 1
   - **Given**: Edge condition
   - **When**: User action
   - **Then**: Expected handling

### Error Handling

1. **Scenario**: Error condition
   - **Given**: Error state
   - **When**: User action
   - **Then**: Error handling

EOF
}

# Generate technical requirements template
generate_technical_requirements() {
    cat << EOF
## Technical Requirements

### Architecture

- **Components**: List main components
- **Data Flow**: Describe data flow
- **Dependencies**: List dependencies

### API Specifications

#### Endpoints

- \`GET /api/endpoint\` - Description
- \`POST /api/endpoint\` - Description

#### Data Models

\`\`\`json
{
  "example": "data model"
}
\`\`\`

### Database Changes

- **Tables**: List table changes
- **Migrations**: Required migrations
- **Indexes**: Required indexes

EOF
}

# Generate implementation plan template
generate_implementation_plan() {
    cat << EOF
## Implementation Plan

### Phase 1: Foundation

- [ ] Task 1
- [ ] Task 2

### Phase 2: Core Features

- [ ] Task 1
- [ ] Task 2

### Phase 3: Integration

- [ ] Task 1
- [ ] Task 2

### Phase 4: Testing & Deployment

- [ ] Task 1
- [ ] Task 2

EOF
}

# Generate risks and considerations template
generate_risks_considerations() {
    cat << EOF
## Risks and Considerations

### Technical Risks

- **Risk 1**: Description and mitigation
- **Risk 2**: Description and mitigation

### Business Risks

- **Risk 1**: Description and mitigation
- **Risk 2**: Description and mitigation

### Dependencies

- **Dependency 1**: Description and impact
- **Dependency 2**: Description and impact

EOF
}

# Escape markdown special characters
escape_markdown() {
    local text="$1"
    echo "$text" | sed -e 's/\\/\\\\/g' -e 's/\*/\\*/g' -e 's/_/\\_/g' -e 's/`/\\`/g'
}

# Format code block
format_code_block() {
    local language="$1"
    local code="$2"

    echo "\`\`\`$language"
    echo "$code"
    echo "\`\`\`"
    echo
}
