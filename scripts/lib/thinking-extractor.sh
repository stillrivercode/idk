#!/bin/bash

# Thinking Extractor Library
# Provides functions to extract and format AI thinking process from Claude output

set -euo pipefail

# Source common utilities if not already sourced
if [[ -z "${COMMON_LIB_SOURCED:-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "${SCRIPT_DIR}/common.sh"
  export COMMON_LIB_SOURCED=1
fi

# Extract thinking blocks from Claude output
extract_thinking_blocks() {
  local input_file="$1"
  local output_file="${2:-}"

  if [[ ! -f "$input_file" ]]; then
    log_error "Input file not found: $input_file"
    return 1
  fi

  log_debug "Extracting thinking blocks from: $input_file"

  # Pattern to match <anythingllm:thinking> blocks
  local thinking_content=""
  local in_thinking_block=false
  local block_count=0

  while IFS= read -r line; do
    if [[ "$line" =~ \<anythingllm:thinking\> ]]; then
      in_thinking_block=true
      ((block_count++))
      thinking_content+="### Thinking Block $block_count\n\n"
      continue
    elif [[ "$line" =~ \</anythingllm:thinking\> ]]; then
      in_thinking_block=false
      thinking_content+="\n---\n\n"
      continue
    fi

    if [[ "$in_thinking_block" == true ]]; then
      thinking_content+="$line\n"
    fi
  done < "$input_file"

  if [[ -n "$output_file" ]]; then
    echo -e "$thinking_content" > "$output_file"
    log_success "Extracted $block_count thinking blocks to: $output_file"
  else
    echo -e "$thinking_content"
  fi

  return 0
}

# Format thinking output for readability
format_thinking_output() {
  local input_file="$1"
  local output_file="${2:-}"

  if [[ ! -f "$input_file" ]]; then
    log_error "Input file not found: $input_file"
    return 1
  fi

  local formatted_content=""
  formatted_content+="# AI Thinking Process\n\n"
  formatted_content+="Generated: $(get_timestamp)\n\n"
  formatted_content+="## Summary\n\n"

  # Extract key phases from thinking
  local phases=(
    "Analysis Phase"
    "Planning Phase"
    "Implementation Phase"
    "Validation Phase"
  )

  for phase in "${phases[@]}"; do
    local phase_content=$(grep -A 10 "$phase" "$input_file" 2>/dev/null || true)
    if [[ -n "$phase_content" ]]; then
      formatted_content+="### $phase\n\n"
      formatted_content+="$phase_content\n\n"
    fi
  done

  # Add full thinking content
  formatted_content+="\n## Full Thinking Process\n\n"
  formatted_content+="$(cat "$input_file")\n"

  if [[ -n "$output_file" ]]; then
    echo -e "$formatted_content" > "$output_file"
    log_success "Formatted thinking output saved to: $output_file"
  else
    echo -e "$formatted_content"
  fi

  return 0
}

# Save thinking process to file with metadata
save_thinking_file() {
  local thinking_content="$1"
  local output_dir="$2"
  local session_id="${3:-thinking_$(date +%s)}"

  safe_mkdir "$output_dir"

  local thinking_file="$output_dir/${session_id}_thinking.md"
  local metadata_file="$output_dir/${session_id}_thinking_metadata.json"

  # Save thinking content
  echo -e "$thinking_content" > "$thinking_file"

  # Save metadata
  cat > "$metadata_file" << EOF
{
  "session_id": "$session_id",
  "timestamp": "$(get_iso_timestamp)",
  "git_info": "$(get_git_info)",
  "thinking_blocks": $(echo -e "$thinking_content" | grep -c "### Thinking Block" || echo 0),
  "file_size": $(stat -f%z "$thinking_file" 2>/dev/null || stat -c%s "$thinking_file" 2>/dev/null || echo 0)
}
EOF

  log_success "Thinking process saved:"
  log_info "  Content: $thinking_file"
  log_info "  Metadata: $metadata_file"

  echo "$thinking_file"
}

# Detect thinking patterns and insights
detect_thinking_patterns() {
  local thinking_file="$1"

  if [[ ! -f "$thinking_file" ]]; then
    log_error "Thinking file not found: $thinking_file"
    return 1
  fi

  log_info "Analyzing thinking patterns..."

  local patterns=()

  # Check for common thinking patterns
  if grep -q "break.*down\|decompos" "$thinking_file" 2>/dev/null; then
    patterns+=("Problem Decomposition")
  fi

  if grep -q "consider\|alternative\|option" "$thinking_file" 2>/dev/null; then
    patterns+=("Alternative Evaluation")
  fi

  if grep -q "test\|verify\|validate" "$thinking_file" 2>/dev/null; then
    patterns+=("Validation Focus")
  fi

  if grep -q "error\|fix\|bug\|issue" "$thinking_file" 2>/dev/null; then
    patterns+=("Error Analysis")
  fi

  if grep -q "optimi[zs]e\|improve\|enhance" "$thinking_file" 2>/dev/null; then
    patterns+=("Optimization Focus")
  fi

  if grep -q "security\|vulnerab\|safe" "$thinking_file" 2>/dev/null; then
    patterns+=("Security Awareness")
  fi

  if [[ ${#patterns[@]} -gt 0 ]]; then
    log_info "Detected thinking patterns:"
    for pattern in "${patterns[@]}"; do
      echo "  - $pattern"
    done
  else
    log_info "No specific patterns detected"
  fi

  return 0
}

# Generate thinking summary for quick review
generate_thinking_summary() {
  local thinking_file="$1"
  local max_lines="${2:-20}"

  if [[ ! -f "$thinking_file" ]]; then
    log_error "Thinking file not found: $thinking_file"
    return 1
  fi

  log_info "Generating thinking summary..."

  # Extract key insights (lines with certain keywords)
  local keywords="decided\|conclusion\|approach\|plan\|implement\|issue\|problem\|solution"
  local summary=""

  summary+="## Quick Thinking Summary\n\n"
  summary+="### Key Decisions\n"

  # Get lines with decision keywords
  local decisions=$(grep -i "$keywords" "$thinking_file" 2>/dev/null | head -n "$max_lines" || true)
  if [[ -n "$decisions" ]]; then
    while IFS= read -r line; do
      summary+="- $line\n"
    done <<< "$decisions"
  else
    summary+="- No explicit decisions found\n"
  fi

  summary+="\n### Thinking Statistics\n"
  summary+="- Total lines: $(wc -l < "$thinking_file")\n"
  summary+="- Thinking blocks: $(grep -c "### Thinking Block" "$thinking_file" 2>/dev/null || echo 0)\n"
  summary+="- Questions raised: $(grep -c "?" "$thinking_file" 2>/dev/null || echo 0)\n"

  echo -e "$summary"
}

# Clean thinking blocks from main output
remove_thinking_from_output() {
  local input_file="$1"
  local output_file="$2"

  if [[ ! -f "$input_file" ]]; then
    log_error "Input file not found: $input_file"
    return 1
  fi

  log_debug "Removing thinking blocks from output..."

  # Remove everything between thinking tags
  sed '/<anythingllm:thinking>/,/<\/anythingllm:thinking>/d' "$input_file" > "$output_file"

  log_success "Cleaned output saved to: $output_file"
  return 0
}
