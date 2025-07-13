#!/bin/bash

set -e

# Get script directory and source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

# Source utilities with error handling
if [[ ! -f "$SCRIPT_DIR/../lib/common-utils.sh" ]]; then
    echo "ERROR: common-utils.sh not found at $SCRIPT_DIR/../lib/common-utils.sh" >&2
    exit 1
fi
source "$SCRIPT_DIR/../lib/common-utils.sh"

# Verify ensure_directory function is available
if ! declare -f ensure_directory >/dev/null; then
    echo "ERROR: ensure_directory function not available from common-utils.sh" >&2
    exit 1
fi

COMMAND_NAME="roadmap"
DESCRIPTION="Displays the latest project roadmap or generates a new one."

# Function to generate a slug from title or goals
generate_slug() {
    local text="$1"
    echo "$text" | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/[^a-zA-Z0-9 ,.-]//g' | \
        sed 's/[, ][, ]*/-/g' | \
        sed 's/^-\+\|-\+$//g' | \
        cut -c1-50
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --generate)
            GENERATE="true"
            shift
            ;;
        --input)
            INPUT="$2"
            shift 2
            ;;
        --research-doc)
            RESEARCH_DOC="$2"
            shift 2
            ;;
        --title)
            TITLE="$2"
            shift 2
            ;;
        --output)
            OUTPUT="$2"
            shift 2
            ;;
        --help|-h)
            HELP="true"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Show help if requested
if [[ "$HELP" == "true" ]]; then
    echo "Usage: $COMMAND_NAME [--generate [--input \"GOALS\"] [--research-doc \"FILE\"] [--title \"TITLE\"]]"
    echo
    echo "$DESCRIPTION"
    echo
    echo "Options:"
    echo "  --generate      Generate a new roadmap."
    echo "  --input         (Optional) Comma-separated list of goals for the new roadmap."
    echo "  --research-doc  (Optional) Path to research document to extract insights from."
    echo "  --title         (Optional) Title for the roadmap. If not provided, generates from goals or research."
    echo "  --output        (Optional) Output file for the new roadmap."
    echo "                  If not specified, generates filename from title/goals."
    echo "  --help, -h      Show this help message."
    echo
    echo "Examples:"
    echo "  $COMMAND_NAME                                    # Display latest roadmap"
    echo "  $COMMAND_NAME --generate --input \"Goal A, Goal B\"  # Generate from goals"
    echo "  $COMMAND_NAME --generate --research-doc docs/research.md  # Generate from research"
    echo "  $COMMAND_NAME --generate --research-doc docs/research.md --title \"Q1 Roadmap\"  # With title"
    exit 0
fi

