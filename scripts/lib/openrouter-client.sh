#!/bin/bash

# OpenRouter API Client Library
# Provides functions to interact with OpenRouter API for multi-model AI support
# Replaces Claude CLI dependencies with direct API integration

set -eo pipefail

# Load dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/error-handling.sh"
source "${SCRIPT_DIR}/retry-utils.sh"

# OpenRouter API Configuration
OPENROUTER_ENDPOINT="https://openrouter.ai/api/v1/chat/completions"

# Supported models with pricing (per 1M tokens - input:output)
# Using functions instead of associative arrays for compatibility
get_model_pricing() {
    local model="$1"
    case "$model" in
        "anthropic/claude-sonnet-4") echo "5.00:20.00" ;;
        "anthropic/claude-3.5-sonnet") echo "3.00:15.00" ;;
        "openai/gpt-4-turbo") echo "10.00:30.00" ;;
        "google/gemini-pro") echo "0.50:1.50" ;;
        "anthropic/claude-3-haiku") echo "0.25:1.25" ;;
        "anthropic/claude-3-opus") echo "15.00:75.00" ;;
        "openai/gpt-3.5-turbo") echo "0.50:1.50" ;;
        *) echo "" ;;
    esac
}

# Model capabilities matrix
get_model_capabilities() {
    local model="$1"
    case "$model" in
        "anthropic/claude-sonnet-4") echo "advanced_code,complex_analysis,superior_reasoning,enhanced_writing" ;;
        "anthropic/claude-3.5-sonnet") echo "code,analysis,reasoning,writing" ;;
        "openai/gpt-4-turbo") echo "code,analysis,reasoning,math,vision" ;;
        "google/gemini-pro") echo "analysis,reasoning,multilingual,vision" ;;
        "anthropic/claude-3-haiku") echo "speed,basic_tasks,simple_code" ;;
        "anthropic/claude-3-opus") echo "complex_reasoning,research,creative" ;;
        "openai/gpt-3.5-turbo") echo "speed,basic_tasks,simple_analysis" ;;
        *) echo "" ;;
    esac
}

# Global variable to store last response
OPENROUTER_RESPONSE=""
OPENROUTER_USAGE=""
OPENROUTER_COST=""

# Validate API inputs
validate_api_inputs() {
    local model="$1"
    local prompt="$2"
    local max_tokens="$3"
    local temperature="$4"

    # Check API key
    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
        log_error "OPENROUTER_API_KEY environment variable is required"
        return 1
    fi

    # Validate API key format
    if [[ ! "${OPENROUTER_API_KEY}" =~ ^sk-or-[a-zA-Z0-9_-]{32,}$ ]]; then
        log_error "Invalid OpenRouter API key format"
        return 1
    fi

    # Check prompt
    if [[ -z "$prompt" ]]; then
        log_error "Prompt cannot be empty"
        return 1
    fi

    # Validate model
    if [[ -z "$(get_model_pricing "$model")" ]]; then
        log_warn "Unknown model '$model', using default: $DEFAULT_MODEL"
        model="$DEFAULT_MODEL"
    fi

    # Validate numeric parameters
    if ! [[ "$max_tokens" =~ ^[0-9]+$ ]] || (( max_tokens <= 0 )); then
        log_error "max_tokens must be a positive integer"
        return 1
    fi

    if ! [[ "$temperature" =~ ^[0-9]*\.?[0-9]+$ ]] || (( $(echo "$temperature < 0" | bc -l) )) || (( $(echo "$temperature > 2" | bc -l) )); then
        log_error "temperature must be between 0 and 2"
        return 1
    fi

    return 0
}

# Prepare request payload
prepare_request_payload() {
    local model="$1"
    local prompt="$2"
    local max_tokens="$3"
    local temperature="$4"

    # Escape prompt for JSON
    local escaped_prompt
    escaped_prompt=$(printf '%s' "$prompt" | jq -Rs .)

    # Build JSON payload
    jq -n \
        --arg model "$model" \
        --argjson content "$escaped_prompt" \
        --argjson max_tokens "$max_tokens" \
        --argjson temperature "$temperature" \
        '{
            "model": $model,
            "messages": [{"role": "user", "content": $content}],
            "max_tokens": $max_tokens,
            "temperature": $temperature
        }'
}

