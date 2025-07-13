#!/bin/bash

# Emergency Audit and Management Tool
# This script provides audit trails and management for emergency actions

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
Emergency Audit and Management Tool

USAGE:
    $0 <command> [options]

COMMANDS:
    audit               Show emergency action audit log
    status              Show current emergency status
    restore             Restore original cost limits after override
    cleanup             Clean up temporary emergency settings
    security            Show security incidents log
    summary             Generate emergency actions summary report
    trigger             Trigger emergency controls workflow (workflow_dispatch)

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -r, --repo REPO     Specify repository (default: current)
    --days N            Show events from last N days (default: 30)
    --limit N           Limit output to N entries (default: 50)

EXAMPLES:
    $0 audit                            # Show recent emergency actions
    $0 audit --days 7                   # Show last 7 days
    $0 status                           # Check current emergency status
    $0 restore                          # Restore original cost limits
    $0 security                         # Show security incidents
    $0 summary --days 30                # Generate 30-day summary

EMERGENCY ACTIONS TRACKED:
    - emergency-stop and resume-operations
    - maintenance-mode toggles
    - circuit-breaker-reset actions
    - cost-limit-override modifications
    - Unauthorized access attempts
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
    local repo="${3:-$GITHUB_REPOSITORY}"

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
    local repo="${3:-$GITHUB_REPOSITORY}"

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

# Convert timestamp to human readable format
format_timestamp() {
    local timestamp="$1"

    # Try different timestamp formats
    if [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
        # ISO format
        date -d "$timestamp" '+%Y-%m-%d %H:%M:%S UTC' 2>/dev/null || date -jf '%Y-%m-%dT%H:%M:%SZ' "$timestamp" '+%Y-%m-%d %H:%M:%S UTC' 2>/dev/null || echo "$timestamp"
    elif [[ "$timestamp" =~ ^[0-9]+$ ]]; then
        # Unix timestamp
        date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S UTC' 2>/dev/null || date -r "$timestamp" '+%Y-%m-%d %H:%M:%S UTC' 2>/dev/null || echo "$timestamp"
    else
        echo "$timestamp"
    fi
}

# Show emergency audit log
show_audit_log() {
    local days="${1:-30}"
    local limit="${2:-50}"

    log "INFO" "Retrieving emergency audit log (last $days days, limit $limit entries)..."

    local emergency_log=$(get_variable "EMERGENCY_LOG" "")

    if [[ -z "$emergency_log" ]]; then
        log "WARN" "No emergency actions found in audit log"
        return
    fi

    echo
    echo "======================================"
    echo "       EMERGENCY AUDIT LOG           "
    echo "======================================"
    echo "Last $days days (limited to $limit entries)"
    echo

    # Calculate cutoff date
    local cutoff_date=$(date -d "$days days ago" '+%Y-%m-%d' 2>/dev/null || date -j -v-"$days"d '+%Y-%m-%d' 2>/dev/null || echo "1970-01-01")

    # Parse and display log entries
    echo "Timestamp                | User              | Action                    | Reason"
    echo "-------------------------|-------------------|---------------------------|---------------------------"

    local count=0
    echo -e "$emergency_log" | tail -"$limit" | while IFS=',' read -r timestamp user action reason; do
        if [[ -n "$timestamp" ]]; then
            # Check if entry is within date range
            local entry_date=$(echo "$timestamp" | cut -d'T' -f1)
            if [[ "$entry_date" > "$cutoff_date" ]] || [[ "$entry_date" == "$cutoff_date" ]]; then
                local formatted_time=$(format_timestamp "$timestamp" | cut -d' ' -f1-2)
                printf "%-24s | %-17s | %-25s | %-25s\n" "$formatted_time" "$user" "$action" "$reason"
                count=$((count + 1))
            fi
        fi
    done

    echo "======================================"
    echo "Total entries shown: $count"
}

# Show current emergency status
show_emergency_status() {
    log "INFO" "Checking current emergency status..."

    # Get all emergency-related variables
    local emergency_stop=$(get_variable "EMERGENCY_STOP_ENABLED" "false")
    local maintenance_mode=$(get_variable "MAINTENANCE_MODE" "false")
    local circuit_state=$(get_variable "AI_CIRCUIT_STATE" "CLOSED")
    local circuit_failures=$(get_variable "AI_CIRCUIT_FAILURES" "0")
    local cost_override=$(get_variable "COST_LIMIT_OVERRIDE" "false")

    echo
    echo "======================================"
    echo "       EMERGENCY STATUS              "
    echo "======================================"

    # Emergency Stop Status
    if [[ "$emergency_stop" == "true" ]]; then
        echo -e "Emergency Stop:    ${RED}ACTIVE${NC} 🚨"
        echo "                   All AI workflows are halted"
    else
        echo -e "Emergency Stop:    ${GREEN}INACTIVE${NC} ✅"
    fi

    # Maintenance Mode Status
    if [[ "$maintenance_mode" == "true" ]]; then
        echo -e "Maintenance Mode:  ${YELLOW}ENABLED${NC} 🔧"
        echo "                   System under maintenance"
    else
        echo -e "Maintenance Mode:  ${GREEN}DISABLED${NC} ✅"
    fi

    # Circuit Breaker Status
    case "$circuit_state" in
        "CLOSED")
            echo -e "Circuit Breaker:   ${GREEN}CLOSED${NC} ✅ (Normal operation)"
            ;;
        "OPEN")
            echo -e "Circuit Breaker:   ${RED}OPEN${NC} 🔴 (Circuit tripped)"
            ;;
        "HALF-OPEN")
            echo -e "Circuit Breaker:   ${YELLOW}HALF-OPEN${NC} ⚡ (Testing recovery)"
            ;;
        *)
            echo -e "Circuit Breaker:   ${BLUE}$circuit_state${NC}"
            ;;
    esac
    echo "                   Failures: $circuit_failures"

    # Cost Override Status
    if [[ "$cost_override" == "true" ]]; then
        local override_time=$(get_variable "COST_LIMIT_OVERRIDE_TIMESTAMP" "")
        local daily_limit=$(get_variable "MAX_DAILY_COST" "unknown")
        local monthly_limit=$(get_variable "MAX_MONTHLY_COST" "unknown")

        echo -e "Cost Override:     ${YELLOW}ACTIVE${NC} 💰"
        echo "                   Daily: \$$daily_limit, Monthly: \$$monthly_limit"

        if [[ -n "$override_time" ]]; then
            local override_date=$(format_timestamp "$override_time")
            echo "                   Since: $override_date"
        fi
    else
        echo -e "Cost Override:     ${GREEN}INACTIVE${NC} ✅"
    fi

    echo "======================================"

    # Overall system status
    local overall_status="NORMAL"
    if [[ "$emergency_stop" == "true" ]]; then
        overall_status="EMERGENCY STOP"
    elif [[ "$maintenance_mode" == "true" ]]; then
        overall_status="MAINTENANCE"
    elif [[ "$circuit_state" == "OPEN" ]]; then
        overall_status="CIRCUIT OPEN"
    elif [[ "$cost_override" == "true" ]]; then
        overall_status="COST OVERRIDE"
    fi

    case "$overall_status" in
        "NORMAL")
            echo -e "Overall Status:    ${GREEN}$overall_status${NC} 🟢"
            ;;
        "EMERGENCY STOP")
            echo -e "Overall Status:    ${RED}$overall_status${NC} 🚨"
            ;;
        "MAINTENANCE")
            echo -e "Overall Status:    ${YELLOW}$overall_status${NC} 🔧"
            ;;
        *)
            echo -e "Overall Status:    ${YELLOW}$overall_status${NC} ⚠️"
            ;;
    esac
}

