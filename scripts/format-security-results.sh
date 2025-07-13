#!/bin/bash
set -euo pipefail

# Security Results Formatter
# Converts raw security scan results (JSON) into readable markdown tables/charts

# Function to validate and sanitize numeric input
validate_number() {
    local value="$1"
    local default_value="${2:-0}"
    
    # Check if value is a valid non-negative integer
    if [[ "$value" =~ ^[0-9]+$ ]]; then
        echo "$value"
    else
        echo "$default_value"
    fi
}

# Function to format Bandit results
format_bandit_results() {
    local json_file="$1"

    if [[ ! -f "$json_file" ]]; then
        echo "No Bandit results found."
        return
    fi

    if ! jq empty "$json_file" 2>/dev/null; then
        echo "Invalid or missing Bandit results file."
        return
    fi

    local results_count
    results_count=$(jq '.results | length' "$json_file" 2>/dev/null || echo "0")
    results_count=$(validate_number "$results_count" 0)

    if [[ "$results_count" -eq 0 ]]; then
        echo "✅ **No security issues found by Bandit**"
        return
    fi

    # Count severity levels with a single jq call
    local severity_counts
    severity_counts=$(jq -r '
        [.results[]] |
        group_by(.issue_severity) |
        map({severity: .[0].issue_severity, count: length}) |
        .[] |
        "\(.severity):\(.count)"
    ' "$json_file")

    local high_count=0 medium_count=0 low_count=0
    while IFS=: read -r severity count; do
        case "$severity" in
            HIGH) high_count=$(validate_number "$count" 0) ;;
            MEDIUM) medium_count=$(validate_number "$count" 0) ;;
            LOW) low_count=$(validate_number "$count" 0) ;;
        esac
    done <<< "$severity_counts"

    cat << EOF
## 🔍 Bandit Security Scan Results

### Summary
- **Total Issues**: $results_count
- **High Severity**: $high_count issues
- **Medium Severity**: $medium_count issues
- **Low Severity**: $low_count issues

