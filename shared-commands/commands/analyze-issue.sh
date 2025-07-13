#!/bin/bash

# Analyze GitHub issue for requirements and scope
# Usage: ./shared-commands/commands/analyze-issue.sh --issue NUMBER
# Provides comprehensive analysis of GitHub issues including complexity assessment

set -e

# Get script directory and source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common-utils.sh"
source "$SCRIPT_DIR/../lib/github-utils.sh"
source "$SCRIPT_DIR/../lib/markdown-utils.sh"

# Command configuration
COMMAND_NAME="analyze-issue"
DESCRIPTION="Analyzes GitHub issue for requirements, scope, and implementation considerations."

# Parse command line arguments
if ! parse_analysis_args "$@"; then
    exit 1
fi

# Show help if requested
if [[ "$PARSED_HELP" == "true" ]]; then
    show_analysis_help "$COMMAND_NAME" "$DESCRIPTION"
    exit 0
fi

# Validate required arguments
if [[ -z "$PARSED_ISSUE" ]]; then
    log_error "Issue number is required"
    show_analysis_help "$COMMAND_NAME" "$DESCRIPTION"
    exit 1
fi

issue_number="$PARSED_ISSUE"
generate_docs="${PARSED_GENERATE_DOCS:-false}"
update_existing="${PARSED_UPDATE_EXISTING:-false}"

# Main execution
main() {
    log_info "Analyzing issue #$issue_number..."

    # Fetch issue data
    local issue_json
    if ! issue_json=$(fetch_issue "$issue_number" "json"); then
        exit 1
    fi

    # Extract issue information
    local issue_title issue_body issue_url issue_created_date labels state
    issue_title=$(get_issue_title "$issue_json")
    issue_body=$(get_issue_body "$issue_json")
    issue_url=$(get_issue_url "$issue_json")
    issue_created_date=$(get_issue_created_date "$issue_json")
    labels=$(get_issue_labels "$issue_json")
    state=$(get_issue_state "$issue_json")

    # Perform analysis
    analyze_issue_content
}

# Analyze the issue content and provide insights
analyze_issue_content() {
    log_info "Issue Analysis Results:"
    echo

    # Basic information
    echo "📋 **Issue #$issue_number**: $issue_title"
    echo "🔗 **URL**: $issue_url"
    echo "📅 **Created**: $issue_created_date"
    echo "🏷️  **Status**: $state"
    echo

    # Labels analysis
    echo "🏷️  **Labels**:"
    if [[ -n "$labels" ]]; then
        while IFS= read -r label; do
            echo "   - $label"
            analyze_label "$label"
        done <<< "$labels"
    else
        echo "   - None"
    fi
    echo

    # Content analysis
    analyze_content "$issue_body"

    # Requirements extraction
    extract_requirements "$issue_body"

    # Complexity assessment
    assess_complexity "$issue_body" "$labels"

    # Recommendations
    provide_recommendations "$labels"
}

# Analyze individual labels
analyze_label() {
    local label="$1"

    case "$label" in
        "ai-task"|"ai-bug-fix"|"ai-refactor"|"ai-test"|"ai-docs")
            echo "     → AI workflow will be triggered"
            ;;
        "enhancement"|"feature")
            echo "     → New feature development"
            ;;
        "bug")
            echo "     → Bug fix required"
            ;;
        "documentation")
            echo "     → Documentation update needed"
            ;;
        "security")
            echo "     → Security considerations required"
            ;;
        "performance")
            echo "     → Performance optimization"
            ;;
        "breaking-change")
            echo "     → ⚠️  Breaking change - requires careful planning"
            ;;
        "high-priority"|"urgent")
            echo "     → ⚡ High priority item"
            ;;
    esac
}

# Analyze content for patterns and keywords
analyze_content() {
    local content="$1"

    echo "📝 **Content Analysis**:"

    # Check for specific patterns
    local has_acceptance_criteria=false
    local has_technical_details=false
    local has_examples=false
    local has_dependencies=false

    if echo "$content" | grep -qi "acceptance criteria\|definition of done\|requirements"; then
        has_acceptance_criteria=true
        echo "   ✅ Contains acceptance criteria or requirements"
    fi

    if echo "$content" | grep -qi "api\|endpoint\|database\|schema\|architecture"; then
        has_technical_details=true
        echo "   ✅ Contains technical details"
    fi

    if echo "$content" | grep -qi "example\|sample\|demo\|mockup"; then
        has_examples=true
        echo "   ✅ Contains examples or mockups"
    fi

    if echo "$content" | grep -qi "depends on\|requires\|blocked by\|prerequisite"; then
        has_dependencies=true
        echo "   ⚠️  Contains dependency references"
    fi

    # Quality assessment
    if [[ "$has_acceptance_criteria" == false ]]; then
        echo "   ❌ Missing clear acceptance criteria"
    fi

    if [[ "$has_technical_details" == false ]]; then
        echo "   ❌ Missing technical implementation details"
    fi

    echo
}

