#!/bin/bash

# Cost Monitor and Management for AI Workflows
# This script provides comprehensive cost tracking and alerting functionality

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

# Default cost estimates by operation type (USD)
# Format: operation_type:cost_usd
OPERATION_COSTS_CONFIG="
lint:0.25
security:0.50
tests:0.75
docs:0.30
general:0.50
"

# Function to get cost for operation type
get_operation_cost() {
    local operation="$1"
    echo "$OPERATION_COSTS_CONFIG" | grep "^${operation}:" | cut -d: -f2 | head -1
}

# Help function
show_help() {
    cat << EOF
Cost Monitor and Management for AI Workflows

USAGE:
    $0 <command> [options]

COMMANDS:
    status              Show current cost status and limits
    track               Track a new AI operation cost
    reset               Reset daily/monthly counters
    alert               Check and send cost alerts
    report              Generate detailed cost report
    limits              Show/update cost limits
    estimate            Estimate cost for planned operations
    history             Show cost history and trends

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -r, --repo REPO     Specify repository (default: current)

EXAMPLES:
    $0 status                           # Check current costs
    $0 track --type lint --cost 0.25    # Track a lint operation
    $0 reset --daily                    # Reset daily counter
    $0 alert --threshold 80             # Check if 80% limit reached
    $0 limits --daily 100 --monthly 1000 # Update cost limits
    $0 estimate --operations "lint,security,tests" # Estimate batch cost

COST TRACKING:
    Daily Limit:       Default \$50, resets at midnight UTC
    Monthly Limit:     Default \$500, resets on 1st of month
    Alert Threshold:   Default 80% of limits
    Operation Types:   lint, security, tests, docs, general
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

# Check if required tools are available
check_dependencies() {
    if ! command -v gh &> /dev/null; then
        log "ERROR" "GitHub CLI (gh) is not installed. Please install it first."
        exit 1
    fi

    if ! command -v bc &> /dev/null; then
        log "ERROR" "bc calculator is not installed. Please install it first."
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

# Reset daily counter if needed
reset_daily_if_needed() {
    local last_reset=$(get_variable "AI_COST_LAST_RESET" "")
    local current_date=$(date +%Y-%m-%d)

    if [[ "$last_reset" != "$current_date" ]]; then
        log "INFO" "Resetting daily cost counter for $current_date"
        set_variable "AI_DAILY_COST" "0"
        set_variable "AI_COST_LAST_RESET" "$current_date"
        return 0  # Reset occurred
    fi

    return 1  # No reset needed
}

# Reset monthly counter if needed
reset_monthly_if_needed() {
    local last_monthly_reset=$(get_variable "AI_MONTHLY_RESET" "")
    local current_month=$(date +%Y-%m)

    if [[ "$last_monthly_reset" != "$current_month" ]]; then
        log "INFO" "Resetting monthly cost counter for $current_month"
        set_variable "AI_MONTHLY_COST" "0"
        set_variable "AI_MONTHLY_RESET" "$current_month"
        return 0  # Reset occurred
    fi

    return 1  # No reset needed
}

# Get current cost status
get_cost_status() {
    # Ensure counters are up to date
    reset_daily_if_needed
    reset_monthly_if_needed

    local daily_cost=$(get_variable "AI_DAILY_COST" "0")
    local monthly_cost=$(get_variable "AI_MONTHLY_COST" "0")
    local max_daily=$(get_variable "MAX_DAILY_COST" "50")
    local max_monthly=$(get_variable "MAX_MONTHLY_COST" "500")
    local alert_threshold=$(get_variable "COST_ALERT_THRESHOLD" "80")

    echo "DAILY_COST:$daily_cost"
    echo "MONTHLY_COST:$monthly_cost"
    echo "MAX_DAILY:$max_daily"
    echo "MAX_MONTHLY:$max_monthly"
    echo "ALERT_THRESHOLD:$alert_threshold"
}

# Show formatted cost status
show_status() {
    log "INFO" "Checking current cost status..."

    local status_info=$(get_cost_status)
    local daily_cost=$(echo "$status_info" | grep "DAILY_COST:" | cut -d':' -f2)
    local monthly_cost=$(echo "$status_info" | grep "MONTHLY_COST:" | cut -d':' -f2)
    local max_daily=$(echo "$status_info" | grep "MAX_DAILY:" | cut -d':' -f2)
    local max_monthly=$(echo "$status_info" | grep "MAX_MONTHLY:" | cut -d':' -f2)
    local alert_threshold=$(echo "$status_info" | grep "ALERT_THRESHOLD:" | cut -d':' -f2)

    # Calculate percentages
    local daily_percent=$(echo "scale=1; $daily_cost / $max_daily * 100" | bc -l)
    local monthly_percent=$(echo "scale=1; $monthly_cost / $max_monthly * 100" | bc -l)

    echo
    echo "======================================"
    echo "         AI WORKFLOW COSTS           "
    echo "======================================"

    # Daily costs with color coding
    if (( $(echo "$daily_percent > $alert_threshold" | bc -l) )); then
        echo -e "Daily Cost:      ${RED}\$$daily_cost${NC} / \$$max_daily (${daily_percent}%)"
    elif (( $(echo "$daily_percent > 50" | bc -l) )); then
        echo -e "Daily Cost:      ${YELLOW}\$$daily_cost${NC} / \$$max_daily (${daily_percent}%)"
    else
        echo -e "Daily Cost:      ${GREEN}\$$daily_cost${NC} / \$$max_daily (${daily_percent}%)"
    fi

    # Monthly costs with color coding
    if (( $(echo "$monthly_percent > $alert_threshold" | bc -l) )); then
        echo -e "Monthly Cost:    ${RED}\$$monthly_cost${NC} / \$$max_monthly (${monthly_percent}%)"
    elif (( $(echo "$monthly_percent > 50" | bc -l) )); then
        echo -e "Monthly Cost:    ${YELLOW}\$$monthly_cost${NC} / \$$max_monthly (${monthly_percent}%)"
    else
        echo -e "Monthly Cost:    ${GREEN}\$$monthly_cost${NC} / \$$max_monthly (${monthly_percent}%)"
    fi

    # Remaining budget
    local daily_remaining=$(echo "$max_daily - $daily_cost" | bc -l)
    local monthly_remaining=$(echo "$max_monthly - $monthly_cost" | bc -l)

    echo "Daily Remaining: \$$daily_remaining"
    echo "Monthly Remaining: \$$monthly_remaining"
    echo "Alert Threshold: ${alert_threshold}%"

    # Show estimated operations remaining
    local avg_cost="0.50"  # Average operation cost
    local daily_ops_remaining=$(echo "scale=0; $daily_remaining / $avg_cost" | bc -l)
    local monthly_ops_remaining=$(echo "scale=0; $monthly_remaining / $avg_cost" | bc -l)

    echo "Est. Operations: ~$daily_ops_remaining daily, ~$monthly_ops_remaining monthly"
    echo "======================================"

    # Show alerts if thresholds exceeded
    if (( $(echo "$daily_percent > $alert_threshold" | bc -l) )); then
        echo -e "${YELLOW}⚠️  Daily cost alert threshold exceeded!${NC}"
    fi

    if (( $(echo "$monthly_percent > $alert_threshold" | bc -l) )); then
        echo -e "${YELLOW}⚠️  Monthly cost alert threshold exceeded!${NC}"
    fi
}

# Track a new operation cost
track_operation() {
    local operation_type="${1:-general}"
    local custom_cost="${2:-}"

    # Determine cost
    local cost="$custom_cost"
    if [[ -z "$cost" ]]; then
        cost="$(get_operation_cost "$operation_type")"
        if [[ -z "$cost" ]]; then
            cost="$(get_operation_cost "general")"
        fi
    fi

    log "INFO" "Tracking $operation_type operation: \$$cost"

    # Check if operation would exceed limits
    local status_info=$(get_cost_status)
    local daily_cost=$(echo "$status_info" | grep "DAILY_COST:" | cut -d':' -f2)
    local monthly_cost=$(echo "$status_info" | grep "MONTHLY_COST:" | cut -d':' -f2)
    local max_daily=$(echo "$status_info" | grep "MAX_DAILY:" | cut -d':' -f2)
    local max_monthly=$(echo "$status_info" | grep "MAX_MONTHLY:" | cut -d':' -f2)

    local new_daily=$(echo "$daily_cost + $cost" | bc -l)
    local new_monthly=$(echo "$monthly_cost + $cost" | bc -l)

    # Check limits
    if (( $(echo "$new_daily > $max_daily" | bc -l) )); then
        log "ERROR" "Operation would exceed daily limit: \$$new_daily > \$$max_daily"
        return 1
    fi

    if (( $(echo "$new_monthly > $max_monthly" | bc -l) )); then
        log "ERROR" "Operation would exceed monthly limit: \$$new_monthly > \$$max_monthly"
        return 1
    fi

    # Update costs
    set_variable "AI_DAILY_COST" "$new_daily"
    set_variable "AI_MONTHLY_COST" "$new_monthly"

    # Log the operation with timestamp
    local timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    local log_entry="$timestamp,$operation_type,$cost,$new_daily,$new_monthly"
    local cost_log=$(get_variable "AI_COST_LOG" "")

    # Keep only last 100 entries (basic log rotation)
    local new_log="$log_entry"
    if [[ -n "$cost_log" ]]; then
        new_log="$cost_log\n$log_entry"
        new_log=$(echo -e "$new_log" | tail -100)
    fi

    set_variable "AI_COST_LOG" "$new_log"

    log "SUCCESS" "Cost tracked: Daily=\$$new_daily, Monthly=\$$new_monthly"

    # Check if we should send alerts
    check_alerts
}

# Check and send cost alerts
check_alerts() {
    local custom_threshold="${1:-}"

    local status_info=$(get_cost_status)
    local daily_cost=$(echo "$status_info" | grep "DAILY_COST:" | cut -d':' -f2)
    local monthly_cost=$(echo "$status_info" | grep "MONTHLY_COST:" | cut -d':' -f2)
    local max_daily=$(echo "$status_info" | grep "MAX_DAILY:" | cut -d':' -f2)
    local max_monthly=$(echo "$status_info" | grep "MAX_MONTHLY:" | cut -d':' -f2)
    local alert_threshold="${custom_threshold:-$(echo "$status_info" | grep "ALERT_THRESHOLD:" | cut -d':' -f2)}"

    local daily_percent=$(echo "scale=1; $daily_cost / $max_daily * 100" | bc -l)
    local monthly_percent=$(echo "scale=1; $monthly_cost / $max_monthly * 100" | bc -l)

    local alerts_sent="false"

    # Check daily threshold
    if (( $(echo "$daily_percent > $alert_threshold" | bc -l) )); then
        log "WARN" "Daily cost alert: ${daily_percent}% of limit used (\$$daily_cost/\$$max_daily)"
        alerts_sent="true"
    fi

    # Check monthly threshold
    if (( $(echo "$monthly_percent > $alert_threshold" | bc -l) )); then
        log "WARN" "Monthly cost alert: ${monthly_percent}% of limit used (\$$monthly_cost/\$$max_monthly)"
        alerts_sent="true"
    fi

    # Check for high individual operation costs
    local recent_operations=$(get_variable "AI_COST_LOG" "" | tail -10)
    if [[ -n "$recent_operations" ]]; then
        while IFS=',' read -r timestamp type cost daily monthly; do
            if (( $(echo "$cost > 2.00" | bc -l) )); then
                log "WARN" "High-cost operation detected: $type (\$$cost) at $timestamp"
                alerts_sent="true"
            fi
        done <<< "$recent_operations"
    fi

    if [[ "$alerts_sent" == "false" ]]; then
        log "INFO" "No cost alerts triggered (threshold: ${alert_threshold}%)"
    fi
}

# Reset cost counters
reset_costs() {
    local reset_type="${1:-both}"

    case "$reset_type" in
        "daily")
            set_variable "AI_DAILY_COST" "0"
            set_variable "AI_COST_LAST_RESET" "$(date +%Y-%m-%d)"
            log "SUCCESS" "Daily cost counter reset"
            ;;

        "monthly")
            set_variable "AI_MONTHLY_COST" "0"
            set_variable "AI_MONTHLY_RESET" "$(date +%Y-%m)"
            log "SUCCESS" "Monthly cost counter reset"
            ;;

        "both")
            set_variable "AI_DAILY_COST" "0"
            set_variable "AI_MONTHLY_COST" "0"
            set_variable "AI_COST_LAST_RESET" "$(date +%Y-%m-%d)"
            set_variable "AI_MONTHLY_RESET" "$(date +%Y-%m)"
            log "SUCCESS" "Both daily and monthly cost counters reset"
            ;;

        *)
            log "ERROR" "Invalid reset type: $reset_type. Use: daily, monthly, or both"
            exit 1
            ;;
    esac
}