# Restore original cost limits
restore_cost_limits() {
    log "INFO" "Checking for cost limit overrides to restore..."

    local cost_override=$(get_variable "COST_LIMIT_OVERRIDE" "false")

    if [[ "$cost_override" != "true" ]]; then
        log "INFO" "No active cost limit override found"
        return
    fi

    # Get original limits
    local original_daily=$(get_variable "COST_LIMIT_ORIGINAL_DAILY" "")
    local original_monthly=$(get_variable "COST_LIMIT_ORIGINAL_MONTHLY" "")

    if [[ -z "$original_daily" || -z "$original_monthly" ]]; then
        log "ERROR" "Original cost limits not found. Cannot restore."
        log "INFO" "Please manually set appropriate limits using the cost-monitor.sh script"
        return 1
    fi

    log "INFO" "Restoring original cost limits..."
    log "INFO" "Daily: \$$original_daily, Monthly: \$$original_monthly"

    # Restore original limits
    set_variable "MAX_DAILY_COST" "$original_daily"
    set_variable "MAX_MONTHLY_COST" "$original_monthly"

    # Clear override flags
    set_variable "COST_LIMIT_OVERRIDE" "false"
    set_variable "COST_LIMIT_OVERRIDE_TIMESTAMP" ""
    set_variable "COST_LIMIT_ORIGINAL_DAILY" ""
    set_variable "COST_LIMIT_ORIGINAL_MONTHLY" ""

    log "SUCCESS" "Original cost limits restored"
}

