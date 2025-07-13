#!/bin/bash
# File operations library for AI task execution
# Provides functions for file creation, editing, and validation

# Apply edit operation to a file using SEARCH/REPLACE format
apply_edit_operation() {
    local file_path="$1"
    local edit_content="$2"

    # Parse SEARCH/REPLACE blocks
    local search_text=""
    local replace_text=""
    local in_search=false
    local in_replace=false

    while IFS= read -r line; do
        if [[ "${line,,}" =~ ^[[:space:]]*search:[[:space:]]*$ ]]; then
            in_search=true
            in_replace=false
        elif [[ "${line,,}" =~ ^[[:space:]]*replace:[[:space:]]*$ ]]; then
            in_search=false
            in_replace=true
        elif [[ $in_search == true ]]; then
            search_text+="$line"$'\n'
        elif [[ $in_replace == true ]]; then
            replace_text+="$line"$'\n'
        fi
    done <<< "$edit_content"

    # Remove trailing newlines
    search_text="${search_text%$'\n'}"
    replace_text="${replace_text%$'\n'}"

    # Validate we have both search and replace text
    if [[ -z "$search_text" ]]; then
        log_warn "⚠️ Edit block missing SEARCH text for $file_path"
        return 1
    fi

    # Check if file exists
    if [[ ! -f "$file_path" ]]; then
        log_warn "⚠️ Cannot apply edit - file doesn't exist: $file_path"
        return 1
    fi

    log_info "🔄 Applying edit to $file_path"
    log_debug "   Searching for: $(echo "$search_text" | head -1)..."

    # Create a temporary file for the edit
    local temp_file=$(mktemp)
    # Set up cleanup trap - capture the variable value, not the variable name
    trap "rm -f \"$temp_file\"" EXIT

    # Check file size before loading into memory
    if [[ $(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path" 2>/dev/null) -gt 1048576 ]]; then
        log_warn "⚠️ File too large (>1MB): $file_path"
        rm -f "$temp_file"
        return 1
    fi

    # Read the file and apply the replacement
    local file_content=$(<"$file_path")
    if [[ "$file_content" == *"$search_text"* ]]; then
        # Perform the replacement (only first occurrence to prevent unintended widespread changes)
        file_content="${file_content/"$search_text"/"$replace_text"}"
        echo "$file_content" > "$temp_file"
        mv "$temp_file" "$file_path"
        log_info "✅ Successfully applied edit to $file_path"
        return 0
    else
        log_warn "⚠️ Could not find search text in $file_path"
        log_debug "   Search text: $search_text"
        rm -f "$temp_file"
        return 1
    fi
}

# Create or overwrite a file with content
create_or_update_file() {
    local file_path="$1"
    local content="$2"

    # Create directory if needed
    local dir_path
    dir_path="$(dirname "$file_path")"
    if [[ "$dir_path" != "." ]] && [[ ! -d "$dir_path" ]]; then
        log_info "📁 Creating directory: $dir_path"
        mkdir -p "$dir_path"
    fi

    # Remove trailing newline from content if present
    content="${content%$'\n'}"

    # Write the content to the file
    printf '%s\n' "$content" > "$file_path"

    log_info "✅ Created/updated file: $file_path ($(wc -l < "$file_path") lines)"
    return 0
}

# Validate file path for security
validate_file_path_security() {
    local file_path="$1"
    local block_language="${2:-}"

    # Canonicalize path and ensure it stays within workspace
    local canonical_path
    canonical_path="$(realpath -m "$file_path" 2>/dev/null || echo "$file_path")"
    if [[ "$canonical_path" != "$PWD"/* ]]; then
        log_warn "⚠️ Path escapes workspace: $file_path"
        return 1
    fi

    # Check for directory traversal (additional check)
    if [[ "$file_path" =~ \.\./|\.\.\\ ]]; then
        log_warn "⚠️ Skipping potentially unsafe file path: $file_path"
        return 1
    fi

    # Check for absolute paths
    if [[ "$file_path" == /* ]]; then
        log_warn "⚠️ Skipping absolute path: $file_path"
        return 1
    fi

    # Check for temporary files
    if [[ "$file_path" =~ ^temp_|^tmp_|\.tmp$|\.temp$ ]]; then
        log_warn "⚠️ Skipping temporary file: $file_path (only implementation files should be created)"
        return 1
    fi

    # Check for executable files (unless it's an edit operation)
    if [[ "$file_path" =~ \.(sh|bash|exe|bin|bat|cmd|ps1|pl|rb)$ ]] && [[ "$block_language" != "edit" ]]; then
        log_warn "⚠️ SECURITY: Skipping executable file type: $file_path (must have explicit path from AI)"
        return 1
    fi

    return 0
}

# File type validation configuration
readonly -a ALLOWED_FILE_EXTENSIONS=(
    "md" "txt" "json" "yml" "yaml" "js" "py" "sh" "bash"
    "html" "css" "xml" "ini" "conf" "config" "env"
)

readonly -a BLOCKED_FILE_EXTENSIONS=(
    "exe" "bin" "so" "dll" "dylib" "app" "dmg" "pkg"
    "zip" "tar" "gz" "bz2" "7z" "rar" "pdf" "doc" "docx"
    "key" "pem" "p12" "jks" "keystore" "crt" "cer"
)

# Validate file type for context inclusion
validate_file_type() {
    local file_path="$1"
    local file_extension

    # Extract file extension (handle multiple dots)
    file_extension="${file_path##*.}"
    file_extension="$(echo "$file_extension" | tr '[:upper:]' '[:lower:]')" # Convert to lowercase

    # Check if file extension is blocked (security check)
    for blocked_ext in "${BLOCKED_FILE_EXTENSIONS[@]}"; do
        if [[ "$file_extension" == "$blocked_ext" ]]; then
            log_debug "🚫 File type blocked for security: $file_path (.$file_extension)"
            return 1
        fi
    done

    # Check if file extension is explicitly allowed
    for allowed_ext in "${ALLOWED_FILE_EXTENSIONS[@]}"; do
        if [[ "$file_extension" == "$allowed_ext" ]]; then
            log_debug "✅ File type allowed: $file_path (.$file_extension)"
            return 0
        fi
    done

    # Special case: files without extensions (like LICENSE, Makefile)
    local filename
    filename="$(basename "$file_path")"
    case "$filename" in
        LICENSE|CHANGELOG|MAKEFILE|DOCKERFILE|Makefile|Dockerfile)
            log_debug "✅ Special file allowed: $file_path"
            return 0
            ;;
        .*)
            log_debug "🚫 Hidden/config file not allowed: $file_path"
            return 1
            ;;
        *)
            log_debug "⚠️ Unknown file type, allowing with caution: $file_path"
            return 0
            ;;
    esac
}