# Generate detailed cost report
generate_report() {
    log "INFO" "Generating detailed cost report..."

    local status_info=$(get_cost_status)
    local daily_cost=$(echo "$status_info" | grep "DAILY_COST:" | cut -d':' -f2)
    local monthly_cost=$(echo "$status_info" | grep "MONTHLY_COST:" | cut -d':' -f2)
    local max_daily=$(echo "$status_info" | grep "MAX_DAILY:" | cut -d':' -f2)
    local max_monthly=$(echo "$status_info" | grep "MAX_MONTHLY:" | cut -d':' -f2)

    echo
    echo "======================================"
    echo "      DETAILED COST REPORT           "
    echo "======================================"
    echo "Report Generated: $(date)"
    echo "Repository: $(git remote get-url origin 2>/dev/null | sed 's/.*github.com[\/:]//; s/\.git$//' || echo 'Unknown')"
    echo

    # Current status
    echo "CURRENT STATUS:"
    echo "---------------"
    echo "Daily Cost:      \$$daily_cost / \$$max_daily"
    echo "Monthly Cost:    \$$monthly_cost / \$$max_monthly"
    echo "Daily Usage:     $(echo "scale=1; $daily_cost / $max_daily * 100" | bc -l)%"
    echo "Monthly Usage:   $(echo "scale=1; $monthly_cost / $max_monthly * 100" | bc -l)%"
    echo

    # Recent operations
    echo "RECENT OPERATIONS:"
    echo "------------------"
    local cost_log=$(get_variable "AI_COST_LOG" "")
    if [[ -n "$cost_log" ]]; then
        echo "Timestamp                | Type     | Cost   | Daily Total | Monthly Total"
        echo "-------------------------|----------|--------|-------------|---------------"
        echo -e "$cost_log" | tail -20 | while IFS=',' read -r timestamp type cost daily monthly; do
            printf "%-24s | %-8s | \$%-5s | \$%-10s | \$%-12s\n" "$timestamp" "$type" "$cost" "$daily" "$monthly"
        done
    else
        echo "No operations recorded yet."
    fi
    echo

    # Cost breakdown by operation type
    echo "COST BREAKDOWN BY TYPE:"
    echo "-----------------------"
    if [[ -n "$cost_log" ]]; then
        declare -A type_costs
        declare -A type_counts

        echo -e "$cost_log" | while IFS=',' read -r timestamp type cost daily monthly; do
            type_costs["$type"]=$(echo "${type_costs[$type]:-0} + $cost" | bc -l)
            type_counts["$type"]=$((${type_counts[$type]:-0} + 1))
        done

        for type in "${!type_costs[@]}"; do
            local avg_cost=$(echo "scale=2; ${type_costs[$type]} / ${type_counts[$type]}" | bc -l)
            printf "%-12s: \$%-8s (%d operations, \$%.2f avg)\n" "$type" "${type_costs[$type]}" "${type_counts[$type]}" "$avg_cost"
        done
    else
        echo "No operation data available."
    fi
    echo

    # Projections
    echo "COST PROJECTIONS:"
    echo "-----------------"
    local days_in_month=$(date +%d)
    local total_days_in_month=$(date -d "$(date +%Y-%m-01) +1 month -1 day" +%d)

    if [[ $days_in_month -gt 1 ]]; then
        local daily_avg=$(echo "scale=2; $monthly_cost / $days_in_month" | bc -l)
        local projected_monthly=$(echo "scale=2; $daily_avg * $total_days_in_month" | bc -l)

        echo "Average daily cost:      \$$daily_avg"
        echo "Projected monthly cost:  \$$projected_monthly"
        echo "Projection accuracy:     Based on $days_in_month days of data"

        if (( $(echo "$projected_monthly > $max_monthly" | bc -l) )); then
            echo -e "${RED}⚠️  Projected monthly cost exceeds limit!${NC}"
        fi
    else
        echo "Insufficient data for projections (need at least 2 days)"
    fi

    echo "======================================"
}

