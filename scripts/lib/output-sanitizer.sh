#!/bin/bash

# Output Sanitization Library
# Provides functions to sanitize sensitive data from Claude CLI output

set -euo pipefail

# Sanitize sensitive data from logs using improved patterns
sanitize_output() {
  local input_file="$1"
  local output_file="$2"

  if [[ ! -f "$input_file" ]]; then
    echo "Error: Input file not found: $input_file" >&2
    return 1
  fi

  if ! sed -E '
    # More specific API key patterns
    s/sk-[a-zA-Z0-9]{48}/sk-***REDACTED***/g;
    s/ghp_[a-zA-Z0-9]{36}/ghp_***REDACTED***/g;
    s/gho_[a-zA-Z0-9]{36}/gho_***REDACTED***/g;
    s/ghu_[a-zA-Z0-9]{36}/ghu_***REDACTED***/g;
    s/ghs_[a-zA-Z0-9]{36}/ghs_***REDACTED***/g;
    s/ghr_[a-zA-Z0-9]{52}/ghr_***REDACTED***/g;
    s/([A-Z_]+API_KEY)[[:space:]]*=[[:space:]]*[^[:space:]]+/\1=***REDACTED***/g;
    s/(OPENROUTER_API_KEY)[[:space:]]*=[[:space:]]*[^[:space:]]+/\1=***REDACTED***/g;
    s/(GITHUB_TOKEN)[[:space:]]*=[[:space:]]*[^[:space:]]+/\1=***REDACTED***/g;
    s/(GH_PAT)[[:space:]]*=[[:space:]]*[^[:space:]]+/\1=***REDACTED***/g;
    s/([A-Z_]*TOKEN)[[:space:]]*=[[:space:]]*[^[:space:]]+/\1=***REDACTED***/g;
    s/([A-Z_]*SECRET)[[:space:]]*=[[:space:]]*[^[:space:]]+/\1=***REDACTED***/g;
    s/([A-Z_]*PASSWORD)[[:space:]]*=[[:space:]]+[^[:space:]]+/\1=***REDACTED***/g;
    s/(token|password|secret|key)[[:space:]]*[:=][[:space:]]*[^[:space:]]+/\1=***REDACTED***/gi;
    s/(Bearer[[:space:]]+)[A-Za-z0-9._-]+/\1***REDACTED***/g;
    s/(Authorization:[[:space:]]*Bearer[[:space:]]+)[A-Za-z0-9._-]+/\1***REDACTED***/g;
    s/eyJ[A-Za-z0-9+\/]+=*\.[A-Za-z0-9+\/]+=*\.[A-Za-z0-9+\/_-]+=*/***JWT_TOKEN_REDACTED***/g;
    s/\b(docker[[:space:]]*login[[:space:]]*.*-p[[:space:]]*)[^[:space:]]+/\1***REDACTED***/g;
    # Base64 encoded potential secrets (only very long ones to avoid false positives)
    s/[A-Za-z0-9+\/]{64,}={0,2}\??/***BASE64_REDACTED***/g;
  ' "$input_file" > "$output_file"; then
    echo "Error: Failed to process file $input_file" >&2
    return 1
  else
    echo "🔒 Output sanitized: $input_file → $output_file"
  fi
}

