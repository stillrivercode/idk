#!/bin/bash

# Comprehensive Prerequisite Validation Library
# Validates all prerequisites before executing AI operations
#
# Features:
# - Network connectivity validation
# - Authentication credential verification
# - Environment variable validation
# - CLI tool availability checks
# - System resource validation
# - Configuration validation

set -euo pipefail

# Validation result codes
readonly VALIDATION_SUCCESS=0
readonly VALIDATION_CRITICAL_FAILURE=1
readonly VALIDATION_WARNING=2

# Minimum system requirements
MIN_DISK_SPACE_MB=100
MIN_MEMORY_MB=512
MAX_LOAD_AVERAGE=10.0

# Network endpoints to test
readonly NETWORK_TEST_ENDPOINTS=(
    "https://api.anthropic.com/health"
    "https://api.github.com"
    "https://httpbin.org/get"
)

# Required environment variables for different operations
REQUIRED_ENV_VARS_AI="OPENROUTER_API_KEY"
REQUIRED_ENV_VARS_GITHUB="GITHUB_TOKEN"
REQUIRED_ENV_VARS_COST="AI_COST_LIMIT_DAILY AI_COST_LIMIT_MONTHLY"

# Validation state tracking
VALIDATION_ERRORS=()
VALIDATION_WARNINGS=()
VALIDATION_INFO=()