# Estimate costs for planned operations
estimate_costs() {
    local operations="${1:-}"

    if [[ -z "$operations" ]]; then
        log "ERROR" "Please specify operations to estimate (e.g., 'lint,security,tests')"
        exit 1
    fi

    log "INFO" "Estimating costs for planned operations..."

    local total_estimate="0"
    local operation_count=0

    echo
    echo "======================================"
    echo "         COST ESTIMATION             "
    echo "======================================"

    IFS=',' read -ra OPS <<< "$operations"
    for operation in "${OPS[@]}"; do
        operation=$(echo "$operation" | xargs)  # Trim whitespace
        local cost="$(get_operation_cost "$operation")"
        if [[ -z "$cost" ]]; then
            cost="$(get_operation_cost "general")"
        fi
        total_estimate=$(echo "$total_estimate + $cost" | bc -l)
        operation_count=$((operation_count + 1))

        echo "$(printf "%-12s" "$operation"): \$$cost"
    done

    echo "--------------------------------"
    echo "Total Estimate:  \$$total_estimate"
    echo "Operations:      $operation_count"
    echo "Average Cost:    \$$(echo "scale=2; $total_estimate / $operation_count" | bc -l)"
    echo

    # Check against current limits
    local status_info=$(get_cost_status)
    local daily_cost=$(echo "$status_info" | grep "DAILY_COST:" | cut -d':' -f2)
    local monthly_cost=$(echo "$status_info" | grep "MONTHLY_COST:" | cut -d':' -f2)
    local max_daily=$(echo "$status_info" | grep "MAX_DAILY:" | cut -d':' -f2)
    local max_monthly=$(echo "$status_info" | grep "MAX_MONTHLY:" | cut -d':' -f2)

    local new_daily=$(echo "$daily_cost + $total_estimate" | bc -l)
    local new_monthly=$(echo "$monthly_cost + $total_estimate" | bc -l)

    echo "IMPACT ANALYSIS:"
    echo "Current Daily:   \$$daily_cost"
    echo "After Operations: \$$new_daily / \$$max_daily"
    echo "Current Monthly: \$$monthly_cost"
    echo "After Operations: \$$new_monthly / \$$max_monthly"
    echo

    # Check if estimates would exceed limits
    if (( $(echo "$new_daily > $max_daily" | bc -l) )); then
        echo -e "${RED}❌ Daily limit would be exceeded!${NC}"
    elif (( $(echo "$new_daily / $max_daily > 0.8" | bc -l) )); then
        echo -e "${YELLOW}⚠️  Would use >80% of daily limit${NC}"
    else
        echo -e "${GREEN}✅ Within daily limits${NC}"
    fi

    if (( $(echo "$new_monthly > $max_monthly" | bc -l) )); then
        echo -e "${RED}❌ Monthly limit would be exceeded!${NC}"
    elif (( $(echo "$new_monthly / $max_monthly > 0.8" | bc -l) )); then
        echo -e "${YELLOW}⚠️  Would use >80% of monthly limit${NC}"
    else
        echo -e "${GREEN}✅ Within monthly limits${NC}"
    fi

    echo "======================================"
}

