#!/bin/bash

# Circuit Breaker Manager for AI Workflows
# This script provides comprehensive circuit breaker management functionality

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help function
show_help() {
    cat << EOF
Circuit Breaker Manager for AI Workflows

USAGE:
    $0 <command> [options]

COMMANDS:
    status              Show current circuit breaker status
    reset               Reset circuit breaker to CLOSED state
    open                Manually open circuit breaker
    close               Manually close circuit breaker
    test                Test circuit breaker functionality
    monitor             Monitor circuit breaker in real-time
    stats               Show circuit breaker statistics
    config              Show/update circuit breaker configuration

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -r, --repo REPO     Specify repository (default: current)

EXAMPLES:
    $0 status                           # Check current status
    $0 reset                           # Reset after fixing issues
    $0 open                            # Emergency stop
    $0 test --simulate-failure         # Test failure handling
    $0 monitor --interval 30           # Monitor every 30 seconds
    $0 config --threshold 5            # Set failure threshold to 5

CIRCUIT BREAKER STATES:
    CLOSED      Normal operation, requests pass through
    OPEN        Circuit tripped, requests fail immediately
    HALF-OPEN   Testing phase, limited requests allowed
EOF
}

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
        "INFO")  echo -e "${BLUE}[INFO]${NC}  $timestamp - $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC}  $timestamp - $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $timestamp - $message" >&2 ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $timestamp - $message" ;;
    esac
}

# Check if gh CLI is available and authenticated
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log "ERROR" "GitHub CLI (gh) is not installed. Please install it first."
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        log "ERROR" "GitHub CLI is not authenticated. Please run 'gh auth login' first."
        exit 1
    fi
}

# Get repository variables with error handling
get_variable() {
    local var_name="$1"
    local default_value="${2:-}"
    local repo="${3:-${GITHUB_REPOSITORY:-}}"

    if [[ -n "$repo" ]]; then
        gh variable get "$var_name" --repo "$repo" 2>/dev/null || echo "$default_value"
    else
        # Try to get repo from git remote
        local git_repo=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[\/:]//; s/\.git$//' || echo "")
        if [[ -n "$git_repo" ]]; then
            gh variable get "$var_name" --repo "$git_repo" 2>/dev/null || echo "$default_value"
        else
            echo "$default_value"
        fi
    fi
}

# Set repository variable with error handling
set_variable() {
    local var_name="$1"
    local var_value="$2"
    local repo="${3:-${GITHUB_REPOSITORY:-}}"

    if [[ -n "$repo" ]]; then
        gh variable set "$var_name" --body "$var_value" --repo "$repo"
    else
        local git_repo=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[\/:]//; s/\.git$//' || echo "")
        if [[ -n "$git_repo" ]]; then
            gh variable set "$var_name" --body "$var_value" --repo "$git_repo"
        else
            log "ERROR" "Cannot determine repository. Please set GITHUB_REPOSITORY environment variable."
            exit 1
        fi
    fi
}

# Get current circuit breaker status
get_status() {
    local state=$(get_variable "AI_CIRCUIT_STATE" "CLOSED")
    local failures=$(get_variable "AI_CIRCUIT_FAILURES" "0")
    local last_failure=$(get_variable "AI_CIRCUIT_LAST_FAILURE" "0")
    local threshold=$(get_variable "AI_CIRCUIT_THRESHOLD" "3")
    local timeout=$(get_variable "AI_CIRCUIT_TIMEOUT" "30")

    echo "STATE:$state"
    echo "FAILURES:$failures"
    echo "LAST_FAILURE:$last_failure"
    echo "THRESHOLD:$threshold"
    echo "TIMEOUT:$timeout"
}