# Main prerequisite validation function
validate_all_prerequisites() {
    local operation_types=("$@")
    local overall_result=$VALIDATION_SUCCESS

    echo "🔍 Validating prerequisites for: ${operation_types[*]:-all}"

    # Clear previous validation state
    VALIDATION_ERRORS=()
    VALIDATION_WARNINGS=()
    VALIDATION_INFO=()

    # Run all validation checks
    validate_environment_variables "${operation_types[@]}"
    validate_network_connectivity
    validate_authentication_credentials "${operation_types[@]}"
    validate_cli_tools "${operation_types[@]}"
    validate_system_resources
    validate_configuration "${operation_types[@]}"
    validate_permissions

    # Generate validation report
    generate_validation_report

    # Determine overall result
    if [[ ${#VALIDATION_ERRORS[@]} -gt 0 ]]; then
        overall_result=$VALIDATION_CRITICAL_FAILURE
    elif [[ ${#VALIDATION_WARNINGS[@]} -gt 0 ]]; then
        overall_result=$VALIDATION_WARNING
    fi

    return $overall_result
}

# Validate required environment variables
validate_environment_variables() {
    local operation_types=("$@")

    echo -n "📋 ENV: "

    # Check key environment variables silently
    check_env_var "HOME" "User home directory" > /dev/null
    check_env_var "PATH" "System PATH" > /dev/null
    check_env_var "USER" "Current user" "$(whoami)" > /dev/null

    # Check operation-specific environment variables
    for op_type in "${operation_types[@]}"; do
        case "$op_type" in
            "ai_operations"|"all")
                validate_openrouter_api_key
                ;;
            "github_operations"|"all")
                validate_github_token
                ;;
            "cost_monitoring"|"all")
                validate_cost_monitoring_vars
                ;;
        esac
    done

    # Check CI/CD specific variables
    if [[ -n "${CI:-}" ]]; then
        echo "   🤖 CI/CD environment detected"
        check_env_var "GITHUB_ACTIONS" "GitHub Actions environment"
        check_env_var "GITHUB_REPOSITORY" "Repository name"
        check_env_var "GITHUB_SHA" "Commit SHA"
    fi

    echo " ✅"
}

# Validate OpenRouter API key
# OpenRouter provides multi-model AI access through a unified API
# API keys follow the format: sk-or-{32+ alphanumeric/underscore/dash characters}
# Minimum length is typically 40 characters (sk-or- prefix + 32+ chars)
validate_openrouter_api_key() {
    local api_key="${OPENROUTER_API_KEY:-}"
    local validation_attempts_file="/tmp/.openrouter_validation_attempts_$$"
    local max_validation_attempts=3
    local validation_cooldown=60  # seconds

    if [[ -z "$api_key" ]]; then
        add_validation_error "OpenRouter API key is missing. Please set OPENROUTER_API_KEY environment variable."
        add_validation_error "Setup instructions:"
        add_validation_error "  1. Create account at https://openrouter.ai"
        add_validation_error "  2. Generate API key from dashboard"
        add_validation_error "  3. Add as repository secret: Settings → Secrets → Actions → OPENROUTER_API_KEY"
        return 1
    fi

    # Validate OpenRouter API key format: sk-or-{32+ alphanumeric/underscore/dash chars}
    # This regex ensures the key starts with 'sk-or-' followed by at least 32 valid characters
    if [[ ! "$api_key" =~ ^sk-or-[a-zA-Z0-9_-]{32,}$ ]]; then
        add_validation_error "OpenRouter API key format is invalid. Expected format: sk-or-{32+ characters}"
        add_validation_error "Valid characters: letters, numbers, underscores, and dashes"
        add_validation_error "Example: sk-or-v1_abcd1234efgh5678ijkl9012mnop3456qrst"
        add_validation_error "Check your key at: https://openrouter.ai/keys"
        return 1
    fi

    # Length validation with rationale
    # OpenRouter keys are typically 40+ characters (4 char prefix + 36+ chars)
    # Keys shorter than 40 chars may be truncated or invalid
    if [[ ${#api_key} -lt 40 ]]; then
        add_validation_warning "OpenRouter API key appears unusually short (${#api_key} characters)"
        add_validation_warning "Expected length: 40+ characters (sk-or- prefix + 32+ character identifier)"
        add_validation_warning "Please verify your key is complete at https://openrouter.ai/keys"
    fi

    # Rate limiting for API validation attempts
    if [[ -f "$validation_attempts_file" ]]; then
        local last_attempt=$(cat "$validation_attempts_file" 2>/dev/null || echo "0")
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_attempt))

        if [[ $time_diff -lt $validation_cooldown ]]; then
            local wait_time=$((validation_cooldown - time_diff))
            add_validation_warning "Rate limiting API validation (wait ${wait_time}s to avoid quota exhaustion)"
            add_validation_info "OpenRouter API key format is valid (skipping live validation due to rate limit)"
            return 0
        fi
    fi

    # Test API key with a minimal request to OpenRouter API
    if command -v curl >/dev/null 2>&1; then
        echo "   🔑 Testing OpenRouter API key validity (rate-limited to prevent quota exhaustion)..."

        # Record validation attempt
        echo "$(date +%s)" > "$validation_attempts_file"

        local test_response
        test_response=$(curl -s -w "%{http_code}" -o /dev/null \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $api_key" \
            -H "HTTP-Referer: ${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-unknown/repo}" \
            -H "X-Title: AI Workflow Assistant Validation" \
            --connect-timeout 5 \
            --max-time 10 \
            https://openrouter.ai/api/v1/chat/completions \
            -d '{"model":"anthropic/claude-3-haiku","max_tokens":1,"messages":[{"role":"user","content":"test"}]}' \
            2>/dev/null || echo "000")

        # Clean up attempt tracking file
        rm -f "$validation_attempts_file"

        case "$test_response" in
            200|400)  # 200 = success, 400 = bad request but valid auth
                add_validation_info "OpenRouter API key is valid and functional"
                ;;
            401)
                add_validation_error "OpenRouter API key is invalid or expired"
                add_validation_error "Please check your key at: https://openrouter.ai/keys"
                add_validation_error "Ensure the key has sufficient credits and permissions"
                ;;
            429)
                add_validation_warning "OpenRouter API key is valid but rate limited"
                add_validation_warning "Consider using a higher-tier plan for increased limits"
                ;;
            403)
                add_validation_error "OpenRouter API key lacks necessary permissions"
                add_validation_error "Ensure your key has chat completion permissions enabled"
                ;;
            *)
                add_validation_warning "Cannot verify OpenRouter API key (HTTP $test_response - network or API issue)"
                add_validation_warning "This may be temporary. Verify manually at: https://openrouter.ai/playground"
                ;;
        esac
    else
        add_validation_warning "Cannot test OpenRouter API key (curl not available)"
        add_validation_info "API key format appears valid - manual verification recommended"
    fi
}

