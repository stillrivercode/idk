#!/bin/bash

# GitHub Issue Creation Script
# Usage: ./create-issue.sh [options]
#
# This script creates GitHub issues with optional labels and templates.
# The ai-task label is NOT automatically added - users must explicitly request it.

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
TITLE=""
BODY=""
LABELS=""
ASSIGNEE=""
MILESTONE=""
PROJECT=""
TEMPLATE=""
DRY_RUN=false
INTERACTIVE=false

# Help function
show_help() {
    cat << EOF
GitHub Issue Creation Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -t, --title TITLE           Issue title (required)
    -b, --body BODY            Issue body/description
    -l, --labels LABELS        Comma-separated labels (e.g., "bug,priority-high")
    -a, --assignee USER        Assign to user
    -m, --milestone NUMBER     Milestone number
    -p, --project NUMBER       Project number
    --template TEMPLATE        Use issue template
    --ai-task                  Add ai-task label (explicit opt-in)
    --dry-run                  Show what would be created without creating
    -i, --interactive          Interactive mode for guided creation
    -h, --help                 Show this help

EXAMPLES:
    # Basic issue
    $0 -t "Fix login bug" -b "Users cannot log in with valid credentials"

    # Issue with labels (manual ai-task)
    $0 -t "Add user auth" -l "feature,backend" -b "Implement JWT authentication"

    # Issue with ai-task label (explicit opt-in)
    $0 -t "Refactor database layer" --ai-task -b "Clean up database connections"

    # Interactive mode
    $0 -i

    # Dry run to preview
    $0 -t "Test issue" --dry-run

LABELS:
    Available labels include:
    - feature, bug, enhancement, documentation
    - priority-high, priority-medium, priority-low
    - ai-task, ai-bug-fix, ai-refactor, ai-test, ai-docs
    - backend, frontend, api, database, security

    Note: The ai-task label is NOT added automatically.
    Use --ai-task flag to explicitly add it.

PREREQUISITES:
    - GitHub CLI (gh) must be installed and authenticated
    - Must be run from within a git repository
    - Repository must have Issues enabled

EOF
}

# Validate prerequisites
validate_prerequisites() {
    echo "🔍 Validating prerequisites..."

    # Check if gh CLI is available
    if ! command -v gh >/dev/null 2>&1; then
        echo "❌ GitHub CLI (gh) is not installed"
        echo "   Install it from: https://cli.github.com/"
        exit 1
    fi

    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "❌ Not in a git repository"
        echo "   Run this script from within your git repository"
        exit 1
    fi

    # Check if gh is authenticated
    if ! gh auth status >/dev/null 2>&1; then
        echo "❌ GitHub CLI is not authenticated"
        echo "   Run: gh auth login"
        exit 1
    fi

    # Check if repository has issues enabled
    local repo_info
    if ! repo_info=$(gh repo view --json hasIssuesEnabled 2>/dev/null); then
        echo "⚠️  Warning: Could not verify if repository has issues enabled"
    elif echo "$repo_info" | grep -q '"hasIssuesEnabled":false'; then
        echo "❌ Repository does not have Issues enabled"
        echo "   Enable Issues in repository settings"
        exit 1
    fi

    echo "✅ Prerequisites validated"
}