# Show formatted status
show_status() {
    log "INFO" "Checking circuit breaker status..."

    local status_info=$(get_status)
    local state=$(echo "$status_info" | grep "STATE:" | cut -d':' -f2)
    local failures=$(echo "$status_info" | grep "FAILURES:" | cut -d':' -f2)
    local last_failure=$(echo "$status_info" | grep "LAST_FAILURE:" | cut -d':' -f2)
    local threshold=$(echo "$status_info" | grep "THRESHOLD:" | cut -d':' -f2)
    local timeout=$(echo "$status_info" | grep "TIMEOUT:" | cut -d':' -f2)

    echo
    echo "======================================"
    echo "       CIRCUIT BREAKER STATUS        "
    echo "======================================"

    # State with color coding
    case "$state" in
        "CLOSED")
            echo -e "State:           ${GREEN}$state${NC} (Normal operation)"
            ;;
        "OPEN")
            echo -e "State:           ${RED}$state${NC} (Circuit tripped)"
            ;;
        "HALF-OPEN")
            echo -e "State:           ${YELLOW}$state${NC} (Testing recovery)"
            ;;
        *)
            echo -e "State:           ${BLUE}$state${NC}"
            ;;
    esac

    echo "Failures:        $failures / $threshold"

    if [[ "$last_failure" != "0" ]]; then
        local last_failure_date=$(date -d "@$last_failure" 2>/dev/null || date -r "$last_failure" 2>/dev/null || echo "Unknown")
        echo "Last Failure:    $last_failure_date"

        if [[ "$state" == "OPEN" ]]; then
            local current_time=$(date +%s)
            local time_since_failure=$((current_time - last_failure))
            local timeout_seconds=$((timeout * 60))
            local remaining_time=$((timeout_seconds - time_since_failure))

            if [[ $remaining_time -gt 0 ]]; then
                local remaining_minutes=$((remaining_time / 60))
                echo "Recovery Time:   $remaining_minutes minutes remaining"
            else
                echo -e "Recovery:        ${YELLOW}Ready to test${NC}"
            fi
        fi
    else
        echo "Last Failure:    Never"
    fi

    echo "Threshold:       $threshold failures"
    echo "Timeout:         $timeout minutes"
    echo "======================================"
}

# Reset circuit breaker
reset_circuit() {
    log "INFO" "Resetting circuit breaker..."

    set_variable "AI_CIRCUIT_STATE" "CLOSED"
    set_variable "AI_CIRCUIT_FAILURES" "0"
    set_variable "AI_CIRCUIT_LAST_FAILURE" "0"

    log "SUCCESS" "Circuit breaker reset to CLOSED state"
}

# Manually open circuit breaker
open_circuit() {
    log "WARN" "Manually opening circuit breaker (emergency stop)..."

    set_variable "AI_CIRCUIT_STATE" "OPEN"
    set_variable "AI_CIRCUIT_LAST_FAILURE" "$(date +%s)"

    log "SUCCESS" "Circuit breaker opened - all AI workflows will be blocked"
}

# Manually close circuit breaker
close_circuit() {
    log "INFO" "Manually closing circuit breaker..."

    set_variable "AI_CIRCUIT_STATE" "CLOSED"
    set_variable "AI_CIRCUIT_FAILURES" "0"

    log "SUCCESS" "Circuit breaker closed - normal operation resumed"
}

# Test circuit breaker functionality
test_circuit() {
    local simulate_failure="${1:-false}"

    log "INFO" "Testing circuit breaker functionality..."

    # Save current state
    local original_status=$(get_status)
    local original_state=$(echo "$original_status" | grep "STATE:" | cut -d':' -f2)

    echo
    echo "=== CIRCUIT BREAKER TEST ==="
    echo "Original state: $original_state"
    echo

    if [[ "$simulate_failure" == "true" ]]; then
        log "INFO" "Simulating failures to test circuit opening..."

        # Get threshold
        local threshold=$(echo "$original_status" | grep "THRESHOLD:" | cut -d':' -f2)

        # Simulate failures
        for ((i=1; i<=threshold; i++)); do
            local current_failures=$(get_variable "AI_CIRCUIT_FAILURES" "0")
            local new_failures=$((current_failures + 1))

            set_variable "AI_CIRCUIT_FAILURES" "$new_failures"
            set_variable "AI_CIRCUIT_LAST_FAILURE" "$(date +%s)"

            if [[ $new_failures -ge $threshold ]]; then
                set_variable "AI_CIRCUIT_STATE" "OPEN"
                log "WARN" "Circuit opened after $new_failures failures"
                break
            else
                log "INFO" "Simulated failure $i/$threshold"
            fi

            sleep 1
        done

        # Show final state
        show_status

        # Wait a bit, then test recovery
        log "INFO" "Testing recovery process..."
        sleep 2

        set_variable "AI_CIRCUIT_STATE" "HALF-OPEN"
        log "INFO" "Moved to HALF-OPEN state"

        sleep 1

        # Simulate successful operation
        set_variable "AI_CIRCUIT_STATE" "CLOSED"
        set_variable "AI_CIRCUIT_FAILURES" "0"
        log "SUCCESS" "Successfully recovered to CLOSED state"

    else
        log "INFO" "Running basic circuit breaker status test..."
        show_status
    fi

    echo
    log "SUCCESS" "Circuit breaker test completed"

    # Restore original state if needed
    if [[ "$simulate_failure" == "true" ]]; then
        log "INFO" "Restoring original circuit breaker state..."

        local restore_state=$(echo "$original_status" | grep "STATE:" | cut -d':' -f2)
        local restore_failures=$(echo "$original_status" | grep "FAILURES:" | cut -d':' -f2)
        local restore_last_failure=$(echo "$original_status" | grep "LAST_FAILURE:" | cut -d':' -f2)

        set_variable "AI_CIRCUIT_STATE" "$restore_state"
        set_variable "AI_CIRCUIT_FAILURES" "$restore_failures"
        set_variable "AI_CIRCUIT_LAST_FAILURE" "$restore_last_failure"

        log "SUCCESS" "Original state restored"
    fi
}

