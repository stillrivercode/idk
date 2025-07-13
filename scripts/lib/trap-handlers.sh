#!/bin/bash

# Trap Handler Library
# Provides robust cleanup functions and trap handlers for shell scripts

set -euo pipefail

# Global array to track temporary files for cleanup
declare -a TEMP_FILES_TO_CLEAN=()

# Register a file for cleanup
register_temp_file() {
    local file="$1"
    TEMP_FILES_TO_CLEAN+=("$file")
}

# Secure file deletion with multiple overwrite passes
secure_delete_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 0
    fi

    # Use shred if available (Linux/GNU systems)
    if command -v shred >/dev/null 2>&1; then
        shred -vfz -n 3 "$file" 2>/dev/null || {
            # Fallback if shred fails
            dd if=/dev/urandom of="$file" bs=1024 count=1 2>/dev/null || true
            rm -f "$file"
        }
    # Use gshred if available (macOS with GNU coreutils)
    elif command -v gshred >/dev/null 2>&1; then
        gshred -vfz -n 3 "$file" 2>/dev/null || {
            # Fallback if gshred fails
            dd if=/dev/urandom of="$file" bs=1024 count=1 2>/dev/null || true
            rm -f "$file"
        }
    else
        # Fallback for systems without shred/gshred
        # Multiple overwrites for better security
        dd if=/dev/urandom of="$file" bs=1024 count=1 2>/dev/null || true
        dd if=/dev/zero of="$file" bs=1024 count=1 2>/dev/null || true
        rm -f "$file"
    fi

    echo "🗑️  Securely removed: $file" >&2
}

# Generic cleanup function for AI/temporary files
cleanup_ai_temp_files() {
    local script_name="${1:-unknown}"

    echo "🧹 [$script_name] Cleaning up temporary files..." >&2

    # Common temporary file patterns
    local patterns=(
        "ai_response_*.md"
        "temp_ai_response_*.md"
        "task_prompt_*.md"
        "claude_output_*.log"
        "security_prompt_*.md"
        "security_response_*.md"
        "fix_*_prompt.md"
        "*-fixes.txt"
        "temp_*.tmp"
        "*.tmp.$$"
        "security_analysis_*.tmp"
        "temp_security_*.txt"
    )

    # Clean registered files first
    # Safe array check compatible with set -u (works with all bash versions)
    if [[ -n "${TEMP_FILES_TO_CLEAN+x}" ]] && [[ ${#TEMP_FILES_TO_CLEAN[@]:-0} -gt 0 ]]; then
        local temp_file
        for temp_file in "${TEMP_FILES_TO_CLEAN[@]}"; do
            if [[ -f "$temp_file" ]]; then
                secure_delete_file "$temp_file"
            fi
        done
    fi

    # Clean pattern-based files
    for pattern in "${patterns[@]}"; do
        find . -maxdepth 1 -name "$pattern" -type f 2>/dev/null | while read -r file; do
            if [[ -f "$file" ]]; then
                secure_delete_file "$file"
            fi
        done
    done

    echo "✅ [$script_name] Temporary file cleanup completed" >&2
}

# Set up standard trap handlers for a script
setup_standard_traps() {
    local script_name="${1:-$(basename "$0")}"

    # Define the cleanup function for this script
    eval "cleanup_on_exit() { cleanup_ai_temp_files '$script_name'; }"

    # Register trap handlers for all exit scenarios
    trap 'cleanup_on_exit' EXIT
    trap 'echo "🚨 [$script_name] Received SIGINT - cleaning up..." >&2; cleanup_on_exit; exit 130' INT
    trap 'echo "🚨 [$script_name] Received SIGTERM - cleaning up..." >&2; cleanup_on_exit; exit 143' TERM
}

# Set up security-focused trap handlers (extra secure cleanup)
setup_security_traps() {
    script_name="${1:-$(basename "$0")}"

    # Define enhanced cleanup for security scripts
    security_cleanup_on_exit() {
        echo "🔒 [$script_name] Performing security-focused cleanup..." >&2

        # Additional security patterns
        local security_patterns=(
            'security_*'
            'audit_*'
            'scan_*'
            'vuln_*'
            '*.sec'
            '*.audit'
        )

        for pattern in "${security_patterns[@]}"; do
            find . -maxdepth 1 -name "$pattern" -type f 2>/dev/null | while read -r file; do
                if [[ -f "$file" ]]; then
                    # Extra secure deletion for security files
                    if command -v shred >/dev/null 2>&1; then
                        shred -vfz -n 5 "$file" 2>/dev/null || rm -f "$file"
                    elif command -v gshred >/dev/null 2>&1; then
                        gshred -vfz -n 5 "$file" 2>/dev/null || rm -f "$file"
                    else
                        # Multiple secure overwrites
                        dd if=/dev/urandom of="$file" bs=1024 count=2 2>/dev/null || true
                        dd if=/dev/zero of="$file" bs=1024 count=1 2>/dev/null || true
                        rm -f "$file"
                    fi
                    echo "🗑️  Securely removed security file: $file" >&2
                fi
            done
        done

        # Call standard cleanup too
        cleanup_ai_temp_files "$script_name"
    }

    # Register enhanced trap handlers
    trap 'security_cleanup_on_exit' EXIT
    trap 'echo "🚨 [$script_name] Security script interrupted - performing secure cleanup..." >&2; security_cleanup_on_exit; exit 130' INT
    trap 'echo "🚨 [$script_name] Security script terminated - performing secure cleanup..." >&2; security_cleanup_on_exit; exit 143' TERM
}