# Show/update cost limits
manage_limits() {
    local action="${1:-show}"
    local daily_limit="${2:-}"
    local monthly_limit="${3:-}"

    case "$action" in
        "show")
            local max_daily=$(get_variable "MAX_DAILY_COST" "50")
            local max_monthly=$(get_variable "MAX_MONTHLY_COST" "500")
            local alert_threshold=$(get_variable "COST_ALERT_THRESHOLD" "80")

            echo
            echo "======================================"
            echo "         COST LIMITS                 "
            echo "======================================"
            echo "Daily Limit:         \$$max_daily"
            echo "Monthly Limit:       \$$max_monthly"
            echo "Alert Threshold:     ${alert_threshold}%"
            echo "======================================"
            ;;

        "set")
            if [[ -n "$daily_limit" ]]; then
                set_variable "MAX_DAILY_COST" "$daily_limit"
                log "SUCCESS" "Daily cost limit set to \$$daily_limit"
            fi

            if [[ -n "$monthly_limit" ]]; then
                set_variable "MAX_MONTHLY_COST" "$monthly_limit"
                log "SUCCESS" "Monthly cost limit set to \$$monthly_limit"
            fi

            if [[ -z "$daily_limit" && -z "$monthly_limit" ]]; then
                log "ERROR" "Please specify at least one limit to set"
                log "INFO" "Usage: $0 limits set <daily_limit> [monthly_limit]"
                exit 1
            fi
            ;;

        *)
            log "ERROR" "Usage: $0 limits [show|set] [daily_limit] [monthly_limit]"
            exit 1
            ;;
    esac
}

