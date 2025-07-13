#!/bin/bash

# GitHub integration utilities for unified workflow
# Source this file in other scripts: source ./shared-commands/lib/github-integration.sh

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-utils.sh"
source "$SCRIPT_DIR/github-utils.sh"

# Retry GitHub API calls with exponential backoff
gh_with_retry() {
    local max_attempts=3
    local attempt=1
    local delay=1
    local temp_file
    temp_file=$(mktemp)

    while [ $attempt -le $max_attempts ]; do
        # Capture both stdout and stderr
        if gh "$@" 2>"$temp_file"; then
            rm -f "$temp_file"
            return 0
        fi

        local exit_code=$?
        local error_output
        error_output=$(cat "$temp_file" 2>/dev/null)

        if [ $attempt -eq $max_attempts ]; then
            log_error "GitHub API call failed after $max_attempts attempts"
            if [[ -n "$error_output" ]]; then
                log_error "Last error: $error_output"
            fi
            rm -f "$temp_file"
            return $exit_code
        fi

        # Check for specific errors that shouldn't be retried
        if [[ "$error_output" == *"Not Found"* ]] || [[ "$error_output" == *"Forbidden"* ]] || [[ "$error_output" == *"Unauthorized"* ]]; then
            log_error "GitHub API call failed with non-retryable error: $error_output"
            rm -f "$temp_file"
            return $exit_code
        fi

        log_warning "GitHub API call failed (attempt $attempt/$max_attempts), retrying in ${delay}s..."
        if [[ -n "$error_output" ]]; then
            log_debug "Error: $error_output"
        fi
        sleep $delay
        attempt=$((attempt + 1))
        delay=$((delay * 2))
    done

    rm -f "$temp_file"
    return 1
}

# Create GitHub issue with labels and get issue number
create_github_issue() {
    local title="$1"
    local body="$2"
    local labels="$3"
    local assignee="$4"
    local dry_run="${5:-false}"
    local parent_issue="${6:-}"

    if [[ -z "$title" ]]; then
        log_error "Issue title is required"
        return 1
    fi

    if ! check_github_cli; then
        return 1
    fi

    # Build gh issue create command
    local gh_cmd_args=("issue" "create" "--title" "$title")

    # Add body if provided
    if [[ -n "$body" ]]; then
        gh_cmd_args+=("--body-file" "-")
    fi

    # Add labels if provided
    if [[ -n "$labels" ]]; then
        # Convert comma-separated to an array of --label arguments
        IFS=',' read -ra label_array <<< "$labels"
        for label in "${label_array[@]}"; do
            gh_cmd_args+=("--label" "$label")
        done
    fi

    # Add assignee if provided
    if [[ -n "$assignee" ]]; then
        gh_cmd_args+=("--assignee" "$assignee")
    fi

    # Show command in dry run mode
    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN - Would execute: gh ${gh_cmd_args[*]}" >&2
        echo "1" # Return fake issue number for dry run
        return 0
    fi

    # Execute the command and extract issue number
    local issue_url
    if [[ -n "$body" ]]; then
        issue_url=$(echo "$body" | gh_with_retry "${gh_cmd_args[@]}" 2>&1)
    else
        issue_url=$(gh_with_retry "${gh_cmd_args[@]}" 2>&1)
    fi
    if [[ $? -eq 0 ]]; then

        log_success "GitHub issue created: $issue_url" >&2

        # Extract issue number from URL
        if [[ "$issue_url" =~ /issues/([0-9]+) ]]; then
            local issue_number="${BASH_REMATCH[1]}"
            if [[ -n "$parent_issue" ]]; then
                link_issue_to_parent "$parent_issue" "$issue_number"
            fi
            echo "$issue_number"
            return 0
        else
            log_error "Could not extract issue number from URL: $issue_url" >&2
            return 1
        fi
    else
        log_error "Failed to create GitHub issue: $issue_url" >&2
        return 1
    fi
}