# Clean up temporary emergency settings
cleanup_emergency_settings() {
    log "INFO" "Cleaning up temporary emergency settings..."

    local cleaned_items=()

    # Check and restore cost limits
    local cost_override=$(get_variable "COST_LIMIT_OVERRIDE" "false")
    if [[ "$cost_override" == "true" ]]; then
        restore_cost_limits
        cleaned_items+=("Cost limit override")
    fi

    # Check for stale maintenance mode (over 24 hours old)
    local maintenance_mode=$(get_variable "MAINTENANCE_MODE" "false")
    if [[ "$maintenance_mode" == "true" ]]; then
        # For now, just report it - don't automatically disable
        log "WARN" "Maintenance mode is still enabled"
        log "INFO" "Use emergency controls workflow to disable if maintenance is complete"
    fi

    # Check for open circuit breaker with old timestamp
    local circuit_state=$(get_variable "AI_CIRCUIT_STATE" "CLOSED")
    local last_failure=$(get_variable "AI_CIRCUIT_LAST_FAILURE" "0")

    if [[ "$circuit_state" == "OPEN" && "$last_failure" != "0" ]]; then
        local current_time=$(date +%s)
        local time_since_failure=$((current_time - last_failure))
        local hours_since_failure=$((time_since_failure / 3600))

        if [[ $hours_since_failure -gt 24 ]]; then
            log "WARN" "Circuit breaker has been open for $hours_since_failure hours"
            log "INFO" "Consider using the circuit-breaker-manager.sh script to reset if appropriate"
        fi
    fi

    if [[ ${#cleaned_items[@]} -eq 0 ]]; then
        log "INFO" "No temporary emergency settings found to clean up"
    else
        log "SUCCESS" "Cleaned up: ${cleaned_items[*]}"
    fi
}

# Show security incidents log
show_security_log() {
    local days="${1:-30}"
    local limit="${2:-25}"

    log "INFO" "Retrieving security incidents log (last $days days, limit $limit entries)..."

    local security_log=$(get_variable "SECURITY_LOG" "")

    if [[ -z "$security_log" ]]; then
        log "INFO" "No security incidents found"
        return
    fi

    echo
    echo "======================================"
    echo "       SECURITY INCIDENTS LOG        "
    echo "======================================"
    echo "Last $days days (limited to $limit entries)"
    echo

    # Calculate cutoff date
    local cutoff_date=$(date -d "$days days ago" '+%Y-%m-%d' 2>/dev/null || date -j -v-"$days"d '+%Y-%m-%d' 2>/dev/null || echo "1970-01-01")

    # Parse and display log entries
    echo "Timestamp                | User              | Incident Type             | Details"
    echo "-------------------------|-------------------|---------------------------|---------------------------"

    local count=0
    echo -e "$security_log" | tail -"$limit" | while IFS=',' read -r timestamp user incident details; do
        if [[ -n "$timestamp" ]]; then
            # Check if entry is within date range
            local entry_date=$(echo "$timestamp" | cut -d'T' -f1)
            if [[ "$entry_date" > "$cutoff_date" ]] || [[ "$entry_date" == "$cutoff_date" ]]; then
                local formatted_time=$(format_timestamp "$timestamp" | cut -d' ' -f1-2)
                printf "%-24s | %-17s | %-25s | %-25s\n" "$formatted_time" "$user" "$incident" "$details"
                count=$((count + 1))
            fi
        fi
    done

    echo "======================================"
    echo "Total incidents shown: $count"
}

# Generate emergency actions summary
generate_summary() {
    local days="${1:-30}"

    log "INFO" "Generating emergency actions summary for last $days days..."

    local emergency_log=$(get_variable "EMERGENCY_LOG" "")
    local security_log=$(get_variable "SECURITY_LOG" "")

    echo
    echo "======================================"
    echo "    EMERGENCY ACTIONS SUMMARY        "
    echo "======================================"
    echo "Report Period: Last $days days"
    echo "Generated: $(date)"
    echo

    # Calculate cutoff date
    local cutoff_date=$(date -d "$days days ago" '+%Y-%m-%d' 2>/dev/null || date -j -v-"$days"d '+%Y-%m-%d' 2>/dev/null || echo "1970-01-01")

    # Count actions by type
    declare -A action_counts
    declare -A user_counts
    local total_actions=0

    if [[ -n "$emergency_log" ]]; then
        while IFS=',' read -r timestamp user action reason; do
            if [[ -n "$timestamp" ]]; then
                local entry_date=$(echo "$timestamp" | cut -d'T' -f1)
                if [[ "$entry_date" > "$cutoff_date" ]] || [[ "$entry_date" == "$cutoff_date" ]]; then
                    action_counts["$action"]=$((${action_counts[$action]:-0} + 1))
                    user_counts["$user"]=$((${user_counts[$user]:-0} + 1))
                    total_actions=$((total_actions + 1))
                fi
            fi
        done <<< "$emergency_log"
    fi

    # Count security incidents
    local security_incidents=0
    if [[ -n "$security_log" ]]; then
        while IFS=',' read -r timestamp user incident details; do
            if [[ -n "$timestamp" ]]; then
                local entry_date=$(echo "$timestamp" | cut -d'T' -f1)
                if [[ "$entry_date" > "$cutoff_date" ]] || [[ "$entry_date" == "$cutoff_date" ]]; then
                    security_incidents=$((security_incidents + 1))
                fi
            fi
        done <<< "$security_log"
    fi

    echo "SUMMARY STATISTICS:"
    echo "-------------------"
    echo "Total Emergency Actions: $total_actions"
    echo "Security Incidents:      $security_incidents"
    echo

    if [[ $total_actions -gt 0 ]]; then
        echo "ACTIONS BY TYPE:"
        echo "----------------"
        for action in "${!action_counts[@]}"; do
            printf "%-25s: %d\n" "$action" "${action_counts[$action]}"
        done
        echo

        echo "ACTIONS BY USER:"
        echo "----------------"
        for user in "${!user_counts[@]}"; do
            printf "%-20s: %d\n" "$user" "${user_counts[$user]}"
        done
        echo
    fi

    # Current status summary
    echo "CURRENT STATUS:"
    echo "---------------"
    local emergency_stop=$(get_variable "EMERGENCY_STOP_ENABLED" "false")
    local maintenance_mode=$(get_variable "MAINTENANCE_MODE" "false")
    local circuit_state=$(get_variable "AI_CIRCUIT_STATE" "CLOSED")
    local cost_override=$(get_variable "COST_LIMIT_OVERRIDE" "false")

    echo "Emergency Stop:          $emergency_stop"
    echo "Maintenance Mode:        $maintenance_mode"
    echo "Circuit Breaker:         $circuit_state"
    echo "Cost Override:           $cost_override"
    echo

    # Recommendations
    echo "RECOMMENDATIONS:"
    echo "----------------"
    if [[ $total_actions -gt 10 ]]; then
        echo "⚠️  High number of emergency actions detected"
        echo "   Consider reviewing system stability and processes"
    fi

    if [[ $security_incidents -gt 0 ]]; then
        echo "⚠️  Security incidents detected"
        echo "   Review access controls and user permissions"
    fi

    if [[ "$cost_override" == "true" ]]; then
        echo "⚠️  Cost override is still active"
        echo "   Consider restoring original limits: $0 restore"
    fi

    if [[ "$emergency_stop" == "true" || "$maintenance_mode" == "true" ]]; then
        echo "⚠️  System is not in normal operation mode"
        echo "   Review and resume normal operations if appropriate"
    fi

    if [[ $total_actions -eq 0 && $security_incidents -eq 0 ]]; then
        echo "✅ No emergency actions or security incidents in the report period"
        echo "   System appears to be operating normally"
    fi

    echo "======================================"
}

# Trigger emergency controls workflow via workflow_dispatch
trigger_emergency_workflow() {
    local action="$2"
    local reason="$3"

    check_gh_cli

    log "INFO" "Triggering emergency-controls.yml workflow with action: $action"

    # Use gh workflow run to trigger emergency-controls.yml
    if gh workflow run emergency-controls.yml \
        --field action="$action" \
        --field reason="$reason"; then
        log "SUCCESS" "Emergency controls workflow triggered successfully"
    else
        log "ERROR" "Failed to trigger emergency controls workflow"
        exit 1
    fi
}

# Main command processing
main() {
    local command="${1:-}"

    case "$command" in
        "audit")
            check_gh_cli
            local days="30"
            local limit="50"

            # Parse arguments
            shift
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --days)
                        days="$2"
                        shift 2
                        ;;
                    --limit)
                        limit="$2"
                        shift 2
                        ;;
                    *)
                        log "ERROR" "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            show_audit_log "$days" "$limit"
            ;;

        "status")
            check_gh_cli
            show_emergency_status
            ;;

        "restore")
            check_gh_cli
            restore_cost_limits
            ;;

        "cleanup")
            check_gh_cli
            cleanup_emergency_settings
            ;;

        "security")
            check_gh_cli
            local days="30"
            local limit="25"

            # Parse arguments
            shift
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --days)
                        days="$2"
                        shift 2
                        ;;
                    --limit)
                        limit="$2"
                        shift 2
                        ;;
                    *)
                        log "ERROR" "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            show_security_log "$days" "$limit"
            ;;

        "summary")
            check_gh_cli
            local days="30"

            # Parse arguments
            shift
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --days)
                        days="$2"
                        shift 2
                        ;;
                    *)
                        log "ERROR" "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            generate_summary "$days"
            ;;

        "trigger")
            # Note: trigger_emergency_workflow already calls check_gh_cli
            trigger_emergency_workflow "$@"
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