# Show cost history and trends
show_history() {
    log "INFO" "Analyzing cost history and trends..."

    local cost_log=$(get_variable "AI_COST_LOG" "")

    if [[ -z "$cost_log" ]]; then
        log "WARN" "No cost history available"
        return
    fi

    echo
    echo "======================================"
    echo "       COST HISTORY & TRENDS         "
    echo "======================================"

    # Calculate daily trends
    declare -A daily_totals
    echo -e "$cost_log" | while IFS=',' read -r timestamp type cost daily monthly; do
        local date=$(echo "$timestamp" | cut -d'T' -f1)
        daily_totals["$date"]=$(echo "${daily_totals[$date]:-0} + $cost" | bc -l)
    done

    echo "DAILY SPENDING TREND (Last 7 days):"
    echo "------------------------------------"
    local days=0
    for date in $(printf '%s\n' "${!daily_totals[@]}" | sort -r | head -7); do
        echo "$date: \$${daily_totals[$date]}"
        days=$((days + 1))
    done

    if [[ $days -gt 1 ]]; then
        # Calculate trend
        local total_recent="0"
        for date in $(printf '%s\n' "${!daily_totals[@]}" | sort -r | head -7); do
            total_recent=$(echo "$total_recent + ${daily_totals[$date]}" | bc -l)
        done
        local avg_daily=$(echo "scale=2; $total_recent / $days" | bc -l)
        echo
        echo "Average daily spend:     \$$avg_daily"
        echo "Trend period:            $days days"
    fi

    echo "======================================"
}

