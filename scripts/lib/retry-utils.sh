#!/bin/bash

# Retry Utility Library with Exponential Backoff
# Provides robust retry mechanisms for AI workflows
#
# Features:
# - Configurable retry attempts with exponential backoff
# - Support for different error types and retry strategies
# - Rate limit handling with respect for reset times
# - Circuit breaker integration
# - Comprehensive logging and error classification

set -euo pipefail

# Default configuration
DEFAULT_MAX_RETRIES=3
DEFAULT_BASE_DELAY=1
DEFAULT_MAX_DELAY=60
DEFAULT_BACKOFF_MULTIPLIER=2
DEFAULT_JITTER_ENABLED=true

# Error type classifications (with guard to prevent redefinition)
if [[ -z "${ERROR_TYPE_NETWORK:-}" ]]; then
    readonly ERROR_TYPE_NETWORK=1
    readonly ERROR_TYPE_RATE_LIMIT=2
    readonly ERROR_TYPE_AUTH=3
    readonly ERROR_TYPE_API=4
    readonly ERROR_TYPE_TIMEOUT=5
    readonly ERROR_TYPE_UNKNOWN=99
fi

# Configuration validation
validate_retry_config() {
    local max_retries="${1:-$DEFAULT_MAX_RETRIES}"
    local base_delay="${2:-$DEFAULT_BASE_DELAY}"
    local max_delay="${3:-$DEFAULT_MAX_DELAY}"

    # Validate max_retries (1-10)
    if [[ ! "$max_retries" =~ ^[0-9]+$ ]] || [[ "$max_retries" -lt 1 ]] || [[ "$max_retries" -gt 10 ]]; then
        echo "ERROR: max_retries must be between 1 and 10, got: $max_retries" >&2
        return 1
    fi

    # Validate base_delay (1-30 seconds)
    if [[ ! "$base_delay" =~ ^[0-9]+$ ]] || [[ "$base_delay" -lt 1 ]] || [[ "$base_delay" -gt 30 ]]; then
        echo "ERROR: base_delay must be between 1 and 30 seconds, got: $base_delay" >&2
        return 1
    fi

    # Validate max_delay (60-300 seconds)
    if [[ ! "$max_delay" =~ ^[0-9]+$ ]] || [[ "$max_delay" -lt 60 ]] || [[ "$max_delay" -gt 300 ]]; then
        echo "ERROR: max_delay must be between 60 and 300 seconds, got: $max_delay" >&2
        return 1
    fi

    # Ensure max_delay >= base_delay
    if [[ "$max_delay" -lt "$base_delay" ]]; then
        echo "ERROR: max_delay ($max_delay) must be >= base_delay ($base_delay)" >&2
        return 1
    fi

    return 0
}

# Calculate exponential backoff delay with jitter
calculate_backoff_delay() {
    local attempt="$1"
    local base_delay="${2:-$DEFAULT_BASE_DELAY}"
    local max_delay="${3:-$DEFAULT_MAX_DELAY}"
    local multiplier="${4:-$DEFAULT_BACKOFF_MULTIPLIER}"
    local jitter_enabled="${5:-$DEFAULT_JITTER_ENABLED}"

    # Calculate exponential delay: base_delay * multiplier^(attempt-1)
    local delay=$base_delay
    for ((i=1; i<attempt; i++)); do
        delay=$((delay * multiplier))
    done

    # Cap at max_delay
    if [[ $delay -gt $max_delay ]]; then
        delay=$max_delay
    fi

    # Add jitter (±25% random variation) to avoid thundering herd
    if [[ "$jitter_enabled" == "true" ]]; then
        local jitter_range=$((delay / 4))  # 25% of delay
        local jitter=$((RANDOM % (jitter_range * 2 + 1) - jitter_range))
        delay=$((delay + jitter))

        # Ensure delay is positive and doesn't exceed max
        if [[ $delay -lt 1 ]]; then
            delay=1
        elif [[ $delay -gt $max_delay ]]; then
            delay=$max_delay
        fi
    fi

    echo $delay
}

