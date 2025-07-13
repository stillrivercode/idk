#!/bin/bash

# Circuit Breaker Integration Library for AI Workflows
# Integrates circuit breaker pattern with retry mechanisms and error handling
#
# Features:
# - Circuit breaker state management with GitHub variables
# - Integration with retry mechanisms
# - Failure tracking and recovery testing
# - Half-open state management
# - Comprehensive logging and monitoring

set -euo pipefail

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/retry-utils.sh"

# Circuit breaker states
readonly CB_STATE_CLOSED="CLOSED"
readonly CB_STATE_OPEN="OPEN"
readonly CB_STATE_HALF_OPEN="HALF-OPEN"

# Default configuration
DEFAULT_CB_THRESHOLD=3
DEFAULT_CB_TIMEOUT=30  # minutes
DEFAULT_CB_HALF_OPEN_MAX_CALLS=3

# Check if circuit breaker allows execution
cb_can_execute() {
    local operation_type="${1:-default}"

    # Get current circuit breaker state
    local cb_state=$(cb_get_state "$operation_type")
    local current_time=$(date +%s)

    case "$cb_state" in
        "$CB_STATE_CLOSED")
            echo "true"
            return 0
            ;;
        "$CB_STATE_OPEN")
            # Check if timeout period has elapsed
            local last_failure=$(cb_get_last_failure_time "$operation_type")
            local timeout_minutes=$(cb_get_timeout "$operation_type")
            local timeout_seconds=$((timeout_minutes * 60))

            if [[ $((current_time - last_failure)) -gt $timeout_seconds ]]; then
                # Move to half-open state
                cb_set_state "$operation_type" "$CB_STATE_HALF_OPEN"
                cb_set_half_open_calls "$operation_type" 0
                echo "true"
                return 0
            else
                echo "false"
                return 1
            fi
            ;;
        "$CB_STATE_HALF_OPEN")
            # Check if we've exceeded max calls in half-open state
            local half_open_calls=$(cb_get_half_open_calls "$operation_type")
            local max_calls=$(cb_get_half_open_max_calls "$operation_type")

            if [[ $half_open_calls -lt $max_calls ]]; then
                echo "true"
                return 0
            else
                echo "false"
                return 1
            fi
            ;;
        *)
            # Unknown state, default to allowing execution
            echo "true"
            return 0
            ;;
    esac
}

# Record successful execution
cb_record_success() {
    local operation_type="${1:-default}"

    local cb_state=$(cb_get_state "$operation_type")

    case "$cb_state" in
        "$CB_STATE_CLOSED")
            # Reset failure count
            cb_set_failure_count "$operation_type" 0
            ;;
        "$CB_STATE_HALF_OPEN")
            # Increment successful calls counter
            local half_open_calls=$(cb_get_half_open_calls "$operation_type")
            cb_set_half_open_calls "$operation_type" $((half_open_calls + 1))

            # Check if we should close the circuit
            local max_calls=$(cb_get_half_open_max_calls "$operation_type")
            if [[ $((half_open_calls + 1)) -ge $max_calls ]]; then
                cb_set_state "$operation_type" "$CB_STATE_CLOSED"
                cb_set_failure_count "$operation_type" 0
                echo "🔄 Circuit breaker closed after successful recovery test"
            fi
            ;;
    esac

    echo "✅ Circuit breaker recorded success for $operation_type"
}