# Function to extract insights from research document
extract_research_insights() {
    local research_file="$1"
    
    if [[ ! -f "$research_file" ]]; then
        log_error "Research document not found: $research_file"
        exit 1
    fi
    
    # Log to stderr to avoid interfering with command substitution
    log_info "Extracting insights from research document: $research_file" >&2
    
    # Extract key insights, conclusions, and recommendations
    # Look for common patterns in research documents
    local insights=""
    
    # Extract from sections like "Key Findings", "Conclusions", "Recommendations"
    if grep -qi "key findings\|conclusions\|recommendations\|insights\|summary" "$research_file"; then
        insights=$(sed -n '/[Kk]ey [Ff]indings\|[Cc]onclusions\|[Rr]ecommendations\|[Ii]nsights\|[Ss]ummary/,/^#/p' "$research_file" | \
                   grep -E '^\s*[-*+]\s+|^\s*[0-9]+\.\s+' | \
                   sed 's/^\s*[-*+]\s*//; s/^\s*[0-9]*\.\s*//' | \
                   head -10)
    fi
    
    # If no structured insights found, extract bullet points and numbered lists
    if [[ -z "$insights" ]]; then
        insights=$(grep -E '^\s*[-*+]\s+|^\s*[0-9]+\.\s+' "$research_file" | \
                   sed 's/^\s*[-*+]\s*//; s/^\s*[0-9]*\.\s*//' | \
                   head -10)
    fi
    
    # Clean and format insights
    if [[ -n "$insights" ]]; then
        echo "$insights" | while IFS= read -r line; do
            # Remove markdown formatting and clean up
            clean_line=$(echo "$line" | sed 's/\*\*//g; s/__//g; s/`//g' | xargs)
            if [[ -n "$clean_line" && ${#clean_line} -gt 10 ]]; then
                echo "$clean_line"
            fi
        done | head -6  # Limit to 6 insights
    else
        log_warning "No structured insights found in research document" >&2
        echo "Analyze research findings,Implement key recommendations,Address identified challenges"
    fi
}

# Main execution
if [[ "$GENERATE" == "true" ]]; then
    # --- Generate Mode ---
    # Validate that we have either input or research document
    if [[ -z "$INPUT" && -z "$RESEARCH_DOC" ]]; then
        log_error "Either --input or --research-doc is required for --generate"
        exit 1
    fi

    # Handle input source - either direct input or research document
    if [[ -n "$RESEARCH_DOC" ]]; then
        # Extract insights from research document
        research_insights=$(extract_research_insights "$RESEARCH_DOC")
        if [[ -n "$INPUT" ]]; then
            # Combine research insights with additional input
            FINAL_INPUT="$research_insights,$INPUT"
        else
            # Use only research insights
            FINAL_INPUT="$research_insights"
        fi
    else
        # Use direct input only
        FINAL_INPUT="$INPUT"
    fi

    # Validate final input format and content
    if [[ -n "$FINAL_INPUT" ]]; then
        # Convert line breaks to commas if needed and clean up
        # Only process if there are actual line breaks
        if [[ "$FINAL_INPUT" == *$'\n'* ]]; then
            FINAL_INPUT=$(echo "$FINAL_INPUT" | tr '\n' ',' | sed 's/,\+/,/g; s/,$//g; s/^,//g')
        fi
        
        if [[ ! "$FINAL_INPUT" =~ ^[^,]+([[:space:]]*,[[:space:]]*[^,]+)*$ ]]; then
            log_error "Invalid input format. Use comma-separated goals without empty values."
            log_info "Example: --input \"Goal 1, Goal 2, Goal 3\""
            exit 1
        fi

        # Check minimum number of goals
        IFS=',' read -ra input_validation <<< "$FINAL_INPUT"
        if [[ ${#input_validation[@]} -lt 1 ]]; then
            log_error "At least one goal is required"
            exit 1
        fi

        # Validate each goal is not empty after trimming
        for goal in "${input_validation[@]}"; do
            # Trim whitespace
            goal="${goal#"${goal%%[![:space:]]*}"}"
            goal="${goal%"${goal##*[![:space:]]}"}"
            if [[ -z "$goal" ]]; then
                log_error "Empty goals are not allowed in input"
                exit 1
            fi
            if [[ ${#goal} -lt 3 ]]; then
                log_error "Goals must be at least 3 characters long: '$goal'"
                exit 1
            fi
        done
    else
        log_error "No valid input found from research document or --input parameter"
        exit 1
    fi

    template_path="$SCRIPT_DIR/../lib/templates/roadmap-template.md"
    if [[ ! -f "$template_path" ]]; then
        log_error "Roadmap template not found at $template_path"
        exit 1
    fi

    # Set roadmap title and description
    if [[ -n "$TITLE" ]]; then
        roadmap_title="$TITLE"
    else
        # Generate title from first goal
        IFS=',' read -ra goals_array <<< "$FINAL_INPUT"
        first_goal="${goals_array[0]#"${goals_array[0]%%[![:space:]]*}"}"
        first_goal="${first_goal%"${first_goal##*[![:space:]]}"}"
        roadmap_title="$first_goal"
    fi
    
    roadmap_description="This roadmap outlines the development plan for $roadmap_title, providing a structured approach to implementation across three phases."

    IFS=',' read -ra goals <<< "$FINAL_INPUT"
    
    # Generate detailed features for each phase
    phase1_features=""
    phase2_features=""
    phase3_features=""
    
    # Distribute goals across phases (1/3, 1/3, 1/3)
    total_goals=${#goals[@]}
    phase1_count=$(( (total_goals + 2) / 3 ))
    phase2_count=$(( (total_goals + 1) / 3 ))
    phase3_count=$(( total_goals - phase1_count - phase2_count ))
    
    # Phase 1 - Foundation/MVP features
    for (( i=0; i<phase1_count && i<total_goals; i++ )); do
        goal="${goals[i]#"${goals[i]%%[![:space:]]*}"}"
        goal="${goal%"${goal##*[![:space:]]}"}"
        phase1_features+="-   **${goal}:**\\n"
        phase1_features+="    -   **Implementation:** Core development and testing.\\n"
        phase1_features+="    -   **Integration:** Establish foundational components.\\n"
        phase1_features+="\\n"
    done
    
    # Phase 2 - Enhancement features  
    for (( i=phase1_count; i<phase1_count+phase2_count && i<total_goals; i++ )); do
        goal="${goals[i]#"${goals[i]%%[![:space:]]*}"}"
        goal="${goal%"${goal##*[![:space:]]}"}"
        phase2_features+="-   **${goal}:**\\n"
        phase2_features+="    -   **Enhancement:** Build upon Phase 1 foundation.\\n"
        phase2_features+="    -   **Optimization:** Improve performance and user experience.\\n"
        phase2_features+="\\n"
    done
    
    # Phase 3 - Advanced features
    for (( i=phase1_count+phase2_count; i<total_goals; i++ )); do
        goal="${goals[i]#"${goals[i]%%[![:space:]]*}"}"
        goal="${goal%"${goal##*[![:space:]]}"}"
        phase3_features+="-   **${goal}:**\\n"
        phase3_features+="    -   **Advanced Implementation:** Complex features and integrations.\\n"
        phase3_features+="    -   **User Experience:** Polish and advanced functionality.\\n"
        phase3_features+="\\n"
    done

    output_dir="$PROJECT_ROOT/dev-docs/roadmaps"
    ensure_directory "$output_dir"

    # Generate filename from title or goals
    if [[ -n "$OUTPUT" ]]; then
        output_file="$OUTPUT"
    else
        # Use title if provided, otherwise generate from goals
        if [[ -n "$TITLE" ]]; then
            slug=$(generate_slug "$TITLE")
        else
            # Generate title from first 2-3 goals
            IFS=',' read -ra goals_array <<< "$FINAL_INPUT"
            # Trim leading/trailing spaces from each goal
            title_text="${goals_array[0]#"${goals_array[0]%%[![:space:]]*}"}"
            title_text="${title_text%"${title_text##*[![:space:]]}"}"
            if [[ ${#goals_array[@]} -gt 1 ]]; then
                goal2="${goals_array[1]#"${goals_array[1]%%[![:space:]]*}"}"
                goal2="${goal2%"${goal2##*[![:space:]]}"}"
                title_text="$title_text $goal2"
            fi
            slug=$(generate_slug "$title_text")
        fi

        base_name="roadmap-$slug"
        output_file="$output_dir/${base_name}.md"

        # If file exists, add a counter to make it unique
        counter=1
        while [[ -f "$output_file" ]]; do
            output_file="$output_dir/${base_name}-${counter}.md"
            ((counter++))
        done
    fi

    log_info "Generating new roadmap at $output_file..."

    # Process template with proper newline handling
    sed -e "s/{{ROADMAP_TITLE}}/$(escape_sed "$roadmap_title")/g" \
        -e "s/{{ROADMAP_DESCRIPTION}}/$(escape_sed "$roadmap_description")/g" \
        -e "s/{{PHASE_1_NAME}}/Foundation \& Core Implementation/g" \
        -e "s/{{PHASE_1_GOAL}}/Establish the core infrastructure and deliver a Minimum Viable Product (MVP) with essential functionality./g" \
        -e "s/{{PHASE_2_NAME}}/Advanced \& Enhanced Features/g" \
        -e "s/{{PHASE_2_GOAL}}/Introduce more complex features and enhance the application's capabilities beyond the basic implementation./g" \
        -e "s/{{PHASE_3_NAME}}/Feature Expansion \& User Engagement/g" \
        -e "s/{{PHASE_3_GOAL}}/Broaden functionality, enhance user experience, and establish advanced features for comprehensive coverage./g" \
        "$template_path" | \
    sed -e "s/{{PHASE_1_FEATURES}}/$(escape_sed "$phase1_features")/g" \
        -e "s/{{PHASE_2_FEATURES}}/$(escape_sed "$phase2_features")/g" \
        -e "s/{{PHASE_3_FEATURES}}/$(escape_sed "$phase3_features")/g" > "$output_file"
    
    # Convert \n to actual newlines in the output
    sed -i.bak 's/\\n/\
/g' "$output_file" && rm -f "${output_file}.bak"

    log_success "New roadmap generated: $output_file"

else
    # --- Display Mode ---
    roadmap_dir="$PROJECT_ROOT/dev-docs/roadmaps"
    latest_roadmap=$(ls -1 "$roadmap_dir"/roadmap-*.md 2>/dev/null | sort -V | tail -n 1)

    if [[ -z "$latest_roadmap" ]]; then
        log_error "No roadmaps found in $roadmap_dir"
        exit 1
    fi

    log_info "Displaying latest roadmap: $latest_roadmap"
    echo
    cat "$latest_roadmap"
fi
