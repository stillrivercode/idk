#!/bin/bash

# Common Library
# Provides shared utilities and constants for all library modules

set -euo pipefail

# Prevent multiple sourcing
if [[ -n "${COMMON_LIB_SOURCED:-}" ]]; then
  return 0
fi
export COMMON_LIB_SOURCED=1

# Constants
readonly CLAUDE_TIMEOUT="${AI_EXECUTION_TIMEOUT_MINUTES:-20}"
readonly MAX_RETRIES=3
readonly COST_MULTIPLIER=1.2
readonly DEFAULT_MODEL="anthropic/claude-sonnet-4"
readonly OUTPUT_BUFFER_SIZE=10240

# Color codes for terminal output (if not in CI)
if [[ -t 1 ]] && [[ -z "${CI:-}" ]]; then
  readonly COLOR_RED='\033[0;31m'
  readonly COLOR_GREEN='\033[0;32m'
  readonly COLOR_YELLOW='\033[1;33m'
  readonly COLOR_BLUE='\033[0;34m'
  readonly COLOR_NC='\033[0m' # No Color
else
  readonly COLOR_RED=''
  readonly COLOR_GREEN=''
  readonly COLOR_YELLOW=''
  readonly COLOR_BLUE=''
  readonly COLOR_NC=''
fi

# Logging functions
log_info() {
  echo -e "${COLOR_BLUE}$*${COLOR_NC}" >&2
}

log_success() {
  echo -e "${COLOR_GREEN}✅ $*${COLOR_NC}" >&2
}

log_warning() {
  echo -e "${COLOR_YELLOW}⚠️ $*${COLOR_NC}" >&2
}

log_error() {
  echo -e "${COLOR_RED}❌ $*${COLOR_NC}" >&2
}

log_debug() {
  if [[ "${DEBUG:-false}" == "true" ]] || [[ "${AI_DEBUG_MODE:-false}" == "true" ]]; then
    echo -e "${COLOR_BLUE}🔍 $*${COLOR_NC}" >&2
  fi
}

# Utility functions
get_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

get_iso_timestamp() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

# Check if running in CI environment
is_ci_environment() {
  [[ -n "${CI:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]] || [[ -n "${JENKINS_HOME:-}" ]] || [[ -n "${CIRCLECI:-}" ]]
}

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Create temporary file with cleanup
create_temp_file() {
  local prefix="${1:-claude}"
  local temp_file
  temp_file=$(mktemp -t "${prefix}.XXXXXX")
  echo "$temp_file"
}

# Calculate file size in human-readable format
human_readable_size() {
  local bytes="$1"
  local units=("B" "KB" "MB" "GB")
  local unit=0

  while (( bytes > 1024 && unit < ${#units[@]} - 1 )); do
    bytes=$((bytes / 1024))
    ((unit++))
  done

  echo "${bytes}${units[$unit]}"
}

# Validate required environment variables
validate_required_env() {
  local required_vars=("$@")
  local missing_vars=()

  for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      missing_vars+=("$var")
    fi
  done

  if [[ ${#missing_vars[@]} -gt 0 ]]; then
    log_error "Missing required environment variables: ${missing_vars[*]}"
    return 1
  fi

  return 0
}

# Safe file operations
safe_rm() {
  local file="$1"
  if [[ -f "$file" ]]; then
    rm -f "$file"
    log_debug "Removed file: $file"
  fi
}

safe_mkdir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    log_debug "Created directory: $dir"
  fi
}

# Escape special characters for JSON
escape_json() {
  local text="$1"
  # Use printf to handle escaping properly
  printf '%s' "$text" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' -e 's/\n/\\n/g' -e 's/\r/\\r/g'
}

# Get git repository info
get_git_info() {
  local info=""

  if command_exists git && git rev-parse --git-dir >/dev/null 2>&1; then
    local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    info="branch: $branch, commit: $commit"
  else
    info="not a git repository"
  fi

  echo "$info"
}

# Validate prerequisites for all scripts
validate_prerequisites() {
  log_info "Validating prerequisites..."

  # Check for required commands
  local required_commands=("bash" "sed" "grep" "awk")
  local missing_commands=()

  for cmd in "${required_commands[@]}"; do
    if ! command_exists "$cmd"; then
      missing_commands+=("$cmd")
    fi
  done

  if [[ ${#missing_commands[@]} -gt 0 ]]; then
    log_error "Missing required commands: ${missing_commands[*]}"
    return 1
  fi

  # Check bash version (minimum 3.2)
  local bash_version="${BASH_VERSION%%.*}"
  if [[ $bash_version -lt 3 ]]; then
    log_error "Bash version 3.2 or higher required (found: $BASH_VERSION)"
    return 1
  fi

  log_success "All prerequisites satisfied"
  return 0
}

# Export common error codes
export readonly ERR_MISSING_DEPS=10
export readonly ERR_INVALID_ARGS=11
export readonly ERR_API_FAILURE=12
export readonly ERR_TIMEOUT=13
export readonly ERR_COST_LIMIT=14
export readonly ERR_PERMISSION=15