# Get issue URL from issue number
get_issue_url() {
    local issue_number="$1"

    if ! validate_issue_number "$issue_number"; then
        return 1
    fi

    if ! check_github_cli; then
        return 1
    fi

    local repo_info
    repo_info=$(gh_with_retry repo view --json url 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        log_error "Failed to get repository URL"
        return 1
    fi

    local repo_url
    repo_url=$(echo "$repo_info" | jq -r '.url')
    echo "$repo_url/issues/$issue_number"
}

# Validate GitHub labels exist or can be created
validate_github_labels() {
    local labels="$1"

    if [[ -z "$labels" ]]; then
        return 0
    fi

    # Available standard labels (GitHub will create missing ones automatically)
    local standard_labels=(
        "user-story" "technical-spec" "documentation"
        "feature" "bug" "enhancement" "question"
        "ai-task" "ai-bug-fix" "ai-refactor" "ai-test" "ai-docs"
        "priority-high" "priority-medium" "priority-low"
        "backend" "frontend" "api" "database" "security"
        "good-first-issue" "help-wanted"
    )

    # Convert comma-separated labels to array
    IFS=',' read -ra label_array <<< "$labels"

    # Check each label
    local custom_labels=()
    for label in "${label_array[@]}"; do
        label=$(echo "$label" | xargs)  # Trim whitespace
        if [[ ! " ${standard_labels[*]} " =~ " $label " ]]; then
            custom_labels+=("$label")
        fi
    done

    # Inform about custom labels
    if [[ ${#custom_labels[@]} -gt 0 ]]; then
        log_info "Custom labels will be created:"
        for custom_label in "${custom_labels[@]}"; do
            echo "  - $custom_label"
        done
    fi

    return 0
}

# Add default labels for command type
add_default_labels() {
    local command_type="$1"
    local existing_labels="$2"

    local default_labels=""

    case "$command_type" in
        "user-story")
            default_labels="user-story,documentation"
            ;;
        "spec"|"technical-spec")
            default_labels="technical-spec,documentation"
            ;;
        *)
            default_labels="documentation"
            ;;
    esac

    # Combine with existing labels
    if [[ -n "$existing_labels" ]]; then
        echo "$existing_labels,$default_labels"
    else
        echo "$default_labels"
    fi
}

# Check if issue exists and is accessible
verify_issue_exists() {
    local issue_number="$1"

    if ! validate_issue_number "$issue_number"; then
        return 1
    fi

    if ! check_github_cli; then
        return 1
    fi

    local issue_data
    if issue_data=$(gh_with_retry issue view "$issue_number" --json number,state 2>/dev/null); then
        local state
        state=$(echo "$issue_data" | jq -r '.state')

        if [[ "$state" == "OPEN" ]]; then
            log_success "Issue #$issue_number exists and is open"
            return 0
        else
            log_warning "Issue #$issue_number exists but is $state"
            return 0
        fi
    else
        log_error "Issue #$issue_number does not exist or is not accessible"
        return 1
    fi
}

# Add comment to existing GitHub issue
add_issue_comment() {
    local issue_number="$1"
    local comment="$2"

    if [[ -z "$comment" ]]; then
        log_error "Comment text is required"
        return 1
    fi

    if ! verify_issue_exists "$issue_number"; then
        return 1
    fi

    if gh_with_retry issue comment "$issue_number" --body "$comment" 2>/dev/null; then
        log_success "Added comment to issue #$issue_number"
        return 0
    else
        log_error "Failed to add comment to issue #$issue_number"
        return 1
    fi
}

# Get repository name in owner/repo format
get_repository_name() {
    if ! check_github_cli; then
        return 1
    fi

    local repo_info
    repo_info=$(gh_with_retry repo view --json name,owner 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        log_error "Failed to get repository information"
        return 1
    fi

    local owner name
    owner=$(echo "$repo_info" | jq -r '.owner.login')
    name=$(echo "$repo_info" | jq -r '.name')

    echo "$owner/$name"
}

# Link a child issue to a parent issue
link_issue_to_parent() {
    local parent_issue_number="$1"
    local child_issue_number="$2"

    if ! verify_issue_exists "$parent_issue_number"; then
        return 1
    fi

    if ! verify_issue_exists "$child_issue_number"; then
        return 1
    fi

    log_info "Linking issue #$child_issue_number to parent #$parent_issue_number..."

    local parent_body
    parent_body=$(gh issue view "$parent_issue_number" --json body -q '.body')

    local new_body
    new_body="$parent_body"

    if gh issue edit "$parent_issue_number" --body "$new_body" >/dev/null 2>&1; then
        log_success "Successfully linked issue #$child_issue_number to parent #$parent_issue_number"
        return 0
    else
        log_error "Failed to link issue #$child_issue_number to parent #$parent_issue_number"
        return 1
    fi
}