# Prepare secure headers
prepare_secure_headers() {
    cat << EOF
Authorization: Bearer ${OPENROUTER_API_KEY}
Content-Type: application/json
HTTP-Referer: ${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-unknown/repo}
X-Title: AI Workflow Assistant
User-Agent: GitHub-Actions-AI-Workflow/1.0
EOF
}

# Process successful API response
process_successful_response() {
    local response="$1"

    # Validate JSON structure
    if ! echo "$response" | jq empty 2>/dev/null; then
        log_error "Invalid JSON response from OpenRouter API"
        return 1
    fi

    # Check for API errors
    local error_message
    error_message=$(echo "$response" | jq -r '.error.message // empty')
    if [[ -n "$error_message" ]]; then
        log_error "OpenRouter API error: $error_message"
        return 1
    fi

    # Extract content
    local content
    content=$(echo "$response" | jq -r '.choices[0].message.content // empty')
    if [[ -z "$content" ]]; then
        log_error "No content in OpenRouter API response"
        return 1
    fi

    # Extract usage information
    local usage
    usage=$(echo "$response" | jq -r '.usage // empty')

    # Store response globally
    OPENROUTER_RESPONSE="$content"
    OPENROUTER_USAGE="$usage"

    log_debug "Successfully processed OpenRouter response"
    return 0
}

# Execute API request with retry logic
execute_with_retry() {
    local request_data="$1"
    local model="$2"
    local attempt=1

    while [ $attempt -le $MAX_RETRIES ]; do
        log_debug "OpenRouter API attempt $attempt/$MAX_RETRIES for model: $model"

        local response
        local http_code
        local headers_file="/tmp/openrouter_headers_$$"

        # Prepare headers file
        prepare_secure_headers > "$headers_file"

        # Execute curl request
        response=$(curl -s -w "\n%{http_code}" \
            -X POST "$OPENROUTER_ENDPOINT" \
            -H @"$headers_file" \
            --connect-timeout 30 \
            --max-time 300 \
            -d "$request_data" 2>/dev/null)

        # Clean up headers file
        rm -f "$headers_file"

        # Extract HTTP code and response body
        http_code=$(echo "$response" | tail -n1)
        # Remove last line (compatible with macOS head)
        response=$(echo "$response" | sed '$d')

        # Handle response based on HTTP code
        case "$http_code" in
            200)
                if process_successful_response "$response"; then
                    log_info "OpenRouter API call successful (model: $model)"
                    return 0
                else
                    log_error "Failed to process successful response"
                    return 1
                fi
                ;;
            429|503|502|504)
                log_warn "Rate limited or server error (HTTP $http_code), retrying..."
                local delay=$((RETRY_DELAY_BASE ** attempt))
                log_debug "Waiting ${delay}s before retry..."
                sleep "$delay"
                ;;
            401|403)
                log_error "Authentication error (HTTP $http_code): Check OPENROUTER_API_KEY"
                return 1
                ;;
            400)
                log_error "Bad request (HTTP $http_code): $response"
                return 1
                ;;
            *)
                log_warn "Unexpected error (HTTP $http_code): $response"
                ;;
        esac

        ((attempt++))
    done

    log_error "All retry attempts failed for model: $model"
    return 1
}

# Main API call function
call_openrouter_api() {
    local model="${1:-$DEFAULT_MODEL}"
    local prompt="$2"
    local max_tokens="${3:-4000}"
    local temperature="${4:-0.1}"

    log_info "Calling OpenRouter API with model: $model"

    # Validate inputs
    if ! validate_api_inputs "$model" "$prompt" "$max_tokens" "$temperature"; then
        return 1
    fi

    # Prepare request payload
    local request_data
    if ! request_data=$(prepare_request_payload "$model" "$prompt" "$max_tokens" "$temperature"); then
        log_error "Failed to prepare request payload"
        return 1
    fi

    # Execute with retry logic
    if execute_with_retry "$request_data" "$model"; then
        # Calculate cost if usage data is available
        if [[ -n "$OPENROUTER_USAGE" ]]; then
            calculate_request_cost "$model" "$OPENROUTER_USAGE"
        fi
        return 0
    else
        return 1
    fi
}

