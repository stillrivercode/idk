#!/bin/bash

# Common utility functions for shared commands
# Source this file in other scripts: source ./shared-commands/lib/common-utils.sh

# Prevent multiple sourcing
if [[ -n "${COMMON_UTILS_SOURCED:-}" ]]; then
  return 0
fi
export COMMON_UTILS_SOURCED=1

# Template cache for performance (compatible with bash 3.2+)
# We use a simple file-based cache since associative arrays require bash 4.0+
_TEMPLATE_CACHE_DIR="${TMPDIR:-/tmp}/.template_cache_$$"

# Initialize cache directory
_init_template_cache() {
    if [[ "${TEMPLATE_CACHE_ENABLED:-true}" == "true" ]] && [[ ! -d "$_TEMPLATE_CACHE_DIR" ]]; then
        mkdir -p "$_TEMPLATE_CACHE_DIR" 2>/dev/null || true
        # Set secure permissions on cache directory (owner only)
        chmod 700 "$_TEMPLATE_CACHE_DIR" 2>/dev/null || true
    fi
}

# Clear template cache
clear_template_cache() {
    if [[ -d "$_TEMPLATE_CACHE_DIR" ]]; then
        rm -rf "$_TEMPLATE_CACHE_DIR" 2>/dev/null || true
    fi
}

# Note: Cache cleanup should be called manually when needed
# to avoid interfering with script execution

# Get file modification time for caching
_get_file_mtime() {
    local file_path="$1"
    local mtime=""

    if command -v stat >/dev/null 2>&1; then
        # Try BSD stat first (macOS), then GNU stat (Linux)
        if mtime=$(stat -f%m "$file_path" 2>/dev/null); then
            :  # BSD stat succeeded
        elif mtime=$(stat -c%Y "$file_path" 2>/dev/null); then
            :  # GNU stat succeeded
        fi
    fi

    echo "$mtime"
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

# Check if required command exists
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command '$cmd' not found. Please install it."
        return 1
    fi
    return 0
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        return 1
    fi
    return 0
}

# Validate issue number
validate_issue_number() {
    local issue_number="$1"
    if [[ ! "$issue_number" =~ ^[0-9]+$ ]]; then
        log_error "Invalid issue number: $issue_number"
        return 1
    fi
    return 0
}

# Create directory if it doesn't exist
ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_info "Created directory: $dir"
    fi
}

# Sanitize filename
sanitize_filename() {
    local filename="$1"
    # Remove/replace invalid characters
    echo "$filename" | sed -e 's/[^a-zA-Z0-9._-]/-/g' -e 's/-\+/-/g' -e 's/^-\|-$//g' | tr '[:upper:]' '[:lower:]'
}

# Get current date in YYYY-MM-DD format
get_current_date() {
    date "+%Y-%m-%d"
}

# Parse command line arguments for unified commands
parse_unified_args() {
    # Parse arguments for create commands
    while [[ $# -gt 0 ]]; do
        case $1 in
            --title)
                PARSED_TITLE="$2"
                shift 2
                ;;
            --body)
                PARSED_BODY="$2"
                shift 2
                ;;
            --labels)
                PARSED_LABELS="$2"
                shift 2
                ;;
            --assignee)
                PARSED_ASSIGNEE="$2"
                shift 2
                ;;
            --user-story-issue)
                PARSED_USER_STORY_ISSUE="$2"
                shift 2
                ;;
            --parent-issue)
                PARSED_PARENT_ISSUE="$2"
                shift 2
                ;;
            --issue)
                PARSED_ISSUE="$2"
                shift 2
                ;;
            --ai-task)
                PARSED_AI_TASK="true"
                shift
                ;;
            --dry-run)
                PARSED_DRY_RUN="true"
                shift
                ;;
            --help|-h)
                PARSED_HELP="true"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done
}

# Parse command line arguments for analysis commands
parse_analysis_args() {
    # Parse arguments for analyze commands
    while [[ $# -gt 0 ]]; do
        case $1 in
            --issue)
                PARSED_ISSUE="$2"
                shift 2
                ;;
            --generate-docs)
                PARSED_GENERATE_DOCS="true"
                shift
                ;;
            --update-existing)
                PARSED_UPDATE_EXISTING="true"
                shift
                ;;
            --help|-h)
                PARSED_HELP="true"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                return 1
                ;;
        esac
    done
}