# Classify error type based on exit code and error message
classify_error() {
    local exit_code="$1"
    local error_output="${2:-}"

    # Network connectivity issues
    if [[ $exit_code -eq 6 ]] || [[ $exit_code -eq 7 ]] || [[ $exit_code -eq 28 ]] ||
       echo "$error_output" | grep -qi "network\|connection\|timeout\|dns\|unreachable"; then
        echo $ERROR_TYPE_NETWORK
        return
    fi

    # Authentication failures (HTTP 401, 403) - check before rate limiting for exit code 22
    if echo "$error_output" | grep -qi "unauthorized\|401\|403\|authentication\|invalid.key\|expired.token\|permission.denied"; then
        echo $ERROR_TYPE_AUTH
        return
    fi

    # Rate limiting (HTTP 429, API quotas)
    if [[ $exit_code -eq 22 ]] || echo "$error_output" | grep -qi "rate.limit\|429\|quota.exceeded\|too.many.requests"; then
        echo $ERROR_TYPE_RATE_LIMIT
        return
    fi

    # API errors (HTTP 4xx, 5xx) - check after auth errors
    if [[ $exit_code -eq 22 ]] || echo "$error_output" | grep -qi "api.error\|server.error\|5[0-9][0-9]\|4[0-9][0-9]"; then
        echo $ERROR_TYPE_API
        return
    fi

    # Timeout errors
    if [[ $exit_code -eq 124 ]] || echo "$error_output" | grep -qi "timed.out\|timeout"; then
        echo $ERROR_TYPE_TIMEOUT
        return
    fi

    # Unknown error type
    echo $ERROR_TYPE_UNKNOWN
}

# Check if error type should be retried
is_retryable_error() {
    local error_type="$1"

    case $error_type in
        $ERROR_TYPE_NETWORK)    return 0 ;;  # Retry network issues
        $ERROR_TYPE_RATE_LIMIT) return 0 ;;  # Retry rate limits with backoff
        $ERROR_TYPE_API)        return 0 ;;  # Retry API errors (may be temporary)
        $ERROR_TYPE_TIMEOUT)    return 0 ;;  # Retry timeouts
        $ERROR_TYPE_AUTH)       return 1 ;;  # Don't retry auth failures
        $ERROR_TYPE_UNKNOWN)    return 0 ;;  # Retry unknown errors (conservative)
        *)                      return 1 ;;  # Don't retry by default
    esac
}

# Extract rate limit reset time from error output
get_rate_limit_reset_time() {
    local error_output="$1"

    # Look for various rate limit reset patterns
    local reset_time=""

    # X-RateLimit-Reset header (Unix timestamp)
    if reset_time=$(echo "$error_output" | grep -oi "x-ratelimit-reset: [0-9]*" | cut -d' ' -f2); then
        echo "$reset_time"
        return
    fi

    # Retry-After header (seconds)
    if reset_time=$(echo "$error_output" | grep -oi "retry-after: [0-9]*" | cut -d' ' -f2); then
        echo $(($(date +%s) + reset_time))
        return
    fi

    # Common rate limit messages with time
    if reset_time=$(echo "$error_output" | grep -oi "try again in [0-9]* seconds" | grep -o "[0-9]*"); then
        echo $(($(date +%s) + reset_time))
        return
    fi

    # Default: no reset time found
    echo ""
}

# Wait for rate limit reset
wait_for_rate_limit_reset() {
    local reset_time="$1"
    local current_time=$(date +%s)

    if [[ -n "$reset_time" && "$reset_time" =~ ^[0-9]+$ ]]; then
        local wait_time=$((reset_time - current_time))

        if [[ $wait_time -gt 0 && $wait_time -le 300 ]]; then  # Max 5 minutes
            echo "🕒 Rate limit active. Waiting ${wait_time}s until reset ($(date -d "@$reset_time" 2>/dev/null || date -r "$reset_time" 2>/dev/null || echo "unknown"))"
            sleep "$wait_time"
            return 0
        fi
    fi

    return 1
}

# Log retry attempt with structured information
log_retry_attempt() {
    local attempt="$1"
    local max_retries="$2"
    local error_type="$3"
    local delay="$4"
    local exit_code="$5"
    local error_message="${6:-}"

    local error_type_name=""
    case $error_type in
        $ERROR_TYPE_NETWORK)    error_type_name="NETWORK" ;;
        $ERROR_TYPE_RATE_LIMIT) error_type_name="RATE_LIMIT" ;;
        $ERROR_TYPE_AUTH)       error_type_name="AUTH" ;;
        $ERROR_TYPE_API)        error_type_name="API" ;;
        $ERROR_TYPE_TIMEOUT)    error_type_name="TIMEOUT" ;;
        *)                      error_type_name="UNKNOWN" ;;
    esac

    echo "🔄 Retry attempt $attempt/$max_retries - Error: $error_type_name (exit: $exit_code) - Waiting ${delay}s"

    if [[ -n "$error_message" ]]; then
        echo "   Error details: $(echo "$error_message" | head -1 | cut -c1-100)"
    fi
}