### Severity Distribution
\`\`\`
High   │$(printf '█%.0s' $(seq 1 $((high_count > 10 ? 10 : high_count))))$(printf '░%.0s' $(seq 1 $((10 - (high_count > 10 ? 10 : high_count))))) │ $high_count
Medium │$(printf '█%.0s' $(seq 1 $((medium_count > 10 ? 10 : medium_count))))$(printf '░%.0s' $(seq 1 $((10 - (medium_count > 10 ? 10 : medium_count))))) │ $medium_count
Low    │$(printf '█%.0s' $(seq 1 $((low_count > 10 ? 10 : low_count))))$(printf '░%.0s' $(seq 1 $((10 - (low_count > 10 ? 10 : low_count))))) │ $low_count
\`\`\`

### Issues Found

| Severity | Confidence | Test ID | File | Line | Issue |
|----------|------------|---------|------|------|-------|
EOF

    # Output sorted results
    jq -r '.results[] |
        [
            (if .issue_severity == "HIGH" then "🚨 HIGH"
             elif .issue_severity == "MEDIUM" then "⚠️ MEDIUM"
             else "💡 LOW" end),
            .issue_confidence,
            .test_id,
            ("`" + (.filename | if length > 30 then "..." + .[-27:] else . end) + "`"),
            .line_number,
            (.issue_text | gsub("\n"; " ") | if length > 60 then .[:57] + "..." else . end)
        ] |
        @tsv' "$json_file" |
    while IFS=$'\t' read -r severity confidence test_id filename line issue; do
        echo "| $severity | $confidence | $test_id | $filename | $line | $issue |"
    done
}

# Function to format Safety results
format_safety_results() {
    local json_file="$1"

    if [[ ! -f "$json_file" ]]; then
        echo "No Safety results found."
        return
    fi

    if ! jq empty "$json_file" 2>/dev/null; then
        echo "Invalid or missing Safety results file."
        return
    fi

    local vuln_count
    vuln_count=$(jq '. | length' "$json_file" 2>/dev/null || echo "0")

    if [[ "$vuln_count" -eq 0 ]]; then
        echo "✅ **No vulnerable dependencies found by Safety**"
        return
    fi

    cat << EOF
## 🛡️ Safety Dependency Check Results

### Summary
- **Total Vulnerabilities**: $vuln_count

### Vulnerable Dependencies

| Package | Version | Vulnerability | CVE | Severity |
|---------|---------|---------------|-----|----------|
EOF

    jq -r '.[] |
        [
            ("`" + .package + "`"),
            .installed_version,
            (.vulnerability | gsub("\n"; " ") | if length > 50 then .[:47] + "..." else . end),
            .vulnerability_id,
            (if (.vulnerability | ascii_downcase | test("critical|remote code execution|rce")) then "🚨 HIGH"
             elif (.vulnerability | ascii_downcase | test("low|minor")) then "💡 LOW"
             else "⚠️ MEDIUM" end)
        ] |
        @tsv' "$json_file" |
    while IFS=$'\t' read -r package version vuln cve severity; do
        echo "| $package | $version | $vuln | $cve | $severity |"
    done
}

# Function to format Semgrep results
format_semgrep_results() {
    local json_file="$1"

    if [[ ! -f "$json_file" ]]; then
        echo "No Semgrep results found."
        return
    fi

    if ! jq empty "$json_file" 2>/dev/null; then
        echo "Invalid or missing Semgrep results file."
        return
    fi

    local results_count
    results_count=$(jq '.results | length' "$json_file" 2>/dev/null || echo "0")
    results_count=$(validate_number "$results_count" 0)

    if [[ "$results_count" -eq 0 ]]; then
        echo "✅ **No security issues found by Semgrep**"
        return
    fi

    # Count by severity with a single jq call
    local severity_counts
    severity_counts=$(jq -r '
        [.results[]] |
        map((.extra.severity // "INFO") | ascii_upcase) |
        group_by(.) |
        map({severity: .[0], count: length}) |
        .[] |
        "\(.severity):\(.count)"
    ' "$json_file")

    local error_count=0 warning_count=0 info_count=0
    while IFS=: read -r severity count; do
        case "$severity" in
            ERROR) error_count="$count" ;;
            WARNING) warning_count="$count" ;;
            INFO) info_count="$count" ;;
        esac
    done <<< "$severity_counts"

    cat << EOF
## ⚡ Semgrep Security Scan Results

### Summary
- **Total Issues**: $results_count
- **Errors**: $error_count issues
- **Warnings**: $warning_count issues
- **Info**: $info_count issues

### Issues Found

| Severity | Rule | File | Line | Message |
|----------|------|------|------|---------|
EOF

    jq -r '.results[] |
        [
            ((.extra.severity // "INFO") | ascii_upcase |
             if . == "ERROR" then "🚨 ERROR"
             elif . == "WARNING" then "⚠️ WARNING"
             else "💡 INFO" end),
            ("`" + .check_id + "`"),
            ("`" + (.path | if length > 30 then "..." + .[-27:] else . end) + "`"),
            .start.line,
            ((.extra.message // "N/A") | gsub("\n"; " ") | if length > 60 then .[:57] + "..." else . end)
        ] |
        @tsv' "$json_file" |
    while IFS=$'\t' read -r severity rule file line message; do
        echo "| $severity | $rule | $file | $line | $message |"
    done
}

# Function to format npm audit results
format_npm_audit_results() {
    local json_file="$1"

    if [[ ! -f "$json_file" ]]; then
        echo "No npm audit results found."
        return
    fi

    if ! jq empty "$json_file" 2>/dev/null; then
        echo "Invalid or missing npm audit results file."
        return
    fi

    local vuln_count
    vuln_count=$(jq '.vulnerabilities | length' "$json_file" 2>/dev/null || echo "0")

    if [[ "$vuln_count" -eq 0 ]]; then
        echo "✅ **No vulnerabilities found by npm audit**"
        return
    fi

    # Count by severity with a single jq call
    local severity_counts
    severity_counts=$(jq -r '
        [.vulnerabilities[] | .severity] |
        group_by(.) |
        map({severity: .[0], count: length}) |
        .[] |
        "\(.severity):\(.count)"
    ' "$json_file")

    local critical_count=0 high_count=0 moderate_count=0 low_count=0
    while IFS=: read -r severity count; do
        case "$severity" in
            critical) critical_count="$count" ;;
            high) high_count="$count" ;;
            moderate) moderate_count="$count" ;;
            low) low_count="$count" ;;
        esac
    done <<< "$severity_counts"

    cat << EOF
## 📦 NPM Audit Results

### Summary
- **Total Vulnerabilities**: $vuln_count
- **Critical**: $critical_count packages
- **High**: $high_count packages
- **Moderate**: $moderate_count packages
- **Low**: $low_count packages

### Vulnerable Packages

| Severity | Package | Via | More Info |
|----------|---------|-----|-----------|
EOF

    jq -r '.vulnerabilities | to_entries[] |
        [
            (.value.severity |
             if . == "critical" then "🚨 Critical"
             elif . == "high" then "⚠️ High"
             elif . == "moderate" then "💡 Moderate"
             else "📝 Low" end),
            ("`" + .key + "`"),
            ((.value.via[:3] | join(", ")) + (if (.value.via | length) > 3 then "..." else "" end)),
            (.value.url // "N/A")
        ] |
        @tsv' "$json_file" |
    while IFS=$'\t' read -r severity package via info; do
        echo "| $severity | $package | $via | $info |"
    done
}

# Main function
main() {
    local output_file="security-report.md"

    # Start with header
    cat > "$output_file" << 'EOF'
# 🔒 Security Review Report

This report contains the results of automated security scans.

EOF

    # Format each tool's results
    {
        format_bandit_results "bandit-results.json"
        echo
        echo
        format_safety_results "safety-results.json"
        echo
        echo
        format_semgrep_results "semgrep-results.json"
        echo
        echo
        format_npm_audit_results "npm-audit-results.json"
        echo
        echo
        echo "---"
        echo
        echo "*Report generated automatically by security review workflow*"
    } >> "$output_file"

    echo "Security report generated: $output_file"
}

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed" >&2
    exit 1
fi

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