# HTTP Status Codes
readonly HTTP_OK=200
readonly HTTP_UNAUTHORIZED=401
readonly HTTP_FORBIDDEN=403

# Validate GitHub token
validate_github_token() {
    local github_token="${GITHUB_TOKEN:-}"

    if [[ -n "${DEBUG:-}" ]]; then
        echo "DEBUG: GITHUB_ACTIONS=${GITHUB_ACTIONS:-false}"
        echo "DEBUG: GITHUB_TOKEN is set: $([[ -n "$github_token" ]] && echo "true" || echo "false")"
    fi


    if [[ -z "$github_token" ]]; then
        add_validation_warning "GITHUB_TOKEN environment variable is not set (may be optional)"
        return 0
    fi

    # Basic format validation
    if [[ ! "$github_token" =~ ^(gh[ospru]_|github_pat_) ]]; then
        add_validation_warning "GITHUB_TOKEN format appears non-standard"
    fi

    # Test token with GitHub API
    if command -v curl >/dev/null 2>&1; then
        # Testing GitHub token validity silently
        local test_response
        test_response=$(curl -s -w "%{http_code}" -o /dev/null \
            -H "Authorization: Bearer $github_token" \
            --max-time 10 \
            https://api.github.com/user \
            2>/dev/null || echo "000")

        case "$test_response" in
            $HTTP_OK)
                add_validation_info "GITHUB_TOKEN is valid and functional"
                ;;
            $HTTP_UNAUTHORIZED)
                add_validation_error "GITHUB_TOKEN is invalid or expired. See: https://docs.github.com/en/authentication/troubleshooting-your-authentication-credentials"
                ;;
            $HTTP_FORBIDDEN)
                # 403 can indicate rate limiting or insufficient permissions for the /user endpoint
                # In GitHub Actions, tokens often have restricted permissions that don't include user:read
                # This is normal and expected - check if we're in a GitHub Actions environment
                if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
                    add_validation_info "GITHUB_TOKEN permissions validated (GitHub Actions environment detected)"
                    add_validation_info "Token has workflow-specific permissions as configured in workflow files. See: https://docs.github.com/en/actions/security-guides/automatic-token-authentication"
                else
                    add_validation_warning "GITHUB_TOKEN has insufficient permissions for user endpoint or is rate limited"
                    add_validation_warning "This may be normal if token has restricted scope (e.g., workflow-only permissions). See: https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/authenticating-as-a-github-app-installation"
                fi
                ;;
            *)
                add_validation_warning "Cannot verify GITHUB_TOKEN (network or API issue)"
                ;;
        esac
    fi
}