# Show help for unified create commands
show_unified_help() {
    local command_name="$1"
    local description="$2"
    local extra_options="$3"

    cat << EOF
Usage: $command_name --title "TITLE" [OPTIONS]

$description

Required Options:
  --title "TITLE"       Issue and document title

Optional Options:
  --body "BODY"         Issue description/body
  --labels "LABELS"     Comma-separated GitHub labels
  --assignee "USER"     GitHub username to assign
  --ai-task             Add ai-task label (triggers AI workflow)
  --dry-run             Preview without creating
  --help, -h            Show this help message

$extra_options

Examples:
  $command_name --title "Add user authentication"
  $command_name --title "Fix login bug" --body "Users cannot log in" --labels "bug,frontend"
  $command_name --title "New feature" --ai-task --assignee "username"

EOF
}

# Show help for analysis commands
show_analysis_help() {
    local command_name="$1"
    local description="$2"

    cat << EOF
Usage: $command_name --issue NUMBER [OPTIONS]

$description

Required Options:
  --issue NUMBER        GitHub issue number

Optional Options:
  --generate-docs       Auto-generate missing documentation
  --update-existing     Update existing documentation
  --help, -h            Show this help message

Examples:
  $command_name --issue 25
  $command_name --issue 100 --generate-docs

EOF
}

# Escape string for sed
escape_sed() {
    echo "$1" | sed -e 's/[\/&]/\\&/g'
}