# Record failed execution
cb_record_failure() {
    local operation_type="${1:-default}"
    local error_type="${2:-unknown}"

    local cb_state=$(cb_get_state "$operation_type")
    local current_time=$(date +%s)

    # Increment failure count
    local failure_count=$(cb_get_failure_count "$operation_type")
    cb_set_failure_count "$operation_type" $((failure_count + 1))
    cb_set_last_failure_time "$operation_type" "$current_time"

    # Check if we should open the circuit
    local threshold=$(cb_get_threshold "$operation_type")

    case "$cb_state" in
        "$CB_STATE_CLOSED")
            if [[ $((failure_count + 1)) -ge $threshold ]]; then
                cb_set_state "$operation_type" "$CB_STATE_OPEN"
                echo "🚨 Circuit breaker opened for $operation_type after $((failure_count + 1)) failures"
                cb_log_circuit_trip "$operation_type" "$error_type" $((failure_count + 1))
            else
                echo "⚠️  Circuit breaker recorded failure $((failure_count + 1))/$threshold for $operation_type"
            fi
            ;;
        "$CB_STATE_HALF_OPEN")
            # Any failure in half-open state immediately opens the circuit
            cb_set_state "$operation_type" "$CB_STATE_OPEN"
            echo "🚨 Circuit breaker re-opened for $operation_type during recovery test"
            cb_log_circuit_trip "$operation_type" "$error_type" $((failure_count + 1))
            ;;
        "$CB_STATE_OPEN")
            echo "⚠️  Additional failure recorded for $operation_type (circuit already open)"
            ;;
    esac
}

# Execute operation with circuit breaker protection
cb_execute_with_protection() {
    local operation_name="$1"
    local operation_command="$2"
    local operation_type="${3:-default}"

    echo "🔒 Executing '$operation_name' with circuit breaker protection"

    # Check if circuit breaker allows execution
    if [[ "$(cb_can_execute "$operation_type")" != "true" ]]; then
        echo "🚫 Circuit breaker is OPEN for $operation_type - execution blocked"
        echo "   Operation: $operation_name"
        echo "   Status: $(cb_get_status_summary "$operation_type")"
        return 1
    fi

    local cb_state=$(cb_get_state "$operation_type")
    if [[ "$cb_state" == "$CB_STATE_HALF_OPEN" ]]; then
        echo "🔍 Circuit breaker is in HALF-OPEN state - testing recovery"
    fi

    # Execute the operation
    local start_time=$(date +%s)
    local exit_code=0
    local error_output=""
    local temp_error_file=$(mktemp)

    if eval "$operation_command" 2>"$temp_error_file"; then
        exit_code=0
        error_output=""
    else
        exit_code=$?
        error_output=$(cat "$temp_error_file" 2>/dev/null || echo "")
    fi

    rm -f "$temp_error_file"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Record result with circuit breaker
    if [[ $exit_code -eq 0 ]]; then
        cb_record_success "$operation_type"
        echo "✅ Operation '$operation_name' completed successfully (${duration}s)"
    else
        local error_type=$(classify_error "$exit_code" "$error_output")
        cb_record_failure "$operation_type" "$error_type"
        echo "❌ Operation '$operation_name' failed with exit code $exit_code (${duration}s)"
    fi

    return $exit_code
}

# Get circuit breaker state
cb_get_state() {
    local operation_type="${1:-default}"
    local var_name="AI_CIRCUIT_STATE"

    if [[ "$operation_type" != "default" ]]; then
        var_name="AI_CIRCUIT_STATE_${operation_type^^}"
    fi

    cb_get_variable "$var_name" "$CB_STATE_CLOSED"
}

# Set circuit breaker state
cb_set_state() {
    local operation_type="${1:-default}"
    local new_state="$2"
    local var_name="AI_CIRCUIT_STATE"

    if [[ "$operation_type" != "default" ]]; then
        var_name="AI_CIRCUIT_STATE_${operation_type^^}"
    fi

    cb_set_variable "$var_name" "$new_state"
}

# Get failure count
cb_get_failure_count() {
    local operation_type="${1:-default}"
    local var_name="AI_CIRCUIT_FAILURES"

    if [[ "$operation_type" != "default" ]]; then
        var_name="AI_CIRCUIT_FAILURES_${operation_type^^}"
    fi

    cb_get_variable "$var_name" "0"
}

# Set failure count
cb_set_failure_count() {
    local operation_type="${1:-default}"
    local count="$2"
    local var_name="AI_CIRCUIT_FAILURES"

    if [[ "$operation_type" != "default" ]]; then
        var_name="AI_CIRCUIT_FAILURES_${operation_type^^}"
    fi

    cb_set_variable "$var_name" "$count"
}

