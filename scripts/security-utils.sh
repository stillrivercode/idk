#!/bin/bash
set -euo pipefail

# Security utilities for safe subprocess execution.
# This module provides secure wrappers for common subprocess operations.

# Allowed commands for execution (space-separated list)
ALLOWED_COMMANDS="git python python3 pip pip3 pytest bandit black ruff mypy npm node jq curl"

# Function to find executable with security validation
find_executable() {
    local command="$1"

    if [[ ! " $ALLOWED_COMMANDS " =~ " $command " ]]; then
        echo "Error: Command '$command' is not in the allowed list" >&2
        return 1
    fi

    local full_path
    full_path=$(command -v "$command" 2>/dev/null || true)

    if [[ -z "$full_path" ]]; then
        echo "Error: Command '$command' not found in PATH" >&2
        return 1
    fi

    echo "$full_path"
}

# Function to securely run a subprocess command
secure_run() {
    local -a command_args=()
    local cwd=""
    local check="true"
    local capture_output="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cwd)
                cwd="$2"
                shift 2
                ;;
            --no-check)
                check="false"
                shift
                ;;
            --capture-output)
                capture_output="true"
                shift
                ;;
            --)
                shift
                command_args=("$@")
                break
                ;;
            *)
                command_args+=("$1")
                shift
                ;;
        esac
    done

    if [[ ${#command_args[@]} -eq 0 ]]; then
        echo "Error: Command list cannot be empty" >&2
        return 1
    fi

    # Get the executable name
    local executable="${command_args[0]}"

    # Find the full path to the executable
    local full_path
    full_path=$(find_executable "$executable")

    # Replace the command with the full path
    command_args[0]="$full_path"

    # Validate cwd if provided
    if [[ -n "$cwd" ]]; then
        if [[ ! -d "$cwd" ]]; then
            echo "Error: Working directory '$cwd' does not exist or is not a directory" >&2
            return 1
        fi

        # Resolve to absolute path
        cwd=$(cd "$cwd" && pwd)
    fi

    # Run the command securely
    # Validate and sanitize each argument
    local -a sanitized_args=()
    for arg in "${command_args[@]}"; do
        # Check for dangerous characters that could lead to command injection
        if [[ "$arg" =~ [';|&$`'] ]]; then
            echo "Error: Argument contains potentially dangerous characters: '$arg'" >&2
            return 1
        fi
        sanitized_args+=("$arg")
    done

    if [[ -n "$cwd" ]]; then
        cd "$cwd"
    fi

    if [[ "$capture_output" == "true" ]]; then
        "${sanitized_args[@]}" 2>&1
    else
        "${sanitized_args[@]}"
    fi

    local exit_code=$?

    if [[ "$check" == "true" && $exit_code -ne 0 ]]; then
        echo "Error: Command failed with exit code $exit_code" >&2
        return $exit_code
    fi

    return $exit_code
}

# Function to validate file path for security
validate_file_path() {
    local path="$1"
    local must_exist="${2:-true}"

    # Use realpath for proper canonicalization
    local resolved_path
    resolved_path=$(realpath -m "$path" 2>/dev/null) || {
        echo "Error: Invalid path '$path'" >&2
        return 1
    }

    # Get canonical project root and current directory
    local project_root current_dir
    project_root=$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")
    current_dir=$(realpath "$(pwd)")

    # Ensure path is within project or current directory (using realpath comparison)
    local path_is_valid=false
    case "$resolved_path" in
        "$project_root"/*)
            path_is_valid=true
            ;;
        "$current_dir"/*)
            path_is_valid=true
            ;;
        "$project_root")
            path_is_valid=true
            ;;
        "$current_dir")
            path_is_valid=true
            ;;
    esac

    if [[ "$path_is_valid" != "true" ]]; then
        echo "Error: Path '$path' is outside project directory" >&2
        return 1
    fi

    if [[ "$must_exist" == "true" && ! -e "$resolved_path" ]]; then
        echo "Error: Path '$path' does not exist" >&2
        return 1
    fi

    echo "$resolved_path"
}

# Function to safely write content to a file
safe_file_write() {
    local path="$1"
    local content="$2"
    local mode="${3:-w}"

    # Validate the path
    local file_path
    file_path=$(validate_file_path "$path" "false")

    # Ensure parent directory exists
    local parent_dir
    parent_dir=$(dirname "$file_path")
    mkdir -p "$parent_dir"

    # Write the file
    if [[ "$mode" == "a" ]]; then
        echo "$content" >> "$file_path"
    else
        echo "$content" > "$file_path"
    fi
}

# Function to safely read content from a file
safe_file_read() {
    local path="$1"

    # Validate the path
    local file_path
    file_path=$(validate_file_path "$path" "true")

    # Read the file
    cat "$file_path"
}

# Function to check if a command is allowed
is_command_allowed() {
    local command="$1"
    [[ " $ALLOWED_COMMANDS " =~ " $command " ]]
}

# Function to add allowed command (for extension)
add_allowed_command() {
    local command="$1"
    if [[ ! " $ALLOWED_COMMANDS " =~ " $command " ]]; then
        ALLOWED_COMMANDS="$ALLOWED_COMMANDS $command"
    fi
}

# Function to remove allowed command
remove_allowed_command() {
    local command="$1"
    ALLOWED_COMMANDS=$(echo "$ALLOWED_COMMANDS" | sed "s/\b$command\b//g" | tr -s ' ')
}

# Function to list allowed commands
list_allowed_commands() {
    echo "$ALLOWED_COMMANDS" | tr ' ' '\n' | sort
}

# Example usage function
example_usage() {
    cat << 'EOF'
Security Utils Usage Examples:

1. Secure command execution:
   secure_run git status
   secure_run --cwd /path/to/repo git log --oneline
   secure_run --capture-output python3 script.py

2. File operations:
   safe_file_write "output.txt" "Hello World"
   content=$(safe_file_read "input.txt")

3. Path validation:
   validated_path=$(validate_file_path "some/file.txt")

4. Command validation:
   if is_command_allowed "git"; then
       echo "Git is allowed"
   fi

5. Managing allowed commands:
   add_allowed_command "new_tool"
   list_allowed_commands
   remove_allowed_command "old_tool"
EOF
}

# Show usage if script is called with --help
if [[ "${1:-}" == "--help" ]]; then
    example_usage
    exit 0
fi

# Export functions for use in other scripts
export -f find_executable
export -f secure_run
export -f validate_file_path
export -f safe_file_write
export -f safe_file_read
export -f is_command_allowed
export -f add_allowed_command
export -f remove_allowed_command
export -f list_allowed_commands