# Internal shared validation function for template paths
# Usage: _validate_template_path <template_path>
# Returns: 0 on success, 1 on failure
_validate_template_path() {
    local template_path="$1"

    # Check if template path is provided
    if [[ -z "$template_path" ]]; then
        log_error "Template path is required"
        return 1
    fi

    # Check if template file exists
    if [[ ! -f "$template_path" ]]; then
        log_error "Template not found: $template_path"
        return 1
    fi

    # Check if template file is readable
    if [[ ! -r "$template_path" ]]; then
        log_error "Template not readable: $template_path"
        return 1
    fi

    # Validate file path security (comprehensive path traversal prevention)
    if [[ "$template_path" == *../* ]] || \
       [[ "$template_path" == */../* ]] || \
       [[ "$template_path" == */./* ]] || \
       [[ "$template_path" == /../* ]] || \
       [[ "$template_path" == */.. ]] || \
       [[ "$template_path" == ..* ]] || \
       [[ "$template_path" == *//* ]]; then
        log_error "Invalid template path: contains path traversal patterns"
        return 1
    fi

    # Additional regex check for complex patterns (if supported)
    local path_traversal_pattern='\.\.\/|\/\.\.|^\.\.?$'
    if [[ "$template_path" =~ $path_traversal_pattern ]] 2>/dev/null; then
        log_error "Invalid template path: contains path traversal patterns"
        return 1
    fi

    # Additional check: resolve the canonical path and ensure it's within expected boundaries
    if command -v realpath >/dev/null 2>&1; then
        local canonical_path
        if canonical_path=$(realpath "$template_path" 2>/dev/null); then
            if [[ "${TEMPLATE_ALLOW_EXTERNAL_PATHS:-false}" != "true" ]]; then
                local current_dir
                current_dir=$(realpath "." 2>/dev/null)
                if [[ "$canonical_path" != "$current_dir"/* ]] && [[ "$canonical_path" != "$current_dir" ]]; then
                    log_error "Template path resolves outside current directory: $canonical_path"
                    return 1
                fi
            fi
        fi
    fi

    return 0
}

# Comprehensive template validation function
# Validates template files for security and integrity
# Usage: validate_template <template_path>
# Returns: 0 on success, 1 on failure
validate_template() {
    local template_path="$1"

    # Use shared path validation
    if ! _validate_template_path "$template_path"; then
        return 1
    fi

    # Check for symbolic links (security measure)
    if [[ -L "$template_path" ]]; then
        if [[ "${TEMPLATE_ALLOW_SYMLINKS:-false}" != "true" ]]; then
            log_error "Symbolic links not allowed for templates: $template_path"
            return 1
        else
            log_warning "Processing symbolic link template: $template_path"
        fi
    fi

    # Check if template file is not empty
    if [[ ! -s "$template_path" ]]; then
        log_error "Template file is empty: $template_path"
        return 1
    fi

    # Check file size (prevent extremely large templates)
    local max_size="${TEMPLATE_MAX_SIZE:-1048576}"  # Default 1MB, configurable
    local file_size

    # Improved cross-platform stat command with better portability
    if command -v stat >/dev/null 2>&1; then
        # Try BSD stat first (macOS), then GNU stat (Linux), then fallback
        if file_size=$(stat -f%z "$template_path" 2>/dev/null); then
            :  # BSD stat succeeded
        elif file_size=$(stat -c%s "$template_path" 2>/dev/null); then
            :  # GNU stat succeeded
        else
            file_size=""  # Both stat variants failed
        fi
    else
        file_size=""  # stat command not available
    fi

    # Handle stat command failures with robust fallback
    if [[ -z "$file_size" ]]; then
        log_warning "Unable to determine file size using stat for: $template_path"
        # Fall back to wc -c if stat fails
        if file_size=$(wc -c < "$template_path" 2>/dev/null); then
            # Remove any whitespace from wc output
            file_size=$(echo "$file_size" | tr -d ' \t\n')
        else
            log_error "Failed to determine file size: $template_path"
            return 1
        fi
    fi

    if [[ "$file_size" -gt "$max_size" ]]; then
        log_error "Template file too large: $template_path (${file_size} bytes, max: ${max_size})"
        return 1
    fi

    # Validate that it's a text file (not binary) with comprehensive patterns
    if command -v file >/dev/null 2>&1; then
        # Use file command if available - expanded patterns for better text detection
        local file_output
        file_output=$(file "$template_path" 2>/dev/null)
        if ! echo "$file_output" | grep -qE "(text|ASCII|UTF-8|UTF-16|Unicode|JSON|XML|HTML|empty|script|source)"; then
            # Additional check: look for null bytes
            if grep -q $'\x00' "$template_path" 2>/dev/null; then
                log_error "Template appears to be a binary file: $template_path"
                return 1
            else
                log_warning "File type uncertain, but appears to be text: $template_path (detected as: $file_output)"
            fi
        fi
    else
        # Fallback: check for null bytes (common in binary files)
        if grep -q $'\x00' "$template_path" 2>/dev/null; then
            log_error "Template contains null bytes (binary file): $template_path"
            return 1
        fi
    fi

    # Template validation successful (silent for use_template)
    return 0
}

# Safer templating function with proper validation and security
# Processes template files by replacing {{KEY}} placeholders with provided values
# Usage: use_template <template_path> KEY1 value1 KEY2 value2 ...
# Returns: 0 on success, 1 on failure. Outputs processed template to stdout
use_template() {
    local template_path="$1"
    shift

    # Parse substitution arguments into key-value pairs
    local keys=()
    local values=()
    local current_key=""
    local expecting_value=false

    # Configuration for input limits (configurable)
    local max_key_length="${TEMPLATE_MAX_KEY_LENGTH:-256}"
    local max_value_length="${TEMPLATE_MAX_VALUE_LENGTH:-65536}"
    local max_substitutions="${TEMPLATE_MAX_SUBSTITUTIONS:-100}"

    # Parse key-value pairs from arguments
    for arg in "$@"; do
        if [[ "$expecting_value" == true ]]; then
            # Validate value length
            if [[ ${#arg} -gt $max_value_length ]]; then
                log_error "Value too long for key '$current_key': ${#arg} characters (max: $max_value_length)"
                return 1
            fi

            keys+=("$current_key")
            values+=("$arg")
            expecting_value=false
        elif [[ "$arg" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
            # Validate key length
            if [[ ${#arg} -gt $max_key_length ]]; then
                log_error "Key too long: ${#arg} characters (max: $max_key_length)"
                return 1
            fi

            current_key="$arg"
            expecting_value=true
        else
            log_error "Invalid substitution key format: $arg (must start with letter or underscore, contain only letters, numbers, underscores)"
            return 1
        fi
    done

    # Check maximum number of substitutions to prevent DoS
    if [[ ${#keys[@]} -gt $max_substitutions ]]; then
        log_error "Too many substitutions: ${#keys[@]} (max: $max_substitutions)"
        return 1
    fi

    # Check for unmatched keys
    if [[ "$expecting_value" == true ]]; then
        log_error "Missing value for substitution key: $current_key"
        return 1
    fi

    # Use shared path validation first
    if ! _validate_template_path "$template_path"; then
        return 1
    fi

    # Check cache first (if enabled)
    local template_content=""
    local cache_enabled="${TEMPLATE_CACHE_ENABLED:-true}"

    if [[ "$cache_enabled" == "true" ]]; then
        _init_template_cache

        # Create cache key from template path (replace / with _)
        local cache_key="${template_path//\//_}"
        local cache_file="$_TEMPLATE_CACHE_DIR/$cache_key"
        local meta_file="$_TEMPLATE_CACHE_DIR/$cache_key.meta"

        local current_mtime
        current_mtime=$(_get_file_mtime "$template_path")

        # Check if we have a cached version with valid metadata
        if [[ -f "$cache_file" ]] && [[ -f "$meta_file" ]] && [[ -n "$current_mtime" ]]; then
            local cached_mtime
            cached_mtime=$(cat "$meta_file" 2>/dev/null | head -n1)

            if [[ "$cached_mtime" == "$current_mtime" ]]; then
                # Cache hit - read cached content
                template_content=$(cat "$cache_file" 2>/dev/null) || template_content=""
            fi
        fi
    fi

    # If not cached or cache disabled, read from file
    if [[ -z "$template_content" ]]; then
        if ! template_content=$(cat "$template_path" 2>/dev/null); then
            log_error "Failed to read template: $template_path"
            return 1
        fi

        # Update cache if enabled
        if [[ "$cache_enabled" == "true" ]] && [[ -n "$current_mtime" ]] && [[ -d "$_TEMPLATE_CACHE_DIR" ]]; then
            local cache_key="${template_path//\//_}"
            local cache_file="$_TEMPLATE_CACHE_DIR/$cache_key"
            local meta_file="$_TEMPLATE_CACHE_DIR/$cache_key.meta"

            # Write content and metadata
            printf '%s' "$template_content" > "$cache_file" 2>/dev/null || true
            printf '%s\n' "$current_mtime" > "$meta_file" 2>/dev/null || true
        fi
    fi

    # Validate template content
    local template_size=${#template_content}
    local max_size="${TEMPLATE_MAX_SIZE:-1048576}"

    if [[ "$template_size" -eq 0 ]]; then
        log_error "Template file is empty: $template_path"
        return 1
    fi

    if [[ "$template_size" -gt "$max_size" ]]; then
        log_error "Template file too large: $template_path (${template_size} characters, max: ${max_size})"
        return 1
    fi

    # Check for null bytes in content (binary file indicator)
    # Use od command for reliable null byte detection
    if printf '%s' "$template_content" | od -t x1 | grep -q ' 00 ' 2>/dev/null; then
        log_error "Template contains null bytes (binary file): $template_path"
        return 1
    fi

    # Validate template contains expected placeholders
    local placeholder_count=0
    local i=0
    while [[ $i -lt ${#keys[@]} ]]; do
        local key="${keys[$i]}"
        # Skip empty keys (shouldn't happen but defensive programming)
        if [[ -n "$key" ]]; then
            if [[ "$template_content" == *"{{$key}}"* ]]; then
                ((placeholder_count++))
            else
                log_warning "Template placeholder {{$key}} not found in template"
            fi
        fi
        ((i++))
    done

    if [[ "$placeholder_count" -eq 0 && "${#keys[@]}" -gt 0 ]]; then
        log_error "No template placeholders found for provided substitutions"
        return 1
    fi

    # Use safer bash parameter expansion instead of sed for substitution
    local result="$template_content"
    i=0
    while [[ $i -lt ${#keys[@]} ]]; do
        local key="${keys[$i]}"
        local value="${values[$i]}"

        # Skip empty keys (defensive programming)
        if [[ -z "$key" ]]; then
            ((i++))
            continue
        fi

        # Enhanced sanitization to prevent injection attacks
        local sanitized_value
        if [[ -n "$value" ]]; then
            # For template substitution, we need to escape shell metacharacters
            # but keep the result human-readable. We don't use printf %q because
            # it produces shell-quoted output that's not suitable for templates.
            # Instead, we escape only the characters that could cause injection.
            sanitized_value="$value"

            # Escape backslashes first to prevent double-escaping
            sanitized_value="${sanitized_value//\\/\\\\}"

            # Escape shell metacharacters that could cause command injection
            sanitized_value="${sanitized_value//\$/\\\$}"     # Dollar signs
            sanitized_value="${sanitized_value//\`/\\\`}"     # Backticks
            sanitized_value="${sanitized_value//\!/\\\!}"     # Exclamation marks (history expansion)
            sanitized_value="${sanitized_value//\"/\\\"}"     # Double quotes
            sanitized_value="${sanitized_value//\'/\\\'}"     # Single quotes

            # Escape other potentially dangerous characters
            sanitized_value="${sanitized_value//;/\\;}"       # Command separators
            sanitized_value="${sanitized_value//\&/\\\&}"     # Background/logical operators
            sanitized_value="${sanitized_value//\|/\\\|}"     # Pipes
            sanitized_value="${sanitized_value//</\\<}"       # Input redirection
            sanitized_value="${sanitized_value//>/\\>}"       # Output redirection
            sanitized_value="${sanitized_value//\(/\\\(}"     # Subshells
            sanitized_value="${sanitized_value//\)/\\\)}"     # Subshells
            sanitized_value="${sanitized_value//\{/\\\{}"     # Brace expansion
            sanitized_value="${sanitized_value//\}/\\\}}"     # Brace expansion
            sanitized_value="${sanitized_value//\[/\\\[}"     # Bracket expansion
            sanitized_value="${sanitized_value//\]/\\\]}"     # Bracket expansion
            sanitized_value="${sanitized_value//\*/\\\*}"     # Globbing
            sanitized_value="${sanitized_value//\?/\\\?}"     # Globbing
        else
            sanitized_value=""
        fi

        # Replace all occurrences of placeholder
        result="${result//\{\{$key\}\}/$sanitized_value}"
        ((i++))
    done

    # Validate that all placeholders were replaced (security check)
    if [[ "$result" == *"{{"* ]] && [[ "$result" == *"}}"* ]]; then
        local remaining_placeholders
        remaining_placeholders=$(echo "$result" | grep -o '{{[^}]*}}' | sort -u | tr '\n' ' ' 2>/dev/null || true)
        if [[ -n "$remaining_placeholders" ]]; then
            log_warning "Unreplaced placeholders found: $remaining_placeholders"
        fi
    fi

    # Output the processed template
    printf '%s' "$result"
    return 0
}

# Enhanced template substitution with file output
# Processes a template and writes the result to a file
# Usage: use_template_to_file <template_path> <output_path> KEY1 value1 KEY2 value2 ...
# Returns: 0 on success, 1 on failure
use_template_to_file() {
    local template_path="$1"
    local output_path="$2"
    shift 2

    # Validate output path
    if [[ -z "$output_path" ]]; then
        log_error "Output path is required"
        return 1
    fi

    # Check if output directory exists
    local output_dir
    output_dir=$(dirname "$output_path")
    if [[ ! -d "$output_dir" ]]; then
        log_error "Output directory does not exist: $output_dir"
        return 1
    fi

    # Check if output directory is writable
    if [[ ! -w "$output_dir" ]]; then
        log_error "Output directory is not writable: $output_dir"
        return 1
    fi

    # Process template
    local processed_content
    if ! processed_content=$(use_template "$template_path" "$@"); then
        return 1
    fi

    # Write to output file
    if ! printf '%s' "$processed_content" > "$output_path"; then
        log_error "Failed to write to output file: $output_path"
        return 1
    fi

    log_success "Template processed successfully: $template_path -> $output_path"
    return 0
}