# Function to sanitize input from stdin and output to stdout
sanitize_stdin() {
  sed -E '
    # More specific API key patterns (match sanitize_output)
    s/sk-[a-zA-Z0-9]{48}/sk-***REDACTED***/g;
    s/ghp_[a-zA-Z0-9]{36}/ghp_***REDACTED***/g;
    s/gho_[a-zA-Z0-9]{36}/gho_***REDACTED***/g;
    s/ghu_[a-zA-Z0-9]{36}/ghu_***REDACTED***/g;
    s/ghs_[a-zA-Z0-9]{36}/ghs_***REDACTED***/g;
    s/ghr_[a-zA-Z0-9]{52}/ghr_***REDACTED***/g;
    s/([A-Z_]+API_KEY)[[:space:]]*=[[:space:]]*[^[:space:]]+/\1=***REDACTED***/g;
    s/(OPENROUTER_API_KEY)[[:space:]]*=[[:space:]]*[^[:space:]]+/\1=***REDACTED***/g;
    s/(GITHUB_TOKEN)[[:space:]]*=[[:space:]]*[^[:space:]]+/\1=***REDACTED***/g;
    s/(GH_PAT)[[:space:]]*=[[:space:]]*[^[:space:]]+/\1=***REDACTED***/g;
    s/([A-Z_]*TOKEN)[[:space:]]*=[[:space:]]*[^[:space:]]+/\1=***REDACTED***/g;
    s/([A-Z_]*SECRET)[[:space:]]*=[[:space:]]*[^[:space:]]+/\1=***REDACTED***/g;
    s/([A-Z_]*PASSWORD)[[:space:]]*=[[:space:]]+[^[:space:]]+/\1=***REDACTED***/g;
    s/(token|password|secret|key)[[:space:]]*[:=][[:space:]]*[^[:space:]]+/\1=***REDACTED***/gi;
    s/(Bearer[[:space:]]+)[A-Za-z0-9._-]+/\1***REDACTED***/g;
    s/(Authorization:[[:space:]]*Bearer[[:space:]]+)[A-Za-z0-9._-]+/\1***REDACTED***/g;
    s/eyJ[A-Za-z0-9+\/]+=*\.[A-Za-z0-9+\/]+=*\.[A-Za-z0-9+\/_-]+=*/***JWT_TOKEN_REDACTED***/g;
    s/\b(docker[[:space:]]*login[[:space:]]*.*-p[[:space:]]*)[^[:space:]]+/\1***REDACTED***/g;
    # Base64 encoded potential secrets (only very long ones to avoid false positives)
    s/[A-Za-z0-9+\/]{64,}={0,2}\??/***BASE64_REDACTED***/g;
  '
}

# Validate that sanitization patterns are working correctly
validate_sanitization() {
  local test_input="$1"
  local expected_redactions="$2"

  echo "🧪 Testing sanitization patterns..."

  # Create temporary test file
  local temp_file=$(mktemp)
  echo "$test_input" > "$temp_file"

  local sanitized_file=$(mktemp)
  sanitize_output "$temp_file" "$sanitized_file"

  local sanitized_content=$(cat "$sanitized_file")

  # Check if expected patterns were redacted
  local validation_passed=true
  IFS=',' read -ra patterns <<< "$expected_redactions"
  for pattern in "${patterns[@]}"; do
    if echo "$sanitized_content" | grep -q "$pattern"; then
      echo "❌ Pattern '$pattern' was not properly redacted"
      validation_passed=false
    else
      echo "✅ Pattern '$pattern' was successfully redacted"
    fi
  done

  # Cleanup
  rm -f "$temp_file" "$sanitized_file"

  if [[ "$validation_passed" == "true" ]]; then
    echo "✅ All sanitization patterns working correctly"
    return 0
  else
    echo "❌ Some sanitization patterns failed"
    return 1
  fi
}

# Clean up sensitive files securely
secure_cleanup() {
  local files_to_clean=("$@")

  echo "🧹 Performing secure cleanup..."

  for file in "${files_to_clean[@]}"; do
    if [[ -f "$file" ]]; then
      # Overwrite file content before deletion (basic security measure)
      if command -v shred >/dev/null 2>&1; then
        shred -vfz -n 3 "$file" 2>/dev/null || rm -f "$file"
      else
        # Fallback for systems without shred
        dd if=/dev/zero of="$file" bs=1024 count=1 2>/dev/null || true
        rm -f "$file"
      fi
      echo "🗑️  Securely removed: $file"
    fi
  done

  echo "✅ Security cleanup completed"
}