# Monitor circuit breaker in real-time
monitor_circuit() {
    local interval="${1:-60}"

    log "INFO" "Starting circuit breaker monitor (interval: ${interval}s)"
    log "INFO" "Press Ctrl+C to stop monitoring"
    echo

    while true; do
        clear
        echo "Circuit Breaker Monitor - $(date)"
        echo "Refreshing every ${interval} seconds"
        echo
        show_status

        # Show recent workflow runs
        echo
        echo "Recent AI Workflow Runs:"
        echo "========================"

        # This would show recent workflow runs in a real implementation
        # For now, we'll show a placeholder
        echo "Use 'gh run list --workflow=ai-*.yml --limit=5' to see recent runs"

        sleep "$interval"
    done
}

# Show circuit breaker statistics
show_stats() {
    log "INFO" "Generating circuit breaker statistics..."

    # Get current values
    local status_info=$(get_status)
    local state=$(echo "$status_info" | grep "STATE:" | cut -d':' -f2)
    local failures=$(echo "$status_info" | grep "FAILURES:" | cut -d':' -f2)
    local last_failure=$(echo "$status_info" | grep "LAST_FAILURE:" | cut -d':' -f2)
    local threshold=$(echo "$status_info" | grep "THRESHOLD:" | cut -d':' -f2)

    # Calculate uptime
    local uptime_status="Normal"
    if [[ "$state" == "OPEN" ]]; then
        uptime_status="Circuit Open"
    elif [[ "$state" == "HALF-OPEN" ]]; then
        uptime_status="Testing Recovery"
    fi

    echo
    echo "======================================"
    echo "    CIRCUIT BREAKER STATISTICS       "
    echo "======================================"
    echo "Current Status:     $uptime_status"
    echo "Failure Rate:       $failures/$threshold ($(( failures * 100 / threshold ))%)"

    if [[ "$last_failure" != "0" ]]; then
        local hours_since_failure=$(( ($(date +%s) - last_failure) / 3600 ))
        echo "Hours Since Failure: $hours_since_failure"
    else
        echo "Hours Since Failure: N/A (no failures)"
    fi

    # Get cost information
    local daily_cost=$(get_variable "AI_DAILY_COST" "0")
    local monthly_cost=$(get_variable "AI_MONTHLY_COST" "0")

    echo "Daily Cost:         \$$daily_cost"
    echo "Monthly Cost:       \$$monthly_cost"
    echo "======================================"

    # Recent trends (placeholder for future implementation)
    echo
    echo "Circuit Breaker Trends (Last 7 days):"
    echo "=====================================  "
    echo "This feature will track:"
    echo "- State change frequency"
    echo "- Average failure recovery time"
    echo "- Cost correlation with failures"
    echo "- Workflow success rates"
}