# Interactive mode for guided issue creation
interactive_mode() {
    echo "🎯 Interactive Issue Creation"
    echo "============================="
    echo ""

    # Get title
    while [[ -z "$TITLE" ]]; do
        read -p "📝 Issue title: " TITLE
        if [[ -z "$TITLE" ]]; then
            echo "   Title is required. Please enter a descriptive title."
        fi
    done

    # Get body/description
    echo ""
    echo "📄 Issue description (press Ctrl+D when done, or enter single line):"
    if command -v editor >/dev/null 2>&1; then
        echo "   (Or type 'editor' to open your default editor)"
    fi
    read -p "> " first_line

    if [[ "$first_line" == "editor" ]] && command -v editor >/dev/null 2>&1; then
        local temp_file
        temp_file=$(mktemp)
        editor "$temp_file"
        BODY=$(cat "$temp_file")
        rm -f "$temp_file"
    else
        BODY="$first_line"
        # Read additional lines if available
        while IFS= read -r line; do
            BODY="$BODY"$'\n'"$line"
        done
    fi

    # Get labels
    echo ""
    echo "🏷️  Labels (comma-separated, or press Enter for none):"
    echo "   Suggestions: feature, bug, enhancement, documentation"
    echo "   Priority: priority-high, priority-medium, priority-low"
    echo "   AI: ai-task, ai-bug-fix, ai-refactor, ai-test, ai-docs"
    read -p "> " LABELS

    # Ask about ai-task label specifically if not already included
    if [[ "$LABELS" != *"ai-task"* ]]; then
        echo ""
        echo "🤖 Add 'ai-task' label to trigger AI implementation? (y/N)"
        read -p "> " ai_task_choice
        if [[ "$ai_task_choice" =~ ^[Yy] ]]; then
            if [[ -n "$LABELS" ]]; then
                LABELS="$LABELS,ai-task"
            else
                LABELS="ai-task"
            fi
        fi
    fi

    # Get assignee
    echo ""
    echo "👤 Assignee (GitHub username, or press Enter for none):"
    read -p "> " ASSIGNEE

    # Preview before creation
    echo ""
    echo "📋 Issue Preview:"
    echo "=================="
    echo "Title: $TITLE"
    echo "Labels: ${LABELS:-none}"
    echo "Assignee: ${ASSIGNEE:-none}"
    echo ""
    echo "Description:"
    echo "------------"
    echo "$BODY"
    echo ""

    read -p "Create this issue? (Y/n): " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        echo "❌ Issue creation cancelled"
        exit 0
    fi
}