# Main command processing
main() {
    local command="${1:-}"

    case "$command" in
        "status")
            check_dependencies
            show_status
            ;;

        "track")
            check_dependencies
            local operation_type="general"
            local custom_cost=""

            # Parse arguments
            shift
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --type)
                        operation_type="$2"
                        shift 2
                        ;;
                    --cost)
                        custom_cost="$2"
                        shift 2
                        ;;
                    *)
                        log "ERROR" "Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            track_operation "$operation_type" "$custom_cost"
            ;;

        "reset")
            check_dependencies
            local reset_type="both"
            if [[ "$2" == "--daily" ]]; then
                reset_type="daily"
            elif [[ "$2" == "--monthly" ]]; then
                reset_type="monthly"
            fi
            reset_costs "$reset_type"
            ;;

        "alert")
            check_dependencies
            local threshold=""
            if [[ "$2" == "--threshold" && -n "$3" ]]; then
                threshold="$3"
            fi
            check_alerts "$threshold"
            ;;

        "report")
            check_dependencies
            generate_report
            ;;

        "estimate")
            local operations=""
            if [[ "$2" == "--operations" && -n "$3" ]]; then
                operations="$3"
            else
                log "ERROR" "Usage: $0 estimate --operations 'lint,security,tests'"
                exit 1
            fi
            estimate_costs "$operations"
            ;;

        "limits")
            check_dependencies
            manage_limits "${2:-show}" "$3" "$4"
            ;;

        "history")
            check_dependencies
            show_history
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
