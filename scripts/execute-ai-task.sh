#!/bin/bash

# Enhanced AI Task Execution Script with OpenRouter API
# Usage: ./execute-ai-task.sh <issue_number>
#
# This script provides:
# - Comprehensive retry logic with exponential backoff
# - Circuit breaker pattern integration
# - Detailed error classification and reporting
# - Prerequisite validation
# - Security-focused output sanitization
# - Cost estimation and monitoring
# - Robust cleanup with trap handlers

set -euo pipefail


# Usage message function
usage() {
    echo "Usage: $0 <issue_number>" >&2
    exit 1
}

# Validate arguments only when running as main script
validate_arguments() {
    if [[ $# -ne 1 ]]; then
        echo "Error: issue_number argument missing." >&2
        usage
    elif [[ ! $1 =~ ^[0-9]+$ ]]; then
        echo "Error: issue_number must be numeric." >&2
        usage
    fi
}

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Source all required libraries
source "$LIB_DIR/common.sh"
source "$LIB_DIR/retry-utils.sh"
source "$LIB_DIR/error-handling.sh"
source "$LIB_DIR/circuit-breaker-integration.sh"
source "$LIB_DIR/prerequisite-validation.sh"
source "$LIB_DIR/openrouter-client.sh"
source "$LIB_DIR/cost-estimator.sh"
source "$LIB_DIR/trap-handlers.sh"
source "$LIB_DIR/smart-file-parser.sh"
source "$LIB_DIR/memory-integration.sh"
source "$LIB_DIR/file-operations.sh"

# Set up standard trap handlers only when running as main script
setup_traps_if_main() {
    if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
        # Skip cleanup in GitHub Actions to avoid unbound variable issues
        if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
            log_info "🚀 GitHub Actions detected - skipping cleanup traps"
        else
            setup_standard_traps "execute-ai-task"
        fi
    fi
}
setup_traps_if_main

# Configuration Constants
readonly AI_MODEL="${AI_MODEL:-anthropic/claude-sonnet-4}"
readonly MAX_PROMPT_SIZE="${MAX_PROMPT_SIZE:-50000}"  # Can be overridden via GHA secret/variable
readonly MAX_RESPONSE_SIZE=50000

# File Context Configuration Constants
readonly MAX_CONTEXT_SIZE=4000
readonly MAX_FILE_SIZE_BYTES=10240  # Increased to 10KB since we have smart parsing
readonly MAX_FILE_LINES=20
readonly MAX_FILES_INCLUDED=3  # Allow more files since we're smarter about content

# Get issue details from GitHub API
get_issue_details() {
    local issue_number="$1"

    log_info "Fetching issue #${issue_number} details..."

    local issue_data
    issue_data=$(curl -s \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${issue_number}" 2>/dev/null)

    if [[ -z "$issue_data" ]] || echo "$issue_data" | jq -e '.message' >/dev/null 2>&1; then
        log_error "Failed to fetch issue details or issue not found"
        return 1
    fi

    echo "$issue_data"
}

# Build AI prompt from issue data
build_ai_prompt() {
    local title="$1"
    local body="$2"
    local labels="$3"

    # Load template and replace placeholders
    local template_file="$LIB_DIR/ai-prompt-template.txt"

    if [[ ! -f "$template_file" ]]; then
        log_error "AI prompt template not found: $template_file"
        return 1
    fi

    # Read template and safely replace placeholders
    local template
    template=$(<"$template_file")

    # Detect potential file modifications and include existing content
    local existing_files_context=""
    existing_files_context=$(build_existing_files_context "$title" "$body")

    # Build AI model context
    local ai_context=""
    ai_context=$(build_ai_context "$AI_MODEL")

    # Replace placeholders using bash string replacement
    # This is safer than sed for user-provided content
    template="${template//\{\{TITLE\}\}/$title}"
    template="${template//\{\{BODY\}\}/$body}"
    template="${template//\{\{LABELS\}\}/$labels}"
    template="${template//\{\{EXISTING_FILES_CONTEXT\}\}/$existing_files_context}"
    template="${template//\{\{AI_CONTEXT\}\}/$ai_context}"

    echo "$template"
}

# Function to build AI-specific context based on model being used
build_ai_context() {
    local model="$1"
    local context=""
    local context_files=()
    local model_name=""

    # Determine model name and appropriate context files
    if [[ "$model" =~ claude|anthropic ]]; then
        model_name="Claude"
        context_files=("CLAUDE.md" "$HOME/CLAUDE.md")
    elif [[ "$model" =~ gemini|google ]]; then
        model_name="Gemini"
        context_files=("GEMINI.md" "$HOME/GEMINI.md")
    elif [[ "$model" =~ gpt|openai ]]; then
        model_name="GPT"
        context_files=("GPT.md" "$HOME/GPT.md" "OPENAI.md" "$HOME/OPENAI.md")
    elif [[ "$model" =~ llama|meta ]]; then
        model_name="Llama"
        context_files=("LLAMA.md" "$HOME/LLAMA.md")
    else
        # For unknown models, try common patterns
        model_name="AI"
        context_files=("AI.md" "$HOME/AI.md" "CLAUDE.md" "$HOME/CLAUDE.md")
    fi

    log_debug "🤖 Building context for $model_name model ($model)"

    # Check each potential context file
    for context_file in "${context_files[@]}"; do
        if [[ -f "$context_file" ]]; then
            local file_type=""
            if [[ "$context_file" =~ ^/ ]]; then
                file_type="Global"
            else
                file_type="Project-Specific"
            fi

            local filename=$(basename "$context_file")
            log_debug "📖 Adding $file_type context from $filename"

            context+="

**$file_type Context ($filename):**
"
            context+="$(cat "$context_file")"
            context+="

"
            # Only use the first matching file for each type (project vs global)
            if [[ "$file_type" == "Project-Specific" ]]; then
                # Skip remaining project files
                while [[ "${context_files[0]}" != /* ]] && [[ ${#context_files[@]} -gt 0 ]]; do
                    context_files=("${context_files[@]:1}")
                done
            fi
        fi
    done

    # If no specific context files found, add basic context
    if [[ -z "$context" ]]; then
        context="

**Basic Context:**
This is an AI-powered workflow template repository using $model_name. Follow best practices and examine existing code patterns.

"
    fi

    echo "$context"
}

# Build context for existing files that might need modification
build_existing_files_context() {
    local title="$1"
    local body="$2"
    local context=""

    log_info "🔍 Analyzing issue for potential file modifications..."

    # Common files that might be referenced in issues
    local potential_files=(
        "README.md"
        "CONTRIBUTING.md"
        "package.json"
        "CHANGELOG.md"
        "LICENSE"
        "docs/"
        ".github/"
    )

    # Look for file references in title and body
    local combined_text="$title $body"
    local files_to_include=()

    # Check for explicit file mentions
    for file in "${potential_files[@]}"; do
        if [[ "$combined_text" =~ $file ]] && [[ -f "$file" || -d "$file" ]]; then
            files_to_include+=("$file")
        fi
    done

    # Add specific common files for certain types of requests
    if [[ "$combined_text" =~ (contributor|contribution|acknowledge|credit) ]]; then
        [[ -f "README.md" ]] && files_to_include+=("README.md")
        [[ -f "CONTRIBUTING.md" ]] && files_to_include+=("CONTRIBUTING.md")
    fi

    if [[ "$combined_text" =~ (version|release|package) ]]; then
        [[ -f "package.json" ]] && files_to_include+=("package.json")
        [[ -f "CHANGELOG.md" ]] && files_to_include+=("CHANGELOG.md")
    fi

    # Remove duplicates and limit to most relevant files using constants
    local unique_files=($(printf "%s\n" "${files_to_include[@]}" | sort -u | head -3))

    # Build context for each file with size constraints
    if [[ ${#unique_files[@]} -gt 0 ]]; then
        context+="\n\n**EXISTING FILES CONTEXT:**\n"
        context+="The following files currently exist and may need modification. Preserve their existing content unless explicitly changing it:\n\n"

        local current_context_size=0
        local files_included=0

        for file in "${unique_files[@]}"; do
            # Stop if we've reached the maximum files limit
            if [[ $files_included -ge $MAX_FILES_INCLUDED ]]; then
                context+="\n### Additional files exist but omitted to prevent prompt size issues: ${unique_files[@]:$files_included}\n"
                break
            fi

            if [[ -f "$file" ]]; then
                # Validate file type before including
                if ! validate_file_type "$file"; then
                    context+="\n### File \`$file\` exists but file type not allowed for context inclusion\n"
                    log_debug "📄 File type validation failed: $file"
                    continue
                fi

                local file_size
                file_size=$(wc -c < "$file" 2>/dev/null || echo "0")

                # Use smart parsing for better content extraction
                local remaining_context_budget=$((MAX_CONTEXT_SIZE - current_context_size))

                if [[ $remaining_context_budget -gt 500 ]]; then
                    # Use smart file parser to get intelligent content
                    local smart_content
                    smart_content=$(generate_smart_file_context "$file" "$combined_text" "$remaining_context_budget")
                    local smart_content_size=${#smart_content}

                    # Check if adding this smart content would exceed our context budget
                    if [[ $smart_content_size -gt 0 ]] && [[ $((current_context_size + smart_content_size + 100)) -lt $MAX_CONTEXT_SIZE ]]; then
                        context+="$smart_content"
                        current_context_size=$((current_context_size + smart_content_size + 100))
                        files_included=$((files_included + 1))
                        log_debug "📄 Including smart content for: $file ($file_size bytes, generated $smart_content_size chars of context)"
                    else
                        # Fallback to simple approach if smart parsing fails or is too large
                        if [[ $file_size -lt $MAX_FILE_SIZE_BYTES ]]; then
                            local file_preview
                            file_preview="$(cat "$file" | head -$MAX_FILE_LINES)"
                            local preview_size=${#file_preview}

                            if [[ $((current_context_size + preview_size + 200)) -lt $MAX_CONTEXT_SIZE ]]; then
                                context+="\n### Current content of \`$file\` (first $MAX_FILE_LINES lines):\n"
                                context+="\`\`\`\n"
                                context+="$file_preview"
                                context+="\n\`\`\`\n"
                                current_context_size=$((current_context_size + preview_size + 200))
                                files_included=$((files_included + 1))
                                log_debug "📄 Including fallback content for: $file ($file_size bytes, showing $preview_size chars)"
                            else
                                context+="\n### File \`$file\` exists (${file_size} bytes) - omitted to prevent prompt size issues\n"
                                log_debug "📄 File omitted for size: $file (would exceed context budget)"
                            fi
                        else
                            context+="\n### File \`$file\` exists (${file_size} bytes) - too large to include, examine manually\n"
                            log_debug "📄 File too large to include: $file ($file_size bytes, max: $MAX_FILE_SIZE_BYTES)"
                        fi
                    fi
                else
                    context+="\n### File \`$file\` exists (${file_size} bytes) - omitted due to context budget exhaustion\n"
                    log_debug "📄 File omitted: $file (context budget exhausted)"
                fi
            elif [[ -d "$file" ]]; then
                context+="\n### Directory \`$file\` exists - examine contents as needed\n"
                log_debug "📁 Directory exists: $file"
            fi
        done
    else
        log_debug "ℹ️ No existing files detected for modification context"
    fi

    # Final size check and truncation if needed using constant
    if [[ ${#context} -gt $MAX_CONTEXT_SIZE ]]; then
        context="${context:0:$MAX_CONTEXT_SIZE}\n\n... [Context truncated to prevent prompt size issues]"
        log_warn "⚠️ File context truncated to prevent prompt size issues (max: $MAX_CONTEXT_SIZE chars)"
    fi

    echo "$context"
}

# Process AI response and create files
process_ai_response() {
    local response="$1"
    local issue_number="$2"

    log_info "Processing AI response for issue #${issue_number}..."

    # Validate response size
    local response_size=${#response}
    if (( response_size > MAX_RESPONSE_SIZE )); then
        log_warn "Large AI response detected (${response_size} chars), truncating..."
        response="${response:0:$MAX_RESPONSE_SIZE}"
    fi

    # Create temporary response file for debugging only (not committed)
    local response_file="temp_ai_response_${issue_number}.md"

    # Ensure response is treated as text and handle encoding properly
    printf '%s\n' "$response" > "$response_file"

    # Register file for cleanup
    register_temp_file "$response_file"

    log_info "AI response processed (${#response} characters) - extracting code..."

    # Debug: Log first 500 characters of AI response for troubleshooting
    log_debug "AI Response Preview (first 500 chars): ${response:0:500}"

    # Process the AI response to extract and implement changes
    local changes_made=false

    # Extract and implement code blocks from the AI response
    log_info "🔄 Implementing AI suggestions..."

    # Extract and apply code blocks from the response
    if implement_code_blocks_from_response "$response" "$issue_number"; then
        changes_made=true
    else
        # If no code blocks were found, try intelligent response processing
        log_info "🔄 No code blocks found, attempting intelligent response processing..."
        if process_text_based_response "$response" "$issue_number"; then
            changes_made=true
        fi
    fi

    # Immediately clean up the temporary response file to prevent commits
    if [[ -f "$response_file" ]]; then
        rm -f "$response_file"
        log_debug "🗑️ Cleaned up temporary response file"
    fi

    # Check if any files were actually changed
    if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
        log_warn "ℹ️ No file changes detected after AI implementation"
        return 1
    else
        log_info "✅ File changes detected - implementation successful"
        return 0
    fi
}

# Improved function to extract and implement code blocks
implement_code_blocks_from_response() {
    local response="$1"
    local issue_number="$2"
    local changes_made=false

    log_info "📋 Extracting code blocks from AI response..."

    # Extract code blocks and try to determine file operations
    local in_code_block=false
    local current_file=""
    local code_content=""
    local block_language=""
    local blocks_found=0

    while IFS= read -r line; do
        # Detect code block end FIRST (before start detection)
        if [[ $line =~ ^\`\`\`$ ]] && [[ $in_code_block == true ]]; then
            in_code_block=false

            # Try to infer file path if missing but we have content and language
            if [[ -z "$current_file" ]] && [[ -n "$code_content" ]] && [[ -n "$block_language" ]]; then
                # Try to infer file name from content or language
                case "$block_language" in
                    "python"|"py")
                        if [[ $code_content =~ def[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
                            current_file="${BASH_REMATCH[1]}.py"
                        else
                            current_file="main.py"
                        fi
                        ;;
                    "javascript"|"js")
                        current_file="script.js"
                        ;;
                    "json")
                        if [[ $code_content =~ \"name\"[[:space:]]*: ]]; then
                            current_file="package.json"
                        else
                            current_file="config.json"
                        fi
                        ;;
                    "yaml"|"yml")
                        current_file="config.yml"
                        ;;
                    "markdown"|"md")
                        current_file="README.md"
                        ;;
                    # SECURITY: Removed bash/sh/shell inference to prevent RCE vulnerability
                    # Scripts must have explicit file paths specified by AI
                esac

                if [[ -n "$current_file" ]]; then
                    log_info "🔍 Inferred file path: $current_file (from language: $block_language)"
                fi
            fi

            # If we have a file path, try to apply the changes
            if [[ -n "$current_file" ]] && [[ -n "$code_content" ]]; then
                log_info "📝 Implementing code block #$blocks_found -> $current_file"

                # Validate file path (security check)
                if validate_file_path_security "$current_file" "$block_language"; then
                    # Handle edit blocks differently
                    if [[ "$block_language" == "edit" ]]; then
                        if apply_edit_operation "$current_file" "$code_content"; then
                            changes_made=true
                        fi
                    else
                        # Regular file creation/overwrite
                        if create_or_update_file "$current_file" "$code_content"; then
                            changes_made=true
                        fi
                    fi
                fi
            else
                if [[ -n "$code_content" ]]; then
                    log_debug "⚠️ Code block #$blocks_found has content but no file path specified (language: $block_language)"
                elif [[ -z "$current_file" ]]; then
                    log_debug "⚠️ Code block #$blocks_found has no file path (language: $block_language)"
                else
                    log_debug "⚠️ Code block #$blocks_found has file path '$current_file' but no content (language: $block_language)"
                fi
            fi

            current_file=""
            code_content=""
            block_language=""
            continue
        fi

        # Detect code block start - more flexible pattern matching
        if [[ $line =~ ^\`\`\`([[:space:]]*[a-zA-Z0-9_+.-]*)[[:space:]]*(.*)$ ]]; then
            in_code_block=true
            # Extract and clean language and file path
            local lang_and_path="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
            lang_and_path="${lang_and_path#"${lang_and_path%%[![:space:]]*}"}" # trim leading whitespace
            lang_and_path="${lang_and_path%"${lang_and_path##*[![:space:]]}"}" # trim trailing whitespace

            # Split on first space/tab to separate language from file path
            if [[ $lang_and_path =~ ^([a-zA-Z0-9_+.-]+)[[:space:]]+(.+)$ ]]; then
                # Language and file path provided
                block_language="${BASH_REMATCH[1]}"
                current_file="${BASH_REMATCH[2]}"

                # Clean up file path - remove quotes and extra whitespace
                current_file="$(echo "$current_file" | sed -E "s/^[[:space:]]*//;s/[[:space:]]*$//;s/^['\"\`]*//;s/['\"\`]*$//")"

            elif [[ $lang_and_path =~ ^([a-zA-Z0-9_+.-]+)$ ]]; then
                # Only language provided, no file path
                block_language="${BASH_REMATCH[1]}"
                current_file=""
            else
                # No recognizable language, treat as generic
                block_language=""
                current_file=""
            fi

            code_content=""
            ((blocks_found++))
            log_debug "Found code block #$blocks_found: language='$block_language', file='$current_file', raw='$lang_and_path'"
            continue
        fi

        # Collect code content when in a code block
        if [[ $in_code_block == true ]]; then
            code_content+="$line"$'\n'
        fi

    done <<< "$response"

    log_info "📊 Processing summary: Found $blocks_found code blocks total"

    if [[ $changes_made == true ]]; then
        log_info "✅ Successfully implemented code blocks from AI response"
        return 0
    else
        log_warn "⚠️ No implementable code blocks found in AI response"
        log_info "💡 Tip: AI must provide code blocks with this exact format:"
        log_info "   \`\`\`language path/to/file.ext"
        log_info "   [actual code content]"
        log_info "   \`\`\`"
        log_info "📊 Found $blocks_found total code blocks, but none had valid file paths"
        log_info "🔍 Common issues:"
        log_info "   - Missing space between language and file path"
        log_info "   - Using absolute paths (must be relative paths)"
        log_info "   - Using ../ in paths (security restriction)"
        log_info "   - Using temporary file names (temp_, tmp_, .tmp, .temp)"
        log_info "   - Supported languages: letters, numbers, underscore, plus, dash, dot"
        log_info "   - Example: \`\`\`python src/main.py"
        log_info "   - Example: \`\`\`javascript package.json"
        log_info "   - Example: \`\`\`yaml .github/workflows/test.yml"
        return 1
    fi
}

# Process text-based AI response when no code blocks are found
process_text_based_response() {
    local response="$1"
    local issue_number="$2"

    log_info "🤖 Processing text-based AI response with intelligent extraction..."

    # Note: Removed specific README/contributor processing in favor of generic AI reformatting below

    # Try to use OpenRouter API to reformat the response into proper code blocks
    log_info "🔄 Using AI to extract actionable changes from text response..."

    local extraction_prompt="You are a code extraction assistant. The following AI response contains implementation instructions but not in proper code block format. Please analyze the response and extract any file changes, then format them as proper code blocks with file paths.

Original AI Response:
---
$response
---

Please provide ONLY the extracted code blocks in this exact format:
\`\`\`language filepath
[complete file content]
\`\`\`

If no actual file changes are specified, respond with: NO_CHANGES_SPECIFIED

CRITICAL: You must provide complete file content, not just snippets or sections."

    local extracted_response
    if extracted_response=$(call_openrouter_api "$extraction_prompt" "$AI_MODEL"); then
        if [[ "$extracted_response" != "NO_CHANGES_SPECIFIED" ]] && [[ -n "$extracted_response" ]]; then
            log_info "✅ Successfully extracted code blocks from text response"
            # Try to implement the extracted code blocks
            if implement_code_blocks_from_response "$extracted_response" "$issue_number"; then
                return 0
            fi
        else
            log_info "ℹ️ AI confirmed no specific file changes in the response"
        fi
    else
        log_warn "⚠️ Failed to extract code blocks using AI"
    fi

    return 1
}


# Handle AI execution failure
handle_ai_execution_failure() {
    local issue_number="$1"

    log_error "AI execution failed for issue #${issue_number}"

    # Create failure comment on issue
    local comment_body="🚨 **AI Task Execution Failed**\n\nThe AI assistant was unable to complete this task. This could be due to:\n\n- API rate limits or service issues\n- Invalid or unclear requirements\n- Technical constraints\n\nPlease review the issue description and try again, or implement manually.\n\nGenerated by AI Workflow Assistant"

    # Post comment to GitHub issue
    curl -s -X POST \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${issue_number}/comments" \
        -d "$(jq -n --arg body "$comment_body" '{body: $body}')" >/dev/null

    return 1
}

# Main execution function with comprehensive error handling
main() {
    local issue_number="$1"
    local overall_exit_code=0

    echo "💰 COST WARNING: This AI task may incur API costs"
    echo "🔒 SECURITY: AI output will be sanitized to prevent data exposure"
    echo "⏰ TIMEOUT: Task limited to ${AI_EXECUTION_TIMEOUT_MINUTES:-10} minutes"
    echo "🤖 AI MODEL: $AI_MODEL"
    echo "📏 MAX PROMPT SIZE: ${MAX_PROMPT_SIZE} chars"
    log_info "🚀 Issue #$issue_number - $(date '+%Y-%m-%d %H:%M:%S')"

    # Initialize memory and validate prerequisites
    init_memory_system
    if ! validate_all_prerequisites "ai_operations" "github_operations"; then
        log_error "❌ Prerequisite validation failed - aborting execution"
        log_error "   Please resolve all critical errors before proceeding"
        exit 1
    fi

    # Get issue details
    local issue_data
    if ! issue_data=$(get_issue_details "$issue_number"); then
        log_error "❌ Failed to retrieve issue details"
        exit 1
    fi

    local title body labels
    title=$(echo "$issue_data" | jq -r '.title')
    body=$(echo "$issue_data" | jq -r '.body // ""')
    labels=$(echo "$issue_data" | jq -r '.labels[].name' | tr '\n' ',' | sed 's/,$//')

    log_info "📋 $title | 🏷️ $labels"

    # Save issue context to memory
    save_issue_context "$issue_number" "$title" "$body" "$labels"

    # Build AI prompt
    local prompt
    prompt=$(build_ai_prompt "$title" "$body" "$labels")
    local prompt_size=${#prompt}

    # Add detailed size reporting
    local title_size=${#title}
    local body_size=${#body}
    local labels_size=${#labels}

    log_info "📏 Prompt: ${prompt_size}/${MAX_PROMPT_SIZE} chars (title:${title_size} body:${body_size} labels:${labels_size})"

    if (( prompt_size > MAX_PROMPT_SIZE )); then
        log_error "❌ Prompt too large (${prompt_size} chars, max ${MAX_PROMPT_SIZE})"
        log_error "   Issue breakdown:"
        log_error "   - Title: ${title_size} chars"
        log_error "   - Description: ${body_size} chars"
        log_error "   - Labels: ${labels_size} chars"

        if (( body_size > 5000 )); then
            log_error "   💡 Issue description is very large (${body_size} chars)"
            log_error "      Consider breaking this into multiple smaller issues"
        fi

        log_error "   💡 Solutions:"
        log_error "      1. Break down the issue into smaller, focused tasks"
        log_error "      2. Reduce the issue description length"
        log_error "      3. Remove unnecessary details from the issue"
        log_error "      4. Create separate issues for different components"
        exit 1
    fi

    log_info "✅ Prompt generated (${prompt_size} chars)"

    # Execute AI task
    local response
    if execute_ai_task_with_models "$prompt" response; then
        log_info "✅ AI execution successful with response (${#response} characters)"

        # Process response
        if process_ai_response "$response" "$issue_number"; then
            log_info "✅ AI response processed successfully"

            # Update cost tracking if we have usage data
            if [[ -n "${OPENROUTER_USAGE:-}" ]]; then
                update_openrouter_cost_tracking "$AI_MODEL" "$prompt" "$OPENROUTER_USAGE"
            fi
        else
            log_error "❌ Failed to process AI response"
            handle_ai_execution_failure "$issue_number"
            overall_exit_code=1
        fi
    else
        log_error "❌ AI execution failed"
        handle_ai_execution_failure "$issue_number"
        overall_exit_code=1
    fi

    # Final status

    # Check for changes and set GitHub Actions output
    log_info "🔍 Checking for changes..."
    local untracked_files
    untracked_files="$(git ls-files --others --exclude-standard)"

    if git diff --quiet && git diff --cached --quiet && [[ -z "$untracked_files" ]]; then
        log_info "ℹ️  No changes detected - workflow completed without modifications"
        echo "has_changes=false" >> "${GITHUB_OUTPUT:-/dev/null}"
    else
        log_info "✅ Changes detected - proceeding with commit workflow"
        echo "has_changes=true" >> "${GITHUB_OUTPUT:-/dev/null}"
    fi

    log_info "🏁 #$issue_number complete - exit:$overall_exit_code"

    # Close memory session
    close_memory_session

    exit $overall_exit_code
}

# Execute main function with provided issue number only if script is run directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    validate_arguments "$@"
    main "$1"
fi
