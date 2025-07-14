#!/bin/bash

# Create GitHub issue and detailed technical specification document in unified workflow
# Usage: ./shared-commands/commands/create-spec-issue.sh --title "TITLE" [OPTIONS]

set -e

# Get script directory and source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common-utils.sh"
source "$SCRIPT_DIR/../lib/github-utils.sh"
source "$SCRIPT_DIR/../lib/github-integration.sh"
source "$SCRIPT_DIR/../lib/markdown-utils.sh"

# Command configuration
COMMAND_NAME="create-spec"
DESCRIPTION="Creates a GitHub issue and detailed technical specification document in a unified workflow."

# Parse command line arguments
parse_unified_args "$@" || exit 1


# Show help if requested
if [[ "$PARSED_HELP" == "true" ]]; then
    extra_options="Spec-specific Options:
  --user-story-issue NUM    Link to related user story issue"
    show_unified_help "$COMMAND_NAME" "$DESCRIPTION" "$extra_options"
    exit 0
fi

# Validate required arguments
if [[ -z "$PARSED_TITLE" ]] && [[ -z "$PARSED_ISSUE" ]]; then
    log_error "Either --title or --issue is required"
    show_unified_help "$COMMAND_NAME" "$DESCRIPTION"
    exit 1
fi

# Set up variables
title="$PARSED_TITLE"
body="${PARSED_BODY:-}"
labels="$PARSED_LABELS"
assignee="${PARSED_ASSIGNEE:-}"
user_story_issue="${PARSED_USER_STORY_ISSUE:-}"
issue_number="${PARSED_ISSUE:-}"
ai_task="${PARSED_AI_TASK:-false}"
dry_run="${PARSED_DRY_RUN:-false}"

# If issue number is provided, fetch title and body
if [[ -n "$issue_number" ]] && [[ -z "$title" ]]; then
    log_info "Fetching details for issue #$issue_number..."
    issue_data=$(gh issue view "$issue_number" --json title,body)
    title=$(echo "$issue_data" | jq -r '.title')
    body=$(echo "$issue_data" | jq -r '.body')
fi

# Add ai-task to labels if requested
if [[ "$ai_task" == "true" ]]; then
    labels=$(add_default_labels "technical-spec" "$labels")
    if [[ "$labels" != *"ai-task"* ]]; then
        labels="$labels,ai-task"
    fi
else
    labels=$(add_default_labels "technical-spec" "$labels")
fi

