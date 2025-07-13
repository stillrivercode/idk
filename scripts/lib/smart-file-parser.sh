#!/bin/bash

# Smart File Parser Library
# Provides intelligent content extraction for large files
# Supports markdown structure parsing and content chunking

# Security and performance configuration
readonly REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
readonly CACHE_DIR="/tmp/file_parser_cache"
readonly MAX_FILE_SIZE="$((10 * 1024 * 1024))"  # 10MB limit
readonly MAX_LINE_LENGTH=10000
readonly PROCESS_TIMEOUT=30  # seconds

# Initialize cache directory
mkdir -p "$CACHE_DIR" 2>/dev/null || true

# Enhanced error logging function
log_error() {
    local msg="$1"
    local file="${2:-unknown}"
    local func="${FUNCNAME[1]:-unknown}"
    echo "ERROR: [$func] $msg (file: $file)" >&2
}

# Security: Path sanitization function
sanitize_file_path() {
    local input_path="$1"
    local file_path

    # Resolve path and check if it exists within repository
    file_path=$(realpath -q "$input_path" 2>/dev/null || echo "")

    if [[ -z "$file_path" ]]; then
        log_error "Invalid or non-existent path" "$input_path"
        return 1
    fi

    # Security check: ensure path is within repository
    if [[ ! "$file_path" =~ ^$REPO_ROOT ]]; then
        log_error "Invalid file path outside repository" "$input_path"
        return 1
    fi

    # Check file size limit
    if [[ -f "$file_path" ]]; then
        local file_size
        file_size=$(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path" 2>/dev/null || echo "0")
        if [[ $file_size -gt $MAX_FILE_SIZE ]]; then
            log_error "File exceeds maximum size limit ($MAX_FILE_SIZE bytes)" "$file_path"
            return 1
        fi
    fi

    echo "$file_path"
}

# Extract markdown structure (headers and sections)
extract_markdown_structure() {
    local input_path="$1"
    local file_path

    # Security: Sanitize and validate file path
    file_path=$(sanitize_file_path "$input_path")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    if [[ ! -f "$file_path" ]]; then
        log_error "File does not exist" "$file_path"
        return 1
    fi

    # Performance: Check cache first
    local cache_key
    cache_key=$(echo "structure_$file_path" | md5sum | cut -d' ' -f1)
    local cache_file="$CACHE_DIR/$cache_key"
    local file_mtime
    file_mtime=$(stat -c%Y "$file_path" 2>/dev/null || stat -f%m "$file_path" 2>/dev/null || echo "0")

    if [[ -f "$cache_file" ]]; then
        local cache_mtime
        cache_mtime=$(stat -c%Y "$cache_file" 2>/dev/null || stat -f%m "$cache_file" 2>/dev/null || echo "0")
        if [[ $cache_mtime -ge $file_mtime ]]; then
            cat "$cache_file"
            return 0
        fi
    fi

    local structure=""
    local line_count=0

    # Performance: Single-pass file reading with timeout
    {
        while IFS= read -r line; do
            line_count=$((line_count + 1))

            # Security: Check line length
            if [[ ${#line} -gt $MAX_LINE_LENGTH ]]; then
                log_error "Line $line_count exceeds maximum length" "$file_path"
                continue
            fi

            # Process markdown headers
            if [[ "$line" =~ ^(#{1,6})[[:space:]]+(.+)$ ]]; then
                local level="${BASH_REMATCH[1]}"
                local title="${BASH_REMATCH[2]}"
                # Security: Sanitize title (remove potential shell characters)
                title=$(echo "$title" | sed 's/[`$\\]//g')
                structure+="${level} ${title}\n"
            fi
        done < "$file_path"
    } &

    # Timeout protection
    local pid=$!
    sleep $PROCESS_TIMEOUT && kill $pid 2>/dev/null &
    local timeout_pid=$!

    if wait $pid 2>/dev/null; then
        kill $timeout_pid 2>/dev/null
        # Cache the result
        echo -e "$structure" > "$cache_file" 2>/dev/null
        echo -e "$structure"
    else
        kill $timeout_pid 2>/dev/null
        log_error "Processing timeout exceeded" "$file_path"
        return 1
    fi
}

# Find relevant content sections based on keywords
find_relevant_sections() {
    local input_path="$1"
    local keywords="$2"
    local max_sections="${3:-2}"

    # Security: Sanitize inputs
    local file_path
    file_path=$(sanitize_file_path "$input_path")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    if [[ ! -f "$file_path" ]]; then
        log_error "File does not exist" "$file_path"
        return 1
    fi

    # Security: Sanitize keywords to prevent regex injection
    keywords=$(echo "$keywords" | sed 's/[^a-zA-Z0-9 _-]//g')
    if [[ -z "$keywords" ]]; then
        log_error "No valid keywords provided" "$file_path"
        return 1
    fi

    # Convert keywords to lowercase for case-insensitive matching
    local keywords_lower
    keywords_lower=$(echo "$keywords" | tr '[:upper:]' '[:lower:]')

    # Split into individual keywords
    local -a keyword_array
    IFS=' ' read -ra keyword_array <<< "$keywords_lower"

    local current_section=""
    local current_header=""
    local -a sections=()
    local -a scores=()

    # Performance: Single-pass file reading with error handling
    local line_count=0

    {
        while IFS= read -r line; do
            line_count=$((line_count + 1))

            # Security: Check line length
            if [[ ${#line} -gt $MAX_LINE_LENGTH ]]; then
                log_error "Line $line_count exceeds maximum length" "$file_path"
                continue
            fi

            # Check if this is a header
            if [[ "$line" =~ ^(#{1,6})[[:space:]]+(.+)$ ]]; then
                # Process previous section if we have one
                if [[ -n "$current_section" ]]; then
                    local score=0
                    local section_lower
                    section_lower=$(echo "$current_section" | tr '[:upper:]' '[:lower:]')

                    # Performance: Optimize keyword matching
                    for keyword in "${keyword_array[@]}"; do
                        # Use parameter expansion instead of external commands
                        local temp="$section_lower"
                        local matches=0
                        while [[ "$temp" == *"$keyword"* ]]; do
                            matches=$((matches + 1))
                            temp="${temp#*$keyword}"
                        done
                        score=$((score + matches))
                    done

                    # Performance: Optimize header matching
                    local header_lower
                    header_lower=$(echo "$current_header" | tr '[:upper:]' '[:lower:]')
                    for keyword in "${keyword_array[@]}"; do
                        if [[ "$header_lower" == *"$keyword"* ]]; then
                            score=$((score + 3))  # Header matches are more important
                        fi
                    done

                    if [[ $score -gt 0 ]]; then
                        sections+=("$current_header|$current_section")
                        scores+=("$score")
                    fi
                fi

                # Start new section
                current_header="$line"
                current_section="$line\n"
            else
                current_section+="$line\n"
            fi
        done < "$file_path"
    } &

    # Timeout protection
    local pid=$!
    sleep $PROCESS_TIMEOUT && kill $pid 2>/dev/null &
    local timeout_pid=$!

    if ! wait $pid 2>/dev/null; then
        kill $timeout_pid 2>/dev/null
        log_error "Processing timeout exceeded" "$file_path"
        return 1
    fi
    kill $timeout_pid 2>/dev/null

    # Process final section
    if [[ -n "$current_section" ]]; then
        local score=0
        local section_lower
        section_lower=$(echo "$current_section" | tr '[:upper:]' '[:lower:]')

        # Performance: Optimize keyword matching (final section)
        for keyword in "${keyword_array[@]}"; do
            local temp="$section_lower"
            local matches=0
            while [[ "$temp" == *"$keyword"* ]]; do
                matches=$((matches + 1))
                temp="${temp#*$keyword}"
            done
            score=$((score + matches))
        done

        local header_lower
        header_lower=$(echo "$current_header" | tr '[:upper:]' '[:lower:]')
        for keyword in "${keyword_array[@]}"; do
            if [[ "$header_lower" == *"$keyword"* ]]; then
                score=$((score + 3))
            fi
        done

        if [[ $score -gt 0 ]]; then
            sections+=("$current_header|$current_section")
            scores+=("$score")
        fi
    fi

    # Performance: Use more efficient sorting for larger arrays
    # Check if arrays have elements before processing
    if [[ ${#sections[@]} -eq 0 ]]; then
        return 0
    fi

    local n=${#sections[@]}
    if [[ $n -gt 10 ]]; then
        # Use shell sort for better performance on larger arrays
        local gap=$((n / 2))
        while [[ $gap -gt 0 ]]; do
            for ((i = gap; i < n; i++)); do
                local temp_score=${scores[i]}
                local temp_section="${sections[i]}"
                local j=$i

                while [[ $j -ge $gap && ${scores[$((j - gap))]} -lt $temp_score ]]; do
                    scores[j]=${scores[$((j - gap))]}
                    sections[j]="${sections[$((j - gap))]}"
                    j=$((j - gap))
                done

                scores[j]=$temp_score
                sections[j]="$temp_section"
            done
            gap=$((gap / 2))
        done
    else
        # Use bubble sort for small arrays (original logic)
        for ((i = 0; i < n; i++)); do
            for ((j = 0; j < n - i - 1; j++)); do
                if [[ ${scores[j]} -lt ${scores[j+1]} ]]; then
                    # Swap scores
                    local temp_score=${scores[j]}
                    scores[j]=${scores[j+1]}
                    scores[j+1]=$temp_score

                    # Swap sections
                    local temp_section="${sections[j]}"
                    sections[j]="${sections[j+1]}"
                    sections[j+1]="$temp_section"
                fi
            done
        done
    fi

    # Return top sections (up to max_sections)
    local count=0
    for section in "${sections[@]}"; do
        if [[ $count -ge $max_sections ]]; then
            break
        fi
        echo "$section"
        count=$((count + 1))
    done
}

# Generate smart file context with structure + relevant content
generate_smart_file_context() {
    local input_path="$1"
    local issue_text="$2"
    local max_context_size="${3:-3000}"

    # Security: Sanitize inputs
    local file_path
    file_path=$(sanitize_file_path "$input_path")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    if [[ ! -f "$file_path" ]]; then
        log_error "File does not exist" "$file_path"
        return 1
    fi

    # Security: Sanitize issue text
    issue_text=$(echo "$issue_text" | sed 's/[^a-zA-Z0-9 _.-]//g')

    local context=""
    local file_extension="${file_path##*.}"
    file_extension=$(echo "$file_extension" | tr '[:upper:]' '[:lower:]')

    case "$file_extension" in
        "md"|"markdown")
            # Handle Markdown files with structure + relevant content
            local structure
            structure=$(extract_markdown_structure "$file_path")

            if [[ -n "$structure" ]]; then
                context+="\n### File Structure of \`$file_path\`:\n"
                context+="$structure\n"

                # Find relevant sections based on issue text
                local relevant_sections
                relevant_sections=$(find_relevant_sections "$file_path" "$issue_text" 2)

                if [[ -n "$relevant_sections" ]]; then
                    context+="\n### Most Relevant Sections:\n"

                    local section_count=0
                    while IFS='|' read -r header section_content; do
                        if [[ $section_count -ge 2 ]]; then
                            break
                        fi

                        # Limit section content to reasonable size
                        local trimmed_content
                        trimmed_content=$(echo -e "$section_content" | head -15)

                        context+="\n#### Relevant Section: $header\n"
                        context+="\`\`\`\n$trimmed_content\n\`\`\`\n"

                        section_count=$((section_count + 1))

                        # Check if we're approaching context limit
                        if [[ ${#context} -gt $((max_context_size - 500)) ]]; then
                            break
                        fi
                    done <<< "$relevant_sections"
                fi
            else
                # Fallback for markdown without clear structure
                context+="\n### Content Preview of \`$file_path\` (first 20 lines):\n"
                context+="\`\`\`\n$(head -20 "$file_path")\n\`\`\`\n"
            fi
            ;;
        "json")
            # Handle JSON files - show structure
            context+="\n### JSON Structure of \`$file_path\`:\n"
            if command -v jq >/dev/null 2>&1; then
                context+="\`\`\`json\n$(jq 'paths(scalars) as $p | $p | join(".")' "$file_path" 2>/dev/null | head -20)\n\`\`\`\n"
            else
                context+="\`\`\`json\n$(head -20 "$file_path")\n\`\`\`\n"
            fi
            ;;
        *)
            # Default handling for other file types
            local file_size
            file_size=$(wc -c < "$file_path" 2>/dev/null || echo "0")

            if [[ $file_size -lt 1000 ]]; then
                # Small files - include full content
                context+="\n### Full Content of \`$file_path\`:\n"
                context+="\`\`\`\n$(cat "$file_path")\n\`\`\`\n"
            else
                # Large files - show preview
                context+="\n### Content Preview of \`$file_path\` (first 15 lines):\n"
                context+="\`\`\`\n$(head -15 "$file_path")\n\`\`\`\n"
            fi
            ;;
    esac

    # Truncate if still too large
    if [[ ${#context} -gt $max_context_size ]]; then
        context="${context:0:$max_context_size}\n\n... [Content truncated to fit context limits]"
    fi

    echo "$context"
}

# Generate file summary for caching
generate_file_summary() {
    local input_path="$1"
    local summary=""

    # Security: Sanitize file path
    local file_path
    file_path=$(sanitize_file_path "$input_path")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    if [[ ! -f "$file_path" ]]; then
        log_error "File does not exist" "$file_path"
        return 1
    fi

    local file_size
    file_size=$(wc -c < "$file_path" 2>/dev/null || echo "0")
    local line_count
    line_count=$(wc -l < "$file_path" 2>/dev/null || echo "0")
    local file_extension="${file_path##*.}"

    summary="File: $file_path\n"
    summary+="Size: $file_size bytes\n"
    summary+="Lines: $line_count\n"
    summary+="Type: $file_extension\n"

    # Add last modified time for cache invalidation
    if command -v stat >/dev/null 2>&1; then
        local last_modified
        if [[ "$(uname)" == "Darwin" ]]; then
            last_modified=$(stat -f "%m" "$file_path" 2>/dev/null || echo "0")
        else
            last_modified=$(stat -c "%Y" "$file_path" 2>/dev/null || echo "0")
        fi
        summary+="LastModified: $last_modified\n"
    fi

    echo -e "$summary"
}