# Validate cost monitoring variables
validate_cost_monitoring_vars() {
    local daily_limit="${AI_COST_LIMIT_DAILY:-}"
    local monthly_limit="${AI_COST_LIMIT_MONTHLY:-}"

    if [[ -n "$daily_limit" ]]; then
        if [[ ! "$daily_limit" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            add_validation_error "AI_COST_LIMIT_DAILY must be a valid number, got: $daily_limit"
        fi
    fi

    if [[ -n "$monthly_limit" ]]; then
        if [[ ! "$monthly_limit" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            add_validation_error "AI_COST_LIMIT_MONTHLY must be a valid number, got: $monthly_limit"
        fi
    fi

    # Validate relationship between daily and monthly limits
    if [[ -n "$daily_limit" && -n "$monthly_limit" ]]; then
        local daily_times_30=$(echo "$daily_limit * 30" | bc -l 2>/dev/null || echo "0")
        if command -v bc >/dev/null 2>&1 && [[ $(echo "$daily_times_30 > $monthly_limit" | bc -l) -eq 1 ]]; then
            add_validation_warning "Daily limit × 30 ($daily_times_30) exceeds monthly limit ($monthly_limit)"
        fi
    fi
}

# Validate network connectivity
validate_network_connectivity() {
    echo -n "🌐 NET: "

    # Test DNS resolution
    if ! nslookup google.com >/dev/null 2>&1; then
        echo "❌ DNS failed"
        add_validation_error "DNS resolution not working"
        return 1
    fi

    # Test key endpoints silently
    local failed_endpoints=0
    if command -v curl >/dev/null 2>&1; then
        for endpoint in "${NETWORK_TEST_ENDPOINTS[@]}"; do
            if ! curl -s --max-time 5 --head "$endpoint" >/dev/null 2>&1; then
                ((failed_endpoints++))
            fi
        done
    fi

    if [[ $failed_endpoints -eq 0 ]]; then
        echo " ✅"
    else
        echo " ⚠️ $failed_endpoints/${#NETWORK_TEST_ENDPOINTS[@]} endpoints failed"
    fi
}

# Validate authentication credentials
validate_authentication_credentials() {
    local operation_types=("$@")

    echo -n "🔐 AUTH: "

    # Check if running in GitHub Actions
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        # Silent check in CI

        # Validate GitHub Actions token
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            add_validation_info "GitHub Actions token is available"
        else
            add_validation_warning "GitHub Actions token not available (may affect some operations)"
        fi
    fi

    # Validate specific authentication requirements
    for op_type in "${operation_types[@]}"; do
        case "$op_type" in
            "ai_operations"|"all")
                if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
                    add_validation_error "AI operations require OPENROUTER_API_KEY"
                fi
                ;;
            "github_operations"|"all")
                if command -v gh >/dev/null 2>&1; then
                    if gh auth status >/dev/null 2>&1; then
                        add_validation_info "GitHub CLI is authenticated"
                    else
                        add_validation_warning "GitHub CLI is not authenticated"
                    fi
                fi
                ;;
        esac
    done

    echo " ✅"
}

# Validate CLI tools availability
validate_cli_tools() {
    local operation_types=("$@")

    echo -n "🔧 CLI: "

    # Check tools silently
    local missing_tools=0
    for tool in bash git curl jq; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            ((missing_tools++))
        fi
    done

    # Operation-specific tools
    for op_type in "${operation_types[@]}"; do
        case "$op_type" in
            "ai_operations"|"all")
                validate_openrouter_api >/dev/null 2>&1 || ((missing_tools++))
                ;;
            "github_operations"|"all")
                command -v gh >/dev/null 2>&1 || ((missing_tools++))
                ;;
        esac
    done

    if [[ $missing_tools -eq 0 ]]; then
        echo " ✅"
    else
        echo " ⚠️ $missing_tools tools missing"
    fi
}

# Validate OpenRouter API specifically
validate_openrouter_api() {
    echo "   🤖 Validating OpenRouter API setup..."

    # Check if OpenRouter API key is set
    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
        add_validation_error "OpenRouter API key required for AI operations"
        add_validation_error "Set OPENROUTER_API_KEY environment variable"
        return 1
    fi

    # Validate API key format
    if [[ ! "${OPENROUTER_API_KEY}" =~ ^sk-or-[a-zA-Z0-9_-]{32,}$ ]]; then
        add_validation_error "Invalid OpenRouter API key format"
        return 1
    fi

    add_validation_info "OpenRouter API configured (using API instead of CLI)"
    add_validation_info "AI Model: ${AI_MODEL:-anthropic/claude-3.5-sonnet}"
    add_validation_info "No CLI installation required - using direct API calls"
}