# Get last failure time
cb_get_last_failure_time() {
    local operation_type="${1:-default}"
    local var_name="AI_CIRCUIT_LAST_FAILURE"

    if [[ "$operation_type" != "default" ]]; then
        var_name="AI_CIRCUIT_LAST_FAILURE_${operation_type^^}"
    fi

    cb_get_variable "$var_name" "0"
}

# Set last failure time
cb_set_last_failure_time() {
    local operation_type="${1:-default}"
    local timestamp="$2"
    local var_name="AI_CIRCUIT_LAST_FAILURE"

    if [[ "$operation_type" != "default" ]]; then
        var_name="AI_CIRCUIT_LAST_FAILURE_${operation_type^^}"
    fi

    cb_set_variable "$var_name" "$timestamp"
}

# Get failure threshold
cb_get_threshold() {
    local operation_type="${1:-default}"
    local var_name="AI_CIRCUIT_THRESHOLD"

    if [[ "$operation_type" != "default" ]]; then
        var_name="AI_CIRCUIT_THRESHOLD_${operation_type^^}"
    fi

    cb_get_variable "$var_name" "$DEFAULT_CB_THRESHOLD"
}

# Get timeout in minutes
cb_get_timeout() {
    local operation_type="${1:-default}"
    local var_name="AI_CIRCUIT_TIMEOUT"

    if [[ "$operation_type" != "default" ]]; then
        var_name="AI_CIRCUIT_TIMEOUT_${operation_type^^}"
    fi

    cb_get_variable "$var_name" "$DEFAULT_CB_TIMEOUT"
}

# Get half-open calls count
cb_get_half_open_calls() {
    local operation_type="${1:-default}"
    local var_name="AI_CIRCUIT_HALF_OPEN_CALLS"

    if [[ "$operation_type" != "default" ]]; then
        var_name="AI_CIRCUIT_HALF_OPEN_CALLS_${operation_type^^}"
    fi

    cb_get_variable "$var_name" "0"
}

# Set half-open calls count
cb_set_half_open_calls() {
    local operation_type="${1:-default}"
    local count="$2"
    local var_name="AI_CIRCUIT_HALF_OPEN_CALLS"

    if [[ "$operation_type" != "default" ]]; then
        var_name="AI_CIRCUIT_HALF_OPEN_CALLS_${operation_type^^}"
    fi

    cb_set_variable "$var_name" "$count"
}

# Get max calls in half-open state
cb_get_half_open_max_calls() {
    local operation_type="${1:-default}"
    local var_name="AI_CIRCUIT_HALF_OPEN_MAX"

    if [[ "$operation_type" != "default" ]]; then
        var_name="AI_CIRCUIT_HALF_OPEN_MAX_${operation_type^^}"
    fi

    cb_get_variable "$var_name" "$DEFAULT_CB_HALF_OPEN_MAX_CALLS"
}

# Get status summary
cb_get_status_summary() {
    local operation_type="${1:-default}"

    local state=$(cb_get_state "$operation_type")
    local failures=$(cb_get_failure_count "$operation_type")
    local threshold=$(cb_get_threshold "$operation_type")
    local last_failure=$(cb_get_last_failure_time "$operation_type")

    echo "State: $state, Failures: $failures/$threshold, Last: $(date -d "@$last_failure" 2>/dev/null || echo "never")"
}

# Log circuit breaker trip
cb_log_circuit_trip() {
    local operation_type="$1"
    local error_type="$2"
    local failure_count="$3"

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S UTC')
    local timeout=$(cb_get_timeout "$operation_type")

    cat << EOF

🚨 CIRCUIT BREAKER ACTIVATED 🚨
═══════════════════════════════════════

Operation Type: $operation_type
Timestamp: $timestamp
Failure Count: $failure_count
Error Type: $(get_error_type_name "$error_type")
Recovery Timeout: $timeout minutes

The circuit breaker has been activated to prevent cascading
failures. All subsequent requests for this operation type
will be blocked until the timeout period elapses.

Recommended Actions:
1. Investigate and resolve the underlying issue
2. Monitor system health and error logs
3. Wait for automatic recovery or manually reset
4. Test recovery with limited requests

EOF
}