# Show/update configuration
manage_config() {
    local action="${1:-show}"
    local key="${2:-}"
    local value="${3:-}"

    case "$action" in
        "show")
            log "INFO" "Current circuit breaker configuration:"
            echo
            echo "================================"
            echo "   CIRCUIT BREAKER CONFIG      "
            echo "================================"
            echo "Threshold:       $(get_variable "AI_CIRCUIT_THRESHOLD" "3") failures"
            echo "Timeout:         $(get_variable "AI_CIRCUIT_TIMEOUT" "30") minutes"
            echo "Check Interval:  $(get_variable "AI_CIRCUIT_CHECK_INTERVAL" "5") minutes"
            echo "Emergency Stop:  $(get_variable "EMERGENCY_STOP_ENABLED" "false")"
            echo "Maintenance:     $(get_variable "MAINTENANCE_MODE" "false")"
            echo "Max Daily Cost:  \$$(get_variable "MAX_DAILY_COST" "50")"
            echo "Max Monthly Cost: \$$(get_variable "MAX_MONTHLY_COST" "500")"
            echo "================================"
            ;;

        "set")
            if [[ -z "$key" || -z "$value" ]]; then
                log "ERROR" "Usage: $0 config set <key> <value>"
                exit 1
            fi

            case "$key" in
                "threshold")
                    set_variable "AI_CIRCUIT_THRESHOLD" "$value"
                    log "SUCCESS" "Circuit breaker threshold set to $value"
                    ;;
                "timeout")
                    set_variable "AI_CIRCUIT_TIMEOUT" "$value"
                    log "SUCCESS" "Circuit breaker timeout set to $value minutes"
                    ;;
                "daily-cost")
                    set_variable "MAX_DAILY_COST" "$value"
                    log "SUCCESS" "Maximum daily cost set to \$$value"
                    ;;
                "monthly-cost")
                    set_variable "MAX_MONTHLY_COST" "$value"
                    log "SUCCESS" "Maximum monthly cost set to \$$value"
                    ;;
                *)
                    log "ERROR" "Unknown configuration key: $key"
                    log "INFO" "Valid keys: threshold, timeout, daily-cost, monthly-cost"
                    exit 1
                    ;;
            esac
            ;;

        *)
            log "ERROR" "Usage: $0 config [show|set] [key] [value]"
            exit 1
            ;;
    esac
}

# Emergency procedures
emergency_stop() {
    log "WARN" "Activating emergency stop for all AI workflows..."

    set_variable "EMERGENCY_STOP_ENABLED" "true"
    set_variable "AI_CIRCUIT_STATE" "OPEN"
    set_variable "AI_CIRCUIT_LAST_FAILURE" "$(date +%s)"

    log "SUCCESS" "Emergency stop activated - all AI workflows halted"
    log "INFO" "To resume operations, run: $0 emergency resume"
}

emergency_resume() {
    log "INFO" "Resuming operations after emergency stop..."

    set_variable "EMERGENCY_STOP_ENABLED" "false"
    set_variable "AI_CIRCUIT_STATE" "CLOSED"
    set_variable "AI_CIRCUIT_FAILURES" "0"

    log "SUCCESS" "Emergency stop lifted - normal operations resumed"
}

# Main command processing
main() {
    local command="${1:-}"

    case "$command" in
        "status")
            check_gh_cli
            show_status
            ;;

        "reset")
            check_gh_cli
            reset_circuit
            ;;

        "open")
            check_gh_cli
            open_circuit
            ;;

        "close")
            check_gh_cli
            close_circuit
            ;;

        "test")
            check_gh_cli
            local simulate="${2:-false}"
            if [[ "$simulate" == "--simulate-failure" ]]; then
                test_circuit "true"
            else
                test_circuit "false"
            fi
            ;;

        "monitor")
            check_gh_cli
            local interval="60"
            if [[ "$2" == "--interval" && -n "$3" ]]; then
                interval="$3"
            fi
            monitor_circuit "$interval"
            ;;

        "stats")
            check_gh_cli
            show_stats
            ;;

        "config")
            check_gh_cli
            manage_config "${2:-show}" "$3" "$4"
            ;;

        "emergency")
            check_gh_cli
            case "${2:-}" in
                "stop")
                    emergency_stop
                    ;;
                "resume")
                    emergency_resume
                    ;;
                *)
                    log "ERROR" "Usage: $0 emergency [stop|resume]"
                    exit 1
                    ;;
            esac
            ;;

        "help"|"-h"|"--help"|"")
            show_help
            ;;

        *)
            log "ERROR" "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