# Calculate cost for the request
calculate_request_cost() {
    local model="$1"
    local usage="$2"

    if [[ -z "$usage" ]]; then
        log_warn "No usage data available for cost calculation"
        return 1
    fi

    local input_tokens output_tokens
    input_tokens=$(echo "$usage" | jq -r '.prompt_tokens // 0')
    output_tokens=$(echo "$usage" | jq -r '.completion_tokens // 0')

    if [[ "$input_tokens" == "0" && "$output_tokens" == "0" ]]; then
        log_warn "No token usage data in response"
        return 1
    fi

    # Get pricing for model
    local pricing="$(get_model_pricing "$model")"
    if [[ -z "$pricing" ]]; then
        pricing="$(get_model_pricing "$DEFAULT_MODEL")"
    fi
    local input_rate="${pricing%:*}"
    local output_rate="${pricing#*:}"

    # Calculate cost (rates are per 1M tokens)
    local input_cost output_cost total_cost
    input_cost=$(echo "scale=6; $input_tokens * $input_rate / 1000000" | bc -l)
    output_cost=$(echo "scale=6; $output_tokens * $output_rate / 1000000" | bc -l)
    total_cost=$(echo "scale=6; $input_cost + $output_cost" | bc -l)

    OPENROUTER_COST="$total_cost"

    log_info "Request cost: \$${total_cost} ($input_tokens input + $output_tokens output tokens)"
    return 0
}

# Get available models
get_available_models() {
    echo "Available OpenRouter models:"
    local models=(
        "anthropic/claude-sonnet-4"
        "anthropic/claude-3.5-sonnet"
        "openai/gpt-4-turbo"
        "google/gemini-pro"
        "anthropic/claude-3-haiku"
        "anthropic/claude-3-opus"
        "openai/gpt-3.5-turbo"
    )

    for model in "${models[@]}"; do
        local pricing="$(get_model_pricing "$model")"
        local capabilities="$(get_model_capabilities "$model")"
        echo "  $model - Pricing: $pricing (input:output per 1M tokens) - Capabilities: $capabilities"
    done
}

# Select best model for task type
select_model_for_task() {
    local task_type="$1"
    local preferred_model="${2:-}"

    # If preferred model is specified, validate it
    if [[ -n "$preferred_model" ]]; then
        local pricing="$(get_model_pricing "$preferred_model")"
        if [[ -n "$pricing" ]]; then
            echo "$preferred_model"
            return 0
        else
            log_error "Invalid model specified: $preferred_model"
            return 1
        fi
    fi

    # Select based on task type
    case "$task_type" in
        "code"|"coding"|"programming")
            echo "anthropic/claude-sonnet-4"
            ;;
        "analysis"|"reasoning")
            echo "anthropic/claude-sonnet-4"
            ;;
        "simple"|"quick"|"basic")
            echo "anthropic/claude-3-haiku"
            ;;
        "complex"|"research"|"creative")
            echo "anthropic/claude-sonnet-4"
            ;;
        "math"|"calculation")
            echo "openai/gpt-4-turbo"
            ;;
        "multilingual"|"translation")
            echo "google/gemini-pro"
            ;;
        *)
            echo "$DEFAULT_MODEL"
            ;;
    esac
}

# Multi-model execution with fallback models within OpenRouter
execute_ai_task_with_models() {
    local prompt="$1"
    local var_name="$2"
    local primary_model="${AI_MODEL:-$DEFAULT_MODEL}"
    local fallback_model="anthropic/claude-3-haiku"  # Cost-effective fallback

    # Try primary model
    if call_openrouter_api "$primary_model" "$prompt" 4000 0.1; then
        eval "$var_name=\"\$OPENROUTER_RESPONSE\""
        log_info "Successfully executed with primary model: $primary_model"
        return 0
    fi

    # Try fallback model if different
    if [[ "$primary_model" != "$fallback_model" ]]; then
        log_warn "Primary model failed, trying fallback: $fallback_model"
        if call_openrouter_api "$fallback_model" "$prompt" 4000 0.1; then
            eval "$var_name=\"\$OPENROUTER_RESPONSE\""
            log_info "Successfully executed with fallback model: $fallback_model"
            return 0
        fi
    fi

    log_error "All OpenRouter execution attempts failed"
    return 1
}


# Export key functions
export -f call_openrouter_api
export -f execute_ai_task_with_models
export -f get_available_models
export -f select_model_for_task
export -f calculate_request_cost
