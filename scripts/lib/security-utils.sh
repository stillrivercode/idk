#!/bin/bash
# Security utility functions for AI workflows
# Version: 1.0.0

set -euo pipefail

# Security configuration
readonly SECURITY_VERSION="1.0.0"
readonly MAX_VALIDATIONS_PER_MINUTE=100
readonly VALIDATION_COUNT_FILE="/tmp/security_validation_count_$$"
readonly CACHE_DIR="/tmp/sanitized_cache_$$"
readonly SECURITY_LOG_FILE="${SECURITY_LOG_FILE:-security.log}"

# Initialize security utilities
init_security_utils() {
    echo "0" > "$VALIDATION_COUNT_FILE"
    mkdir -p "$CACHE_DIR"
    log_security_event "Security utilities initialized (version: $SECURITY_VERSION)" "INFO"
}

# Rate limiting for security validation functions
check_rate_limit() {
    local current_count
    current_count=$(cat "$VALIDATION_COUNT_FILE" 2>/dev/null || echo "0")

    if ((current_count > MAX_VALIDATIONS_PER_MINUTE)); then
        log_security_event "Rate limit exceeded: $current_count validations" "WARNING"
        return 1
    fi

    echo $((current_count + 1)) > "$VALIDATION_COUNT_FILE"
    return 0
}

# Structured security event logging
log_security_event() {
    local event="$1"
    local severity="${2:-INFO}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Structured JSON logging
    local log_entry
    log_entry=$(jq -n \
        --arg timestamp "$timestamp" \
        --arg severity "$severity" \
        --arg event "$event" \
        --arg version "$SECURITY_VERSION" \
        --arg process "$$" \
        '{timestamp: $timestamp, severity: $severity, event: $event, version: $version, process: $process}')

    echo "$log_entry" >> "$SECURITY_LOG_FILE"

    # Also log to stderr for immediate visibility
    echo "[$timestamp] SECURITY[$severity]: $event" >&2

    # Log to GitHub Actions if available
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        case "$severity" in
            "ERROR"|"CRITICAL")
                echo "::error::Security Event: $event"
                ;;
            "WARNING")
                echo "::warning::Security Event: $event"
                ;;
            *)
                echo "::notice::Security Event: $event"
                ;;
        esac
    fi
}

# Cache sanitized content to improve performance
cache_sanitized_content() {
    local input="$1"
    local sanitized="$2"
    local cache_key
    cache_key=$(echo "$input" | sha256sum | cut -d' ' -f1)

    echo "$sanitized" > "$CACHE_DIR/$cache_key"
}

get_cached_content() {
    local input="$1"
    local cache_key
    cache_key=$(echo "$input" | sha256sum | cut -d' ' -f1)

    if [[ -f "$CACHE_DIR/$cache_key" ]]; then
        cat "$CACHE_DIR/$cache_key"
        return 0
    fi

    return 1
}

# Enhanced sanitize_text with rate limiting and caching
sanitize_text() {
    local input="$1"
    local max_length="${2:-1000}"

    # Check rate limit
    if ! check_rate_limit; then
        log_security_event "Text sanitization rate limit exceeded" "ERROR"
        return 1
    fi

    # Check cache first
    local cached_result
    if cached_result=$(get_cached_content "$input"); then
        log_security_event "Using cached sanitized content" "DEBUG"
        echo "$cached_result"
        return 0
    fi

    # Sanitize content
    local sanitized
    sanitized=$(echo "$input" | tr -d '\000-\037\177' | head -c "$max_length")

    # Cache the result
    cache_sanitized_content "$input" "$sanitized"

    log_security_event "Text sanitized: ${#input} -> ${#sanitized} chars" "DEBUG"
    echo "$sanitized"
}