# Main execution
main() {
    log_info "Creating technical specification: $title"
    echo

    # Validate GitHub setup
    if ! check_github_cli; then
        exit 1
    fi

    # Validate user story issue if provided
    if [[ -n "$user_story_issue" ]]; then
        log_info "Validating related user story issue #$user_story_issue..."
        if ! verify_issue_exists "$user_story_issue"; then
            log_warning "User story issue #$user_story_issue may not exist"
        else
            log_success "User story issue #$user_story_issue verified"
        fi
        echo
    fi

    # Validate labels
    validate_github_labels "$labels"
    echo

    # Create GitHub issue
    log_info "Step 1: Creating GitHub issue..."
    local issue_number
    if ! issue_number=$(create_github_issue "$title" "$body" "$labels" "$assignee" "$dry_run"); then
        log_error "Failed to create GitHub issue"
        exit 1
    fi

    echo
    log_info "Step 2: Generating technical specification document..."

    # Create output directory
    ensure_directory "specs"

    # Generate filename using issue number
    local sanitized_title filename issue_url
    sanitized_title=$(sanitize_filename "$title")
    filename="specs/issue-${issue_number}-${sanitized_title}.md"

    # Get issue URL
    if [[ "$dry_run" != "true" ]]; then
        issue_url=$(get_issue_url "$issue_number")
    else
        issue_url="https://github.com/owner/repo/issues/$issue_number"
    fi

    # Generate technical specification document
    if [[ "$dry_run" == "true" ]]; then
        log_info "Would create: $filename"
    else
        generate_spec_document > "$filename"
    fi

    log_success "Technical specification created: $filename"

    # Add comment to issue linking to the spec document
    if [[ "$dry_run" != "true" ]]; then
        local spec_comment="📋 **Technical Specification Document**

A detailed technical specification has been created for this issue:

**📄 Specification File**: [\`$filename\`]($filename)

This document contains:
- 🏗️ **System Architecture** - Component design and data flow
- 🔧 **API Specifications** - Endpoint definitions and examples
- 🗄️ **Database Design** - Schema, indexes, and migrations
- 🔒 **Security Considerations** - Auth, encryption, and compliance
- ⚡ **Performance Requirements** - Targets and optimization strategies
- 🧪 **Testing Strategy** - Unit, integration, and E2E testing
- 🚀 **Deployment Plan** - Environments and infrastructure
- 📊 **Progress Tracking** - Implementation checklist

The specification document will be updated as implementation progresses."

        if add_issue_comment "$issue_number" "$spec_comment"; then
            log_success "Added specification document link to issue #$issue_number"
        else
            log_warning "Failed to add specification document link to issue #$issue_number"
        fi
        echo
    fi

    # Check for related user story
    if [[ -n "$user_story_issue" ]]; then
        local user_story_title user_story_sanitized user_story_file
        if [[ "$dry_run" != "true" ]]; then
            user_story_title=$(gh issue view "$user_story_issue" --json title | jq -r '.title' 2>/dev/null || echo "$title")
        else
            user_story_title="$title"
        fi
        user_story_sanitized=$(sanitize_filename "$user_story_title")
        user_story_file="user-stories/issue-${user_story_issue}-${user_story_sanitized}.md"

        echo
        if [[ -f "$user_story_file" ]]; then
            log_info "Related user story found: $user_story_file"
        else
            log_info "💡 Related user story not found. Consider creating with:"
            log_info "   ./shared-commands/commands/create-user-story-issue.sh --title \"$user_story_title\""
        fi
    else
        local potential_user_story="user-stories/issue-${issue_number}-${sanitized_title}.md"
        echo
        if [[ -f "$potential_user_story" ]]; then
            log_info "Related user story found: $potential_user_story"
        else
            log_info "💡 Consider creating a related user story with:"
            log_info "   ./shared-commands/commands/create-user-story-issue.sh --title "$title Story""
        fi
    fi

    # Add cross-reference comment to user story issue if provided
    if [[ -n "$user_story_issue" && "$dry_run" != "true" ]]; then
        local comment="📋 **Technical Specification Created**

Technical specification has been created for this user story:
- **Issue**: #$issue_number
- **Document**: [Technical Specification]($issue_url)
- **File**: \`$filename\`

This spec provides detailed implementation guidance for the user story requirements."

        if add_issue_comment "$user_story_issue" "$comment"; then
            log_success "Added cross-reference comment to user story issue #$user_story_issue"
        fi
    fi

    # Show completion summary
    echo
    log_success "✅ Unified workflow completed!"
    echo
    echo "📋 **Created:**"
    echo "   • GitHub Issue #$issue_number: $issue_url"
    echo "   • Technical Spec: $filename"
    echo "   • Spec document linked to issue via comment"
    if [[ -n "$user_story_issue" ]]; then
        echo "   • Cross-referenced with User Story Issue #$user_story_issue"
    fi
    echo

    if [[ "$ai_task" == "true" ]]; then
        echo "🤖 **AI Workflow:**"
        echo "   • AI implementation will start automatically"
        echo "   • Monitor progress in GitHub Actions"
        echo "   • Review generated PR when ready"
        echo
    fi

    echo "📚 **Next Steps:**"
    if [[ "$ai_task" != "true" ]]; then
        echo "   • Add 'ai-task' label to trigger AI implementation"
    fi
    if [[ -z "$user_story_issue" ]]; then
        echo "   • Create related user story if needed"
    fi
    echo "   • Assign issue to team members"
    echo "   • Add to project boards for tracking"
}



# Generate the complete technical specification document
generate_spec_document() {
    local template_path="$SCRIPT_DIR/../lib/templates/spec-template.md"

    if [[ ! -f "$template_path" ]]; then
        log_error "Template not found at $template_path"
        return 1
    fi

    local workflow_integration
    if [[ "$labels" == *"ai-task"* ]]; then
        workflow_integration="- ✅ **AI Task**: This issue will trigger automated AI implementation\n- 📊 **Monitoring**: Track progress in GitHub Actions tab\n- 🔄 **Automation**: PR will be created automatically when implementation is complete"
    else
        workflow_integration="- 📝 **Manual**: Add 'ai-task' label to trigger AI implementation\n- 👥 **Assignment**: Assign to team members for manual implementation\n- 📋 **Tracking**: Add to project boards and milestones"
    fi

    local labels_md
    if [[ -n "$labels" ]]; then
        labels_md=$(echo "$labels" | tr ',' ' ' | sed 's/ /`, `/g' | sed 's/^/- `/g' | sed 's/$/`/g')
    else
        labels_md="- None"
    fi

    # Read the template and perform substitutions
    sed -e "s/{{TITLE}}/$(escape_sed "$title")"/g \
        -e "s/{{ISSUE_NUMBER}}/$issue_number/g" \
        -e "s|{{ISSUE_URL}}|$issue_url|g" \
        -e "s/{{DATE}}/$(get_current_date)/g" \
        -e "s|{{BODY}}|$(escape_sed "${body:-This technical specification was generated from GitHub issue requirements. Please customize the problem statement with specific technical challenges and requirements.}")|g" \
        -e "s|{{LABELS}}|$(escape_sed "$labels_md")|g" \
        -e "s|{{WORKFLOW_INTEGRATION}}|$(escape_sed "$workflow_integration")|g" \
        -e "s/{{COMMAND_NAME}}/$COMMAND_NAME/g" \
        -e "s/{{REPO_NAME}}/$(get_repository_name 2>/dev/null || echo "Unknown")|g" \
        "$template_path"
}

# Execute main function
main "$@"