# Main retry function with comprehensive error handling
retry_with_backoff() {
    local command="$1"
    local max_retries="${2:-$DEFAULT_MAX_RETRIES}"
    local base_delay="${3:-$DEFAULT_BASE_DELAY}"
    local max_delay="${4:-$DEFAULT_MAX_DELAY}"
    local multiplier="${5:-$DEFAULT_BACKOFF_MULTIPLIER}"
    local jitter_enabled="${6:-$DEFAULT_JITTER_ENABLED}"

    # Validate configuration
    if ! validate_retry_config "$max_retries" "$base_delay" "$max_delay"; then
        return 1
    fi

    local attempt=1
    local last_exit_code=0
    local error_output=""
    local temp_error_file=""

    # Create temporary file for error output
    temp_error_file=$(mktemp)
    trap "rm -f '$temp_error_file'" RETURN

    echo "🚀 Executing command with retry: $command"
    echo "   Max retries: $max_retries, Base delay: ${base_delay}s, Max delay: ${max_delay}s"

    while [[ $attempt -le $max_retries ]]; do
        echo ""
        echo "📝 Attempt $attempt/$max_retries: $(date)"

        # Execute command and capture exit code and error output
        if eval "$command" 2>"$temp_error_file"; then
            echo "✅ Command succeeded on attempt $attempt"
            return 0
        else
            last_exit_code=$?
            error_output=$(cat "$temp_error_file" 2>/dev/null || echo "")
        fi

        # If this was the last attempt, don't retry
        if [[ $attempt -eq $max_retries ]]; then
            echo "❌ Command failed after $max_retries attempts (final exit code: $last_exit_code)"
            echo "   Final error: $(echo "$error_output" | head -1)"
            return $last_exit_code
        fi

        # Classify error and determine if it should be retried
        local error_type
        error_type=$(classify_error "$last_exit_code" "$error_output")

        if ! is_retryable_error "$error_type"; then
            echo "❌ Non-retryable error detected (type: $error_type, exit: $last_exit_code)"
            echo "   Error: $(echo "$error_output" | head -1)"
            return $last_exit_code
        fi

        # Handle rate limiting specially
        if [[ $error_type -eq $ERROR_TYPE_RATE_LIMIT ]]; then
            local reset_time
            reset_time=$(get_rate_limit_reset_time "$error_output")

            if wait_for_rate_limit_reset "$reset_time"; then
                # Rate limit wait succeeded, try again immediately
                ((attempt++))
                continue
            fi
        fi

        # Calculate backoff delay
        local delay
        delay=$(calculate_backoff_delay "$attempt" "$base_delay" "$max_delay" "$multiplier" "$jitter_enabled")

        # Log retry attempt
        log_retry_attempt "$attempt" "$max_retries" "$error_type" "$delay" "$last_exit_code" "$error_output"

        # Wait before retry
        sleep "$delay"

        ((attempt++))
    done

    # This should never be reached, but just in case
    return $last_exit_code
}

# Convenience function for common Claude CLI retries
retry_claude_command() {
    local claude_command="$1"
    local max_retries="${2:-3}"

    # Use Claude-specific configuration
    retry_with_backoff \
        "$claude_command" \
        "$max_retries" \
        2 \
        120 \
        2 \
        true
}

# Convenience function for network operations
retry_network_command() {
    local network_command="$1"
    local max_retries="${2:-5}"

    # Use network-optimized configuration with longer delays
    retry_with_backoff \
        "$network_command" \
        "$max_retries" \
        1 \
        30 \
        2 \
        true
}

# Test function for retry mechanism
test_retry_mechanism() {
    local failure_count="${1:-2}"

    echo "🧪 Testing retry mechanism (will fail $failure_count times, then succeed)"

    local test_command="bash -c 'counter_file=\"/tmp/retry_test_counter\"; if [[ ! -f \"\$counter_file\" ]]; then echo \"0\" > \"\$counter_file\"; fi; count=\$(cat \"\$counter_file\"); ((count++)); echo \"\$count\" > \"\$counter_file\"; if [[ \$count -le $failure_count ]]; then echo \"Attempt \$count: Simulated failure\"; exit 1; else echo \"Attempt \$count: Success!\"; rm -f \"\$counter_file\"; exit 0; fi'"

    if retry_with_backoff "$test_command" 5 1 10 2 false; then
        echo "✅ Retry mechanism test passed"
        return 0
    else
        echo "❌ Retry mechanism test failed"
        return 1
    fi
}

# Export functions for use in other scripts
export -f retry_with_backoff
export -f retry_claude_command
export -f retry_network_command
export -f classify_error
export -f is_retryable_error
export -f validate_retry_config
export -f test_retry_mechanism