# Wrapper functions for GitHub variables (can be overridden for testing)
cb_get_variable() {
    local var_name="$1"
    local default_value="$2"

    if command -v gh >/dev/null 2>&1; then
        # Try to get repo from git remote or use GITHUB_REPOSITORY
        local repo="${GITHUB_REPOSITORY:-}"
        if [[ -z "$repo" ]]; then
            repo=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[\/:]//; s/\.git$//' || echo "")
        fi

        if [[ -n "$repo" ]]; then
            gh variable get "$var_name" --repo "$repo" 2>/dev/null || echo "$default_value"
        else
            echo "$default_value"
        fi
    else
        echo "$default_value"
    fi
}

cb_set_variable() {
    local var_name="$1"
    local var_value="$2"

    if command -v gh >/dev/null 2>&1; then
        local repo="${GITHUB_REPOSITORY:-}"
        if [[ -z "$repo" ]]; then
            repo=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[\/:]//; s/\.git$//' || echo "")
        fi

        if [[ -n "$repo" ]]; then
            gh variable set "$var_name" --body "$var_value" --repo "$repo" 2>/dev/null || {
                echo "Warning: Failed to set GitHub variable $var_name" >&2
                return 1
            }
        else
            echo "Warning: Cannot determine repository for setting variable $var_name" >&2
            return 1
        fi
    else
        echo "Warning: GitHub CLI not available for setting variable $var_name" >&2
        return 1
    fi
}

# Test circuit breaker functionality
cb_test() {
    local operation_type="${1:-test}"

    echo "🧪 Testing circuit breaker functionality for operation type: $operation_type"

    # Test 1: Normal operation (should succeed)
    echo ""
    echo "Test 1: Normal operation"
    if cb_execute_with_protection "test-success" "true" "$operation_type"; then
        echo "✅ Test 1 passed: Normal operation succeeded"
    else
        echo "❌ Test 1 failed: Normal operation should have succeeded"
        return 1
    fi

    # Test 2: Repeated failures (should trip circuit)
    echo ""
    echo "Test 2: Repeated failures to trip circuit"
    local threshold=$(cb_get_threshold "$operation_type")

    for ((i=1; i<=threshold; i++)); do
        echo "   Failure $i/$threshold"
        cb_execute_with_protection "test-failure-$i" "false" "$operation_type" || true
    done

    local state=$(cb_get_state "$operation_type")
    if [[ "$state" == "$CB_STATE_OPEN" ]]; then
        echo "✅ Test 2 passed: Circuit breaker opened after $threshold failures"
    else
        echo "❌ Test 2 failed: Circuit breaker should be open, but state is: $state"
        return 1
    fi

    # Test 3: Blocked execution (should fail)
    echo ""
    echo "Test 3: Blocked execution when circuit is open"
    if ! cb_execute_with_protection "test-blocked" "true" "$operation_type"; then
        echo "✅ Test 3 passed: Execution blocked when circuit is open"
    else
        echo "❌ Test 3 failed: Execution should be blocked when circuit is open"
        return 1
    fi

    # Test 4: Manual reset and recovery
    echo ""
    echo "Test 4: Manual reset and recovery"
    cb_set_state "$operation_type" "$CB_STATE_CLOSED"
    cb_set_failure_count "$operation_type" 0

    if cb_execute_with_protection "test-recovery" "true" "$operation_type"; then
        echo "✅ Test 4 passed: Circuit breaker reset and recovery successful"
    else
        echo "❌ Test 4 failed: Recovery should have succeeded"
        return 1
    fi

    echo ""
    echo "🎉 All circuit breaker tests passed!"
    return 0
}

# Export functions for use in other scripts
export -f cb_can_execute
export -f cb_record_success
export -f cb_record_failure
export -f cb_execute_with_protection
export -f cb_get_status_summary
export -f cb_test
