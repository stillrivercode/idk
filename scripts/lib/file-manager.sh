#!/bin/bash

# File Manager Library
# Provides functions for managing files and artifacts generated during AI execution

set -euo pipefail

# Source common utilities if not already sourced
if [[ -z "${COMMON_LIB_SOURCED:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "${SCRIPT_DIR}/common.sh"
  export COMMON_LIB_SOURCED=1
fi

# Default output directory
readonly DEFAULT_OUTPUT_DIR="/tmp/claude_execution"

# Setup output directory structure
setup_output_directory() {
  local base_dir="${1:-$DEFAULT_OUTPUT_DIR}"
  local session_id="${2:-claude_$(date +%s)_$$}"

  local session_dir="$base_dir/$session_id"

  # Create directory structure
  safe_mkdir "$session_dir"
  safe_mkdir "$session_dir/artifacts"
  safe_mkdir "$session_dir/logs"
  safe_mkdir "$session_dir/backups"

  log_success "Output directory structure created: $session_dir"

  # Return the session directory path
  echo "$session_dir"
}

# Save full conversation with metadata
save_conversation() {
  local conversation_content="$1"
  local output_dir="$2"
  local session_id="${3:-conversation_$(date +%s)}"

  safe_mkdir "$output_dir"

  local conversation_file="$output_dir/${session_id}_conversation.md"
  local metadata_file="$output_dir/${session_id}_metadata.json"

  # Save conversation content
  echo -e "$conversation_content" > "$conversation_file"

  # Generate metadata
  cat > "$metadata_file" << EOF
{
  "session_id": "$session_id",
  "timestamp": "$(get_iso_timestamp)",
  "timestamp_human": "$(get_timestamp)",
  "git_info": "$(get_git_info)",
  "working_directory": "$(pwd)",
  "user": "${USER:-unknown}",
  "hostname": "${HOSTNAME:-$(hostname 2>/dev/null || echo unknown)}",
  "conversation_size": $(stat -f%z "$conversation_file" 2>/dev/null || stat -c%s "$conversation_file" 2>/dev/null || echo 0),
  "environment": {
    "shell": "${SHELL:-unknown}",
    "term": "${TERM:-unknown}",
    "ci": $(is_ci_environment && echo true || echo false)
  }
}
EOF

  log_success "Conversation saved:"
  log_info "  Content: $conversation_file"
  log_info "  Metadata: $metadata_file"

  echo "$conversation_file"
}

# Track modified files during execution
save_modified_files() {
  local output_dir="$1"
  local before_snapshot="${2:-}"
  local session_id="${3:-$(date +%s)}"

  safe_mkdir "$output_dir/artifacts"

  local modified_files_log="$output_dir/artifacts/${session_id}_modified_files.txt"
  local file_backups_dir="$output_dir/backups"

  safe_mkdir "$file_backups_dir"

  # If we have a before snapshot, compare with current state
  if [[ -n "$before_snapshot" && -f "$before_snapshot" ]]; then
    log_info "Detecting modified files..."

    # Create current snapshot
    local after_snapshot=$(create_temp_file "after_snapshot")
    find . -type f -newer "$before_snapshot" 2>/dev/null | grep -v ".git/" > "$after_snapshot" || true

    # Find modified files
    comm -13 <(sort "$before_snapshot") <(sort "$after_snapshot") > "$modified_files_log" || true

    # Backup modified files
    if [[ -s "$modified_files_log" ]]; then
      local count=0
      while IFS= read -r file; do
        if [[ -f "$file" ]]; then
          local backup_path="$file_backups_dir/$(basename "$file").${session_id}.backup"
          cp "$file" "$backup_path" 2>/dev/null || true
          ((count++))
        fi
      done < "$modified_files_log"

      log_success "Backed up $count modified files"
    fi

    rm -f "$after_snapshot"
  else
    # Just list current directory state
    find . -type f -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.md" 2>/dev/null | \
      grep -v ".git/" | sort > "$modified_files_log" || true
  fi

  log_info "Modified files list saved to: $modified_files_log"
  echo "$modified_files_log"
}

# Generate execution summary
generate_summary() {
  local output_dir="$1"
  local session_id="$2"
  local exit_code="${3:-0}"
  local estimated_cost="${4:-0.0000}"

  local summary_file="$output_dir/${session_id}_summary.md"

  cat > "$summary_file" << EOF
# AI Execution Summary

## Session Information
- **Session ID**: $session_id
- **Date**: $(get_timestamp)
- **Exit Code**: $exit_code
- **Status**: $([ $exit_code -eq 0 ] && echo "✅ Success" || echo "❌ Failed")
- **Estimated Cost**: \$$estimated_cost

## Environment
- **Working Directory**: $(pwd)
- **Git Info**: $(get_git_info)
- **User**: ${USER:-unknown}
- **CI Environment**: $(is_ci_environment && echo "Yes" || echo "No")

## Generated Files
EOF

  # List all files in the output directory
  if [[ -d "$output_dir" ]]; then
    echo -e "\n### Output Directory Contents\n" >> "$summary_file"
    find "$output_dir" -type f -name "${session_id}*" 2>/dev/null | while read -r file; do
      local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
      echo "- $(basename "$file") ($(human_readable_size $size))" >> "$summary_file"
    done
  fi

  # Add execution metrics if available
  local metrics_file="$output_dir/${session_id}_metrics.json"
  if [[ -f "$metrics_file" ]]; then
    echo -e "\n## Execution Metrics\n" >> "$summary_file"
    echo '```json' >> "$summary_file"
    cat "$metrics_file" >> "$summary_file"
    echo '```' >> "$summary_file"
  fi

  log_success "Summary generated: $summary_file"
  echo "$summary_file"
}

# Cleanup temporary files with security considerations
cleanup_temp_files() {
  local output_dir="$1"
  local session_id="$2"
  local keep_logs="${3:-false}"

  log_info "Cleaning up temporary files..."

  # Files to always clean up (sensitive data)
  local sensitive_patterns=(
    "*_prompt_copy"
    "*_raw_output.log"
    "*.tmp"
    "*_api_key*"
    "*_token*"
  )

  # Clean sensitive files
  for pattern in "${sensitive_patterns[@]}"; do
    find "$output_dir" -name "$pattern" -type f -exec shred -u {} \; 2>/dev/null || \
    find "$output_dir" -name "$pattern" -type f -exec rm -f {} \; 2>/dev/null || true
  done

  # Optionally keep logs
  if [[ "$keep_logs" != "true" ]]; then
    find "$output_dir" -name "${session_id}*.log" -type f -exec rm -f {} \; 2>/dev/null || true
  fi

  # Remove empty directories
  find "$output_dir" -type d -empty -delete 2>/dev/null || true

  log_success "Cleanup completed"
}

# Archive session artifacts
archive_session() {
  local output_dir="$1"
  local session_id="$2"
  local archive_dir="${3:-$HOME/.claude_archives}"

  safe_mkdir "$archive_dir"

  local archive_name="${session_id}_$(date +%Y%m%d_%H%M%S).tar.gz"
  local archive_path="$archive_dir/$archive_name"

  log_info "Archiving session artifacts..."

  # Create archive
  tar -czf "$archive_path" -C "$output_dir" . 2>/dev/null || {
    log_error "Failed to create archive"
    return 1
  }

  log_success "Session archived: $archive_path"
  log_info "Archive size: $(human_readable_size $(stat -f%z "$archive_path" 2>/dev/null || stat -c%s "$archive_path" 2>/dev/null || echo 0))"

  echo "$archive_path"
}

# Get artifact by type
get_session_artifact() {
  local output_dir="$1"
  local session_id="$2"
  local artifact_type="$3"

  local artifact_path=""

  case "$artifact_type" in
    "conversation")
      artifact_path="$output_dir/${session_id}_conversation.md"
      ;;
    "thinking")
      artifact_path="$output_dir/${session_id}_thinking.md"
      ;;
    "summary")
      artifact_path="$output_dir/${session_id}_summary.md"
      ;;
    "output")
      artifact_path="$output_dir/${session_id}_sanitized_output.log"
      ;;
    "error")
      artifact_path="$output_dir/${session_id}_error_report.md"
      ;;
    "metrics")
      artifact_path="$output_dir/${session_id}_metrics.json"
      ;;
    *)
      log_error "Unknown artifact type: $artifact_type"
      return 1
      ;;
  esac

  if [[ -f "$artifact_path" ]]; then
    echo "$artifact_path"
  else
    log_warning "Artifact not found: $artifact_type"
    return 1
  fi
}

# List all session artifacts
list_session_artifacts() {
  local output_dir="$1"
  local session_id="${2:-*}"

  log_info "Session artifacts in $output_dir:"

  find "$output_dir" -name "${session_id}*" -type f 2>/dev/null | while read -r file; do
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
    local modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1,2)
    printf "  %-50s %10s  %s\n" "$(basename "$file")" "$(human_readable_size $size)" "$modified"
  done
}

# Create file snapshot for tracking changes
create_file_snapshot() {
  local output_file="${1:-file_snapshot.txt}"

  find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" -o -name "*.md" \) \
    -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./__pycache__/*" \
    -exec stat -f "%m %N" {} \; 2>/dev/null || \
    find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" -o -name "*.md" \) \
    -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./__pycache__/*" \
    -exec stat -c "%Y %n" {} \; 2>/dev/null > "$output_file"

  echo "$output_file"
}