# Validate and process labels
process_labels() {
    if [[ -z "$LABELS" ]]; then
        return 0
    fi

    # Available labels (can be extended)
    local available_labels=(
        "feature" "bug" "enhancement" "documentation" "question"
        "priority-high" "priority-medium" "priority-low"
        "ai-task" "ai-bug-fix" "ai-refactor" "ai-test" "ai-docs"
        "backend" "frontend" "api" "database" "security"
        "good-first-issue" "help-wanted" "duplicate" "invalid" "wontfix"
    )

    # Convert comma-separated labels to array
    IFS=',' read -ra label_array <<< "$LABELS"

    # Validate each label
    local invalid_labels=()
    for label in "${label_array[@]}"; do
        label=$(echo "$label" | xargs)  # Trim whitespace
        if [[ ! " ${available_labels[*]} " =~ " $label " ]]; then
            invalid_labels+=("$label")
        fi
    done

    # Warn about invalid labels but don't block creation
    if [[ ${#invalid_labels[@]} -gt 0 ]]; then
        echo "⚠️  Warning: These labels may not exist in the repository:"
        printf '   - %s\n' "${invalid_labels[@]}"
        echo "   GitHub will create them automatically if they don't exist"
    fi

    # Show ai-task warning if present
    if [[ "$LABELS" == *"ai-task"* ]]; then
        echo "🤖 ai-task label detected - this will trigger AI implementation workflow"
    fi
}

# Create the GitHub issue
create_issue() {
    echo "🚀 Creating GitHub issue..."

    # Build gh issue create command
    local gh_cmd="gh issue create"

    # Add title
    gh_cmd="$gh_cmd --title \"$TITLE\""

    # Add body if provided
    if [[ -n "$BODY" ]]; then
        gh_cmd="$gh_cmd --body \"$BODY\""
    fi

    # Add labels if provided
    if [[ -n "$LABELS" ]]; then
        # Convert comma-separated to space-separated for gh CLI
        local formatted_labels
        formatted_labels=$(echo "$LABELS" | tr ',' ' ')
        gh_cmd="$gh_cmd --label \"$formatted_labels\""
    fi

    # Add assignee if provided
    if [[ -n "$ASSIGNEE" ]]; then
        gh_cmd="$gh_cmd --assignee \"$ASSIGNEE\""
    fi

    # Add milestone if provided
    if [[ -n "$MILESTONE" ]]; then
        gh_cmd="$gh_cmd --milestone \"$MILESTONE\""
    fi

    # Show command in dry run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "🔍 DRY RUN - Would execute:"
        echo "   $gh_cmd"
        echo ""
        echo "📋 Issue Details:"
        echo "   Title: $TITLE"
        echo "   Labels: ${LABELS:-none}"
        echo "   Assignee: ${ASSIGNEE:-none}"
        echo "   Milestone: ${MILESTONE:-none}"
        echo ""
        echo "   Body:"
        echo "   -----"
        echo "$BODY"
        return 0
    fi

    # Execute the command
    local issue_url
    if issue_url=$(eval "$gh_cmd" 2>&1); then
        echo "✅ Issue created successfully!"
        echo "   URL: $issue_url"

        # Extract issue number from URL for additional info
        local issue_number
        if [[ "$issue_url" =~ /([0-9]+)$ ]]; then
            issue_number="${BASH_REMATCH[1]}"
            echo "   Issue #: $issue_number"

            # Show additional info if ai-task label was added
            if [[ "$LABELS" == *"ai-task"* ]]; then
                echo ""
                echo "🤖 AI Task Workflow:"
                echo "   The ai-task label will trigger automated AI implementation"
                echo "   Monitor progress in the Actions tab of your repository"
                echo "   Expected timeline: 5-15 minutes for implementation"
            fi

            # Offer to open the issue
            echo ""
            read -p "🌐 Open issue in browser? (Y/n): " open_choice
            if [[ ! "$open_choice" =~ ^[Nn] ]]; then
                gh issue view "$issue_number" --web
            fi
        fi

        return 0
    else
        echo "❌ Failed to create issue:"
        echo "   $issue_url"
        return 1
    fi
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--title)
                TITLE="$2"
                shift 2
                ;;
            -b|--body)
                BODY="$2"
                shift 2
                ;;
            -l|--labels)
                LABELS="$2"
                shift 2
                ;;
            -a|--assignee)
                ASSIGNEE="$2"
                shift 2
                ;;
            -m|--milestone)
                MILESTONE="$2"
                shift 2
                ;;
            -p|--project)
                PROJECT="$2"
                shift 2
                ;;
            --template)
                TEMPLATE="$2"
                shift 2
                ;;
            --ai-task)
                if [[ -n "$LABELS" ]]; then
                    LABELS="$LABELS,ai-task"
                else
                    LABELS="ai-task"
                fi
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -i|--interactive)
                INTERACTIVE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "❌ Unknown option: $1"
                echo "   Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Main execution function
main() {
    echo "🎯 GitHub Issue Creator"
    echo "======================="
    echo ""

    # Parse arguments first
    parse_arguments "$@"

    # Validate prerequisites
    validate_prerequisites
    echo ""

    # Run interactive mode if requested
    if [[ "$INTERACTIVE" == "true" ]]; then
        interactive_mode
        echo ""
    fi

    # Validate required fields
    if [[ -z "$TITLE" ]]; then
        echo "❌ Error: Issue title is required"
        echo "   Use -t/--title to specify title or -i/--interactive for guided creation"
        exit 1
    fi

    # Process and validate labels
    process_labels
    echo ""

    # Create the issue
    if create_issue; then
        echo ""
        echo "🎉 Issue creation completed successfully!"

        # Show next steps
        echo ""
        echo "📚 Next Steps:"
        if [[ "$LABELS" == *"ai-task"* ]]; then
            echo "   • AI implementation will start automatically"
            echo "   • Monitor progress in GitHub Actions"
            echo "   • Review and test the generated PR when ready"
        else
            echo "   • Add ai-task label later to trigger AI implementation"
            echo "   • Assign the issue to team members as needed"
            echo "   • Add to project boards for tracking"
        fi
    else
        echo ""
        echo "❌ Issue creation failed"
        echo "   Check the error message above and try again"
        exit 1
    fi
}

# Execute main function with all arguments
main "$@"
