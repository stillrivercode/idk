#!/bin/bash
set -euo pipefail

# OpenRouter AI Helper Script
# Provides AI assistance via OpenRouter API for GitHub workflows

# Configuration
REQUEST_TIMEOUT=180
MAX_RETRIES=5
RETRY_DELAY_SECONDS=5
BACKOFF_FACTOR=2

# Function to show usage
usage() {
    cat << EOF
Usage: $0 --prompt-file FILE --output-file FILE [OPTIONS]

Options:
    --prompt-file FILE     File containing the prompt (required)
    --output-file FILE     File to write the response (required)
    --model MODEL          AI model to use (default: anthropic/claude-3.5-sonnet)
    --title TITLE          Title for the request (default: AI Assistant)
    --validate-json        Validate if the response is valid JSON
    --help                 Show this help message

Environment Variables:
    OPENROUTER_API_KEY     Your OpenRouter API key (required)

EOF
}

# Function to validate JSON
validate_json() {
    local content="$1"
    if ! echo "$content" | jq empty 2>/dev/null; then
        echo "Invalid JSON response" >&2
        return 1
    fi
}

# Function to make API request with retries
make_api_request() {
    local prompt="$1"
    local model="$2"
    local title="$3"
    local validate_json_flag="$4"
    local output_file="$5"

    local retries=0
    local delay=$RETRY_DELAY_SECONDS

    while [[ $retries -lt $MAX_RETRIES ]]; do
        # Create JSON payload
        local json_payload
        json_payload=$(jq -n \
            --arg model "$model" \
            --arg prompt "$prompt" \
            --arg title "$title" \
            '{
                model: $model,
                messages: [{"role": "user", "content": $prompt}]
            }')

        # Make the API request
        local response
        local http_code

        response=$(curl -s -w "%{http_code}" \
            --max-time "$REQUEST_TIMEOUT" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $OPENROUTER_API_KEY" \
            -H "HTTP-Referer: https://github.com" \
            -H "X-Title: $title" \
            -d "$json_payload" \
            "https://openrouter.ai/api/v1/chat/completions")

        # Extract HTTP code and response body
        http_code="${response: -3}"
        response="${response%???}"

        # Check for success
        if [[ "$http_code" == "200" ]]; then
            # Extract content from response
            local content
            content=$(echo "$response" | jq -r '.choices[0].message.content // empty')

            if [[ -z "$content" ]]; then
                echo "Invalid API response: empty message content" >&2
                return 1
            fi

            # Validate JSON if requested
            if [[ "$validate_json_flag" == "true" ]]; then
                if ! validate_json "$content"; then
                    echo "Response is not valid JSON" >&2
                    return 1
                fi
            fi

            # Write response to output file
            echo "$content" > "$output_file"
            echo "AI response written to $output_file"
            return 0
        fi

        # Handle specific error codes
        case "$http_code" in
            429|500|502|503)
                echo "Retryable error ($http_code). Retrying in ${delay}s..." >&2
                sleep "$delay"
                retries=$((retries + 1))
                delay=$((delay * BACKOFF_FACTOR))
                ;;
            *)
                local error_msg
                error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"' 2>/dev/null || echo "HTTP $http_code")
                echo "API error: $http_code - $error_msg" >&2

                # Write error response to output file
                cat > "$output_file" << EOF
## ⚠️ AI Request Failed

Error: API error: $http_code - $error_msg

This could be due to:
- API rate limiting
- Large input size
- Temporary service issues

Please retry later or request manual assistance.
EOF
                return 1
                ;;
        esac
    done

    echo "Max retries exceeded. Failed to get AI response." >&2
    return 1
}

# Main function
main() {
    local prompt_file=""
    local output_file=""
    local model="anthropic/claude-3.5-sonnet"
    local title="AI Assistant"
    local validate_json_flag="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --prompt-file)
                prompt_file="$2"
                shift 2
                ;;
            --output-file)
                output_file="$2"
                shift 2
                ;;
            --model)
                model="$2"
                shift 2
                ;;
            --title)
                title="$2"
                shift 2
                ;;
            --validate-json)
                validate_json_flag="true"
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$prompt_file" ]]; then
        echo "Error: --prompt-file is required" >&2
        usage >&2
        exit 1
    fi

    if [[ -z "$output_file" ]]; then
        echo "Error: --output-file is required" >&2
        usage >&2
        exit 1
    fi

    # Check for API key
    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
        echo "OPENROUTER_API_KEY environment variable not set" >&2
        exit 1
    fi

    # Read the prompt
    if [[ ! -f "$prompt_file" ]]; then
        echo "Prompt file not found: $prompt_file" >&2
        exit 1
    fi

    local prompt
    prompt=$(cat "$prompt_file")

    # Check dependencies
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed" >&2
        exit 1
    fi

    if ! command -v curl >/dev/null 2>&1; then
        echo "Error: curl is required but not installed" >&2
        exit 1
    fi

    # Make the API request
    make_api_request "$prompt" "$model" "$title" "$validate_json_flag" "$output_file"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