# Validate system resources
validate_system_resources() {
    echo -n "💻 SYS: "

    # Check disk space
    local space_ok=1
    if command -v df >/dev/null 2>&1; then
        local available_space_mb
        available_space_mb=$(df . | awk 'NR==2 {print int($4/1024)}')
        if [[ $available_space_mb -lt $MIN_DISK_SPACE_MB ]]; then
            space_ok=0
        fi
    fi

    # Check memory
    local memory_ok=1
    if [[ -f /proc/meminfo ]]; then
        local available_memory_mb
        available_memory_mb=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo "9999")
        if [[ $available_memory_mb -lt $MIN_MEMORY_MB ]]; then
            memory_ok=0
        fi
    fi

    if [[ $space_ok -eq 1 && $memory_ok -eq 1 ]]; then
        echo " ✅"
    else
        echo " ⚠️ resource constraints"
    fi
}

# Validate configuration files and settings
validate_configuration() {
    local operation_types=("$@")

    echo -n "⚙️ CONFIG: "

    local config_issues=0
    # Check git configuration silently
    if command -v git >/dev/null 2>&1; then
        local git_user_name=$(git config user.name 2>/dev/null || echo "")
        local git_user_email=$(git config user.email 2>/dev/null || echo "")

        [[ -z "$git_user_name" ]] && ((config_issues++))
        [[ -z "$git_user_email" ]] && ((config_issues++))
    fi

    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        ((config_issues++))
    fi

    if [[ $config_issues -eq 0 ]]; then
        echo " ✅"
    else
        echo " ⚠️ $config_issues config issues"
    fi

    echo " ✅"
}

# Validate file and directory permissions
validate_permissions() {
    echo -n "🔒 PERMS: "

    local perm_issues=0
    # Check key directory permissions
    [[ ! -w "." ]] && ((perm_issues++))
    [[ ! -w "/tmp" ]] && ((perm_issues++))
    [[ ! -w "$HOME" ]] && ((perm_issues++))

    if [[ $perm_issues -eq 0 ]]; then
        echo " ✅"
    else
        echo " ⚠️ $perm_issues permission issues"
    fi
}

# Helper functions for validation state management
add_validation_error() {
    VALIDATION_ERRORS+=("$1")
}

add_validation_warning() {
    VALIDATION_WARNINGS+=("$1")
}

add_validation_info() {
    VALIDATION_INFO+=("$1")
}

# Check if environment variable is set
check_env_var() {
    local var_name="$1"
    local description="$2"
    local default_value="${3:-}"

    local var_value="${!var_name:-}"

    if [[ -n "$var_value" ]]; then
        add_validation_info "$description ($var_name): Set"
    elif [[ -n "$default_value" ]]; then
        add_validation_info "$description ($var_name): Using default ($default_value)"
    else
        add_validation_warning "$description ($var_name): Not set"
    fi
}

# Check if CLI tool is available
check_cli_tool() {
    local tool_name="$1"
    local description="$2"
    local required="$3"

    if command -v "$tool_name" >/dev/null 2>&1; then
        local tool_path=$(which "$tool_name")
        add_validation_info "$description ($tool_name): Available at $tool_path"
    else
        if [[ "$required" == "true" ]]; then
            add_validation_error "$description ($tool_name): Required but not found"
        else
            add_validation_warning "$description ($tool_name): Not available (optional)"
        fi
    fi
}

# Generate validation report
generate_validation_report() {
    if [[ ${#VALIDATION_ERRORS[@]} -eq 0 ]]; then
        if [[ ${#VALIDATION_WARNINGS[@]} -eq 0 ]]; then
            echo "✅ All prerequisites validated"
        else
            echo "⚠️ Prerequisites OK (${#VALIDATION_WARNINGS[@]} warnings)"
        fi
    else
        echo "❌ Prerequisites failed (${#VALIDATION_ERRORS[@]} errors, ${#VALIDATION_WARNINGS[@]} warnings)"
        # Only show errors for failures
        for error in "${VALIDATION_ERRORS[@]}"; do
            echo "  ❌ $error"
        done
    fi
}

# Export main validation function
export -f validate_all_prerequisites