# Extract requirements from the content
extract_requirements() {
    local content="$1"

    echo "📋 **Extracted Requirements**:"

    # Look for bullet points, numbered lists, or requirement keywords
    local requirements
    requirements=$(echo "$content" | grep -E "^[\s]*[-*+]|^[\s]*[0-9]+\.|must|should|shall|will" | head -10)

    if [[ -n "$requirements" ]]; then
        while IFS= read -r req; do
            # Clean up the requirement text
            req=$(echo "$req" | sed 's/^[\s]*[-*+0-9.]\+[\s]*//' | sed 's/^[\s]*//')
            if [[ -n "$req" ]]; then
                echo "   - $req"
            fi
        done <<< "$requirements"
    else
        echo "   - No explicit requirements found in bullet/numbered format"
        echo "   - Consider adding structured requirements for clarity"
    fi
    echo
}

# Assess implementation complexity
assess_complexity() {
    local content="$1"
    local labels="$2"

    echo "🎯 **Complexity Assessment**:"

    local complexity_score=0
    local complexity_factors=()

    # Check content for complexity indicators
    if echo "$content" | grep -qi "database\|migration\|schema"; then
        complexity_score=$((complexity_score + 2))
        complexity_factors+=("Database changes required")
    fi

    if echo "$content" | grep -qi "api\|endpoint\|integration"; then
        complexity_score=$((complexity_score + 2))
        complexity_factors+=("API development/integration")
    fi

    if echo "$content" | grep -qi "authentication\|authorization\|security"; then
        complexity_score=$((complexity_score + 3))
        complexity_factors+=("Security implementation")
    fi

    if echo "$content" | grep -qi "testing\|test\|qa"; then
        complexity_score=$((complexity_score + 1))
        complexity_factors+=("Testing requirements")
    fi

    if echo "$content" | grep -qi "performance\|optimization\|scaling"; then
        complexity_score=$((complexity_score + 2))
        complexity_factors+=("Performance considerations")
    fi

    # Check labels for complexity indicators
    if echo "$labels" | grep -q "breaking-change"; then
        complexity_score=$((complexity_score + 3))
        complexity_factors+=("Breaking change impact")
    fi

    if echo "$labels" | grep -q "enhancement\|feature"; then
        complexity_score=$((complexity_score + 1))
        complexity_factors+=("New feature development")
    fi

    # Determine complexity level
    local complexity_level
    if [[ $complexity_score -le 2 ]]; then
        complexity_level="🟢 Low"
    elif [[ $complexity_score -le 5 ]]; then
        complexity_level="🟡 Medium"
    elif [[ $complexity_score -le 8 ]]; then
        complexity_level="🟠 High"
    else
        complexity_level="🔴 Very High"
    fi

    echo "   **Level**: $complexity_level (Score: $complexity_score)"

    if [[ ${#complexity_factors[@]} -gt 0 ]]; then
        echo "   **Factors**:"
        for factor in "${complexity_factors[@]}"; do
            echo "      - $factor"
        done
    fi
    echo
}

# Provide implementation recommendations
provide_recommendations() {
    local labels="$1"

    echo "💡 **Recommendations**:"

    # Check if it's an AI task
    if echo "$labels" | grep -q "ai-task\|ai-bug-fix\|ai-refactor\|ai-test\|ai-docs"; then
        echo "   🤖 AI workflow will handle implementation automatically"
        echo "      - Ensure issue description is clear and detailed"
        echo "      - Consider breaking down complex requirements"
    fi

    # Documentation recommendations
    if [[ ! -f "user-stories/issue-${issue_number}-"* ]]; then
        echo "   📝 Consider creating a user story: user-story-this --issue $issue_number"
    fi

    if [[ ! -f "specs/issue-${issue_number}-"* ]]; then
        echo "   📋 Consider creating a technical spec: spec-this --issue $issue_number"
    fi

    # Development recommendations
    echo "   🛠️  Development approach:"
    if echo "$labels" | grep -q "breaking-change"; then
        echo "      - Plan for backward compatibility or migration strategy"
        echo "      - Update documentation and version numbers"
        echo "      - Coordinate with stakeholders for rollout"
    fi

    if echo "$labels" | grep -q "security"; then
        echo "      - Conduct security review before implementation"
        echo "      - Consider threat modeling"
        echo "      - Plan for security testing"
    fi

    echo "   📊 Quality assurance recommendations:"
    echo "      - Define test cases before implementation"
    echo "      - Consider performance impact"
    echo "      - Plan for monitoring and observability"

    echo "   🔄 Process:"
    echo "      - Create feature branch for implementation"
    echo "      - Use small, focused commits"
    echo "      - Request peer review before merging"

    echo
}

# Execute main function
main "$@"
