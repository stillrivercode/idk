#!/bin/bash

# Memory Integration Library
# Provides persistent memory and context management for AI tasks
# Supports issue context caching, file content caching, and session persistence

set -euo pipefail

# Source common utilities if not already sourced
if [[ -z "${COMMON_LIB_SOURCED:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "${SCRIPT_DIR}/common.sh"
  export COMMON_LIB_SOURCED=1
fi

# Memory configuration
readonly MEMORY_BASE_DIR="/tmp/ai_task_memory"
readonly MEMORY_ISSUES_DIR="$MEMORY_BASE_DIR/issues"
readonly MEMORY_FILES_DIR="$MEMORY_BASE_DIR/files"
readonly MEMORY_CONTEXT_DIR="$MEMORY_BASE_DIR/context"
readonly MEMORY_SESSIONS_DIR="$MEMORY_BASE_DIR/sessions"
readonly MAX_MEMORY_AGE_DAYS=7
readonly MAX_MEMORY_SIZE_MB=100

# Initialize memory system
init_memory_system() {
    log_debug "🧠 Initializing memory system"

    # Create memory directory structure
    mkdir -p "$MEMORY_ISSUES_DIR"
    mkdir -p "$MEMORY_FILES_DIR"
    mkdir -p "$MEMORY_CONTEXT_DIR"
    mkdir -p "$MEMORY_SESSIONS_DIR"

    # Clean old memory files
    cleanup_old_memory

    # Initialize session
    local session_id="session_$(date +%s)_$$"
    local session_file="$MEMORY_SESSIONS_DIR/$session_id.json"

    cat > "$session_file" <<EOF
{
    "session_id": "$session_id",
    "started_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "pid": $$,
    "status": "active",
    "issues_processed": [],
    "files_cached": [],
    "context_generated": 0
}
EOF

    export AI_MEMORY_SESSION_ID="$session_id"
    log_debug "Memory system initialized with session: $session_id"
}

# Clean up old memory files
cleanup_old_memory() {
    log_debug "🧹 Cleaning up old memory files"

    # Remove files older than MAX_MEMORY_AGE_DAYS
    find "$MEMORY_BASE_DIR" -type f -mtime +$MAX_MEMORY_AGE_DAYS -delete 2>/dev/null || true

    # Check total memory usage
    local memory_usage
    memory_usage=$(du -sm "$MEMORY_BASE_DIR" 2>/dev/null | cut -f1 || echo "0")

    if [[ $memory_usage -gt $MAX_MEMORY_SIZE_MB ]]; then
        log_warning "⚠️ Memory usage ($memory_usage MB) exceeds limit ($MAX_MEMORY_SIZE_MB MB)"

        # Remove oldest files first
        find "$MEMORY_BASE_DIR" -type f -exec ls -lt {} + | tail -n +$((MAX_MEMORY_SIZE_MB / 2)) | \
            awk '{print $NF}' | xargs rm -f 2>/dev/null || true
    fi
}

# Save issue context to memory
save_issue_context() {
    local issue_number="$1"
    local title="$2"
    local body="$3"
    local labels="$4"

    local memory_file="$MEMORY_ISSUES_DIR/issue_${issue_number}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create comprehensive issue context
    cat > "$memory_file" <<EOF
{
    "issue_number": $issue_number,
    "title": $(echo "$title" | jq -R .),
    "body": $(echo "$body" | jq -R .),
    "labels": $(echo "$labels" | jq -R . | jq 'split(",")'),
    "timestamp": "$timestamp",
    "status": "processing",
    "files_referenced": [],
    "context_size": 0,
    "processing_attempts": 1,
    "session_id": "${AI_MEMORY_SESSION_ID:-unknown}"
}
EOF

    # Update session with processed issue
    if [[ -n "${AI_MEMORY_SESSION_ID:-}" ]]; then
        update_session_issues "$issue_number"
    fi

    log_debug "💾 Saved issue context: issue #$issue_number"
}

# Load issue context from memory
load_issue_context() {
    local issue_number="$1"
    local memory_file="$MEMORY_ISSUES_DIR/issue_${issue_number}.json"

    if [[ ! -f "$memory_file" ]]; then
        return 1
    fi

    log_debug "🔍 Loading issue context: issue #$issue_number"
    cat "$memory_file"
}

# Update issue status in memory
update_issue_status() {
    local issue_number="$1"
    local status="$2"
    local additional_data="${3:-{}}"

    local memory_file="$MEMORY_ISSUES_DIR/issue_${issue_number}.json"

    if [[ ! -f "$memory_file" ]]; then
        log_warning "⚠️ Issue memory file not found: $memory_file"
        return 1
    fi

    local temp_file=$(mktemp)
    jq --arg status "$status" \
       --argjson data "$additional_data" \
       '.status = $status | .updated_at = now | . += $data' \
       "$memory_file" > "$temp_file" && mv "$temp_file" "$memory_file"

    log_debug "📝 Updated issue #$issue_number status to: $status"
}

# Cache file content with smart processing
cache_file_content() {
    local file_path="$1"
    local content="$2"
    local context_type="${3:-smart}"

    # Create safe filename for cache
    local cache_filename
    cache_filename=$(echo "$file_path" | tr '/' '_' | tr ' ' '_')
    local cache_file="$MEMORY_FILES_DIR/${cache_filename}.json"

    local file_mtime
    file_mtime=$(stat -c%Y "$file_path" 2>/dev/null || stat -f%m "$file_path" 2>/dev/null || echo "0")

    # Create cache entry
    cat > "$cache_file" <<EOF
{
    "file_path": $(echo "$file_path" | jq -R .),
    "content": $(echo "$content" | jq -R .),
    "context_type": "$context_type",
    "file_mtime": $file_mtime,
    "cached_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "content_size": ${#content},
    "session_id": "${AI_MEMORY_SESSION_ID:-unknown}"
}
EOF

    # Update session with cached file
    if [[ -n "${AI_MEMORY_SESSION_ID:-}" ]]; then
        update_session_files "$file_path"
    fi

    log_debug "💽 Cached file content: $file_path (${#content} chars)"
}

# Load cached file content
load_cached_file_content() {
    local file_path="$1"

    local cache_filename
    cache_filename=$(echo "$file_path" | tr '/' '_' | tr ' ' '_')
    local cache_file="$MEMORY_FILES_DIR/${cache_filename}.json"

    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi

    # Check if cache is still valid
    local file_mtime
    file_mtime=$(stat -c%Y "$file_path" 2>/dev/null || stat -f%m "$file_path" 2>/dev/null || echo "0")

    local cached_mtime
    cached_mtime=$(jq -r '.file_mtime' "$cache_file" 2>/dev/null || echo "0")

    if [[ $file_mtime -gt $cached_mtime ]]; then
        log_debug "🔄 Cache expired for: $file_path"
        return 1
    fi

    log_debug "📖 Loading cached content: $file_path"
    jq -r '.content' "$cache_file"
}

# Save context generation result
save_context_result() {
    local context_id="$1"
    local context_data="$2"
    local metadata="${3:-{}}"

    local context_file="$MEMORY_CONTEXT_DIR/${context_id}.json"

    cat > "$context_file" <<EOF
{
    "context_id": "$context_id",
    "context_data": $(echo "$context_data" | jq -R .),
    "metadata": $metadata,
    "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "size": ${#context_data},
    "session_id": "${AI_MEMORY_SESSION_ID:-unknown}"
}
EOF

    log_debug "🎯 Saved context result: $context_id (${#context_data} chars)"
}

# Update session with processed issue
update_session_issues() {
    local issue_number="$1"

    if [[ -z "${AI_MEMORY_SESSION_ID:-}" ]]; then
        return 0
    fi

    local session_file="$MEMORY_SESSIONS_DIR/$AI_MEMORY_SESSION_ID.json"

    if [[ ! -f "$session_file" ]]; then
        return 1
    fi

    local temp_file=$(mktemp)
    jq --argjson issue "$issue_number" \
       '.issues_processed += [$issue] | .issues_processed = (.issues_processed | unique)' \
       "$session_file" > "$temp_file" && mv "$temp_file" "$session_file"
}

# Update session with cached file
update_session_files() {
    local file_path="$1"

    if [[ -z "${AI_MEMORY_SESSION_ID:-}" ]]; then
        return 0
    fi

    local session_file="$MEMORY_SESSIONS_DIR/$AI_MEMORY_SESSION_ID.json"

    if [[ ! -f "$session_file" ]]; then
        return 1
    fi

    local temp_file=$(mktemp)
    jq --arg file "$file_path" \
       '.files_cached += [$file] | .files_cached = (.files_cached | unique)' \
       "$session_file" > "$temp_file" && mv "$temp_file" "$session_file"
}

# Get memory statistics
get_memory_stats() {
    local stats_json=""

    # Count files in each directory
    local issues_count
    issues_count=$(find "$MEMORY_ISSUES_DIR" -name "*.json" 2>/dev/null | wc -l || echo "0")

    local files_count
    files_count=$(find "$MEMORY_FILES_DIR" -name "*.json" 2>/dev/null | wc -l || echo "0")

    local context_count
    context_count=$(find "$MEMORY_CONTEXT_DIR" -name "*.json" 2>/dev/null | wc -l || echo "0")

    local sessions_count
    sessions_count=$(find "$MEMORY_SESSIONS_DIR" -name "*.json" 2>/dev/null | wc -l || echo "0")

    # Calculate total size
    local total_size
    total_size=$(du -sm "$MEMORY_BASE_DIR" 2>/dev/null | cut -f1 || echo "0")

    cat <<EOF
{
    "issues_cached": $issues_count,
    "files_cached": $files_count,
    "contexts_saved": $context_count,
    "active_sessions": $sessions_count,
    "total_size_mb": $total_size,
    "base_directory": "$MEMORY_BASE_DIR"
}
EOF
}

# Close current session
close_memory_session() {
    if [[ -z "${AI_MEMORY_SESSION_ID:-}" ]]; then
        return 0
    fi

    local session_file="$MEMORY_SESSIONS_DIR/$AI_MEMORY_SESSION_ID.json"

    if [[ -f "$session_file" ]]; then
        local temp_file=$(mktemp)
        jq '.status = "completed" | .completed_at = now' \
           "$session_file" > "$temp_file" && mv "$temp_file" "$session_file"

        log_debug "📋 Closed memory session: $AI_MEMORY_SESSION_ID"
    fi

    unset AI_MEMORY_SESSION_ID
}

# Export functions for use in other scripts
export -f init_memory_system
export -f cleanup_old_memory
export -f save_issue_context
export -f load_issue_context
export -f update_issue_status
export -f cache_file_content
export -f load_cached_file_content
export -f save_context_result
export -f get_memory_stats
export -f close_memory_session