# Enhanced branch name sanitization
sanitize_branch_name() {
    local input="$1"

    # Check rate limit
    if ! check_rate_limit; then
        log_security_event "Branch name sanitization rate limit exceeded" "ERROR"
        return 1
    fi

    # Check cache first
    local cached_result
    if cached_result=$(get_cached_content "$input"); then
        echo "$cached_result"
        return 0
    fi

    # Generate safe git branch names
    local sanitized
    sanitized=$(echo "$input" | tr '[:upper:]' '[:lower:]' | \
        sed 's/[^a-z0-9._-]/-/g' | \
        sed 's/--*/-/g' | \
        sed 's/^-\|-$//g' | \
        head -c 50)

    # Ensure branch name is valid
    if [[ -z "$sanitized" || "$sanitized" =~ ^\.|\.$|@\{|\.\.|\// ]]; then
        sanitized="safe-branch-$(date +%s)"
        log_security_event "Generated fallback branch name: $sanitized" "WARNING"
    fi

    # Cache the result
    cache_sanitized_content "$input" "$sanitized"

    log_security_event "Branch name sanitized: '$input' -> '$sanitized'" "DEBUG"
    echo "$sanitized"
}

# Enhanced input validation with rate limiting
validate_input() {
    local input="$1"
    local max_length="$2"
    local allowed_pattern="$3"

    # Check rate limit
    if ! check_rate_limit; then
        log_security_event "Input validation rate limit exceeded" "ERROR"
        return 1
    fi

    # Length validation
    if [[ ${#input} -gt $max_length ]]; then
        log_security_event "Input length violation: ${#input} > $max_length" "WARNING"
        return 1
    fi

    # Pattern validation
    if [[ -n "$allowed_pattern" && ! "$input" =~ $allowed_pattern ]]; then
        log_security_event "Input pattern violation for input: ${input:0:50}..." "WARNING"
        return 1
    fi

    log_security_event "Input validation passed: ${#input} chars" "DEBUG"
    return 0
}

# Enhanced shell argument escaping
escape_shell_args() {
    local input="$1"

    # Check rate limit
    if ! check_rate_limit; then
        log_security_event "Shell escaping rate limit exceeded" "ERROR"
        return 1
    fi

    # Use printf %q for shell-safe quoting
    local escaped
    escaped=$(printf '%q' "$input")

    log_security_event "Shell arguments escaped: ${#input} -> ${#escaped} chars" "DEBUG"
    echo "$escaped"
}

# Validate and sanitize JSON input
sanitize_json() {
    local input="$1"
    local max_length="${2:-5000}"

    # Check rate limit
    if ! check_rate_limit; then
        log_security_event "JSON sanitization rate limit exceeded" "ERROR"
        return 1
    fi

    # Basic JSON validation and sanitization
    if ! echo "$input" | jq . >/dev/null 2>&1; then
        log_security_event "Invalid JSON input detected" "ERROR"
        return 1
    fi

    # Truncate if too long
    local sanitized
    sanitized=$(echo "$input" | head -c "$max_length")

    log_security_event "JSON sanitized: ${#input} -> ${#sanitized} chars" "DEBUG"
    echo "$sanitized"
}

# Get security utility version
get_security_version() {
    echo "$SECURITY_VERSION"
}

# Security health check
security_health_check() {
    local errors=0

    # Check if rate limiting is working
    if [[ ! -f "$VALIDATION_COUNT_FILE" ]]; then
        log_security_event "Rate limiting not initialized" "ERROR"
        ((errors++))
    fi

    # Check if caching directory exists
    if [[ ! -d "$CACHE_DIR" ]]; then
        log_security_event "Cache directory not initialized" "ERROR"
        ((errors++))
    fi

    # Check if logging is working
    if ! echo "test" > "$SECURITY_LOG_FILE" 2>/dev/null; then
        log_security_event "Security logging not available" "ERROR"
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        log_security_event "Security health check passed" "INFO"
        return 0
    else
        log_security_event "Security health check failed with $errors errors" "ERROR"
        return 1
    fi
}

# Cleanup function for temporary files
cleanup_security_utils() {
    rm -f "$VALIDATION_COUNT_FILE"
    rm -rf "$CACHE_DIR"
    log_security_event "Security utilities cleaned up" "INFO"
}

# Set up cleanup trap
trap cleanup_security_utils EXIT

# Initialize on source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being executed directly
    init_security_utils
    security_health_check
else
    # Script is being sourced
    init_security_utils
fi
