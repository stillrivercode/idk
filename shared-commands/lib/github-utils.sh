#!/bin/bash

# GitHub utility functions for shared commands
# Source this file in other scripts: source ./shared-commands/lib/github-utils.sh

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-utils.sh"

# Validate issue number format
validate_issue_number() {
    local issue_number="$1"

    if [[ -z "$issue_number" ]]; then
        log_error "Issue number is required"
        return 1
    fi

    # Check if it's a positive integer
    if ! [[ "$issue_number" =~ ^[1-9][0-9]*$ ]]; then
        log_error "Invalid issue number: '$issue_number'. Must be a positive integer"
        return 1
    fi

    # Check if issue number is reasonable (not too large)
    if [[ "$issue_number" -gt 999999 ]]; then
        log_error "Issue number too large: $issue_number"
        return 1
    fi

    return 0
}

# Check if GitHub CLI is available
check_github_cli() {
    if ! check_command "gh"; then
        log_error "GitHub CLI (gh) is required but not installed."
        log_info "Install it from: https://cli.github.com/"
        return 1
    fi

    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated."
        log_info "Run: gh auth login"
        return 1
    fi

    return 0
}

# Fetch issue details from GitHub
fetch_issue() {
    local issue_number="$1"
    local format="${2:-json}"

    if ! validate_issue_number "$issue_number"; then
        return 1
    fi

    if ! check_github_cli; then
        return 1
    fi

    local issue_data
    case "$format" in
        json)
            issue_data=$(gh issue view "$issue_number" --json number,title,body,labels,assignees,milestone,state,createdAt,updatedAt,url 2>/dev/null)
            ;;
        raw)
            issue_data=$(gh issue view "$issue_number" 2>/dev/null)
            ;;
        *)
            log_error "Invalid format: $format. Use 'json' or 'raw'"
            return 1
            ;;
    esac

    if [[ $? -ne 0 ]] || [[ -z "$issue_data" ]]; then
        log_error "Failed to fetch issue #$issue_number"
        return 1
    fi

    echo "$issue_data"
}

# Extract issue title from JSON
get_issue_title() {
    local issue_json="$1"
    echo "$issue_json" | jq -r '.title // empty'
}

# Extract issue body from JSON
get_issue_body() {
    local issue_json="$1"
    echo "$issue_json" | jq -r '.body // empty'
}

# Extract issue labels from JSON
get_issue_labels() {
    local issue_json="$1"
    echo "$issue_json" | jq -r '.labels[]?.name // empty'
}

# Extract issue URL from JSON
get_issue_url() {
    local issue_json="$1"
    echo "$issue_json" | jq -r '.url // empty'
}

# Extract issue state from JSON
get_issue_state() {
    local issue_json="$1"
    echo "$issue_json" | jq -r '.state // empty'
}

# Extract issue creation date from JSON
get_issue_created_date() {
    local issue_json="$1"
    echo "$issue_json" | jq -r '.createdAt // empty' | cut -d'T' -f1
}

# Check if issue has specific label
has_label() {
    local issue_json="$1"
    local label="$2"
    local labels
    labels=$(get_issue_labels "$issue_json")
    echo "$labels" | grep -q "^$label$"
}

# Get repository name
get_repo_name() {
    if ! check_git_repo; then
        return 1
    fi

    local repo_info
    repo_info=$(gh repo view --json name,owner 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        log_error "Failed to get repository information"
        return 1
    fi

    local owner name
    owner=$(echo "$repo_info" | jq -r '.owner.login')
    name=$(echo "$repo_info" | jq -r '.name')

    echo "$owner/$name"
}

# Get repository URL
get_repo_url() {
    if ! check_git_repo; then
        return 1
    fi

    local repo_info
    repo_info=$(gh repo view --json url 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        log_error "Failed to get repository URL"
        return 1
    fi

    echo "$repo_info" | jq -r '.url'
}
