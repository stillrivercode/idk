#!/bin/bash

# Setup script for shared commands
# Usage: ./shared-commands/setup.sh

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source utilities
source "$SCRIPT_DIR/lib/common-utils.sh"

# Configuration
COMMAND_PREFIX="shared-"

# Main setup function
main() {
    log_info "Setting up shared commands for AI assistants..."

    # Check prerequisites
    check_prerequisites

    # Make commands executable
    make_commands_executable

    # Create symbolic links (optional)
    create_symlinks

    # Test commands
    test_commands

    log_success "Shared commands setup completed!"
    echo
    show_usage_examples
}

# Check if required tools are available
check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing_tools=()

    if ! check_command "gh"; then
        missing_tools+=("gh (GitHub CLI)")
    fi

    if ! check_command "jq"; then
        missing_tools+=("jq (JSON processor)")
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        echo
        log_info "Install missing tools and run setup again."
        exit 1
    fi

    # Check GitHub CLI authentication
    if ! gh auth status &> /dev/null; then
        log_warning "GitHub CLI is not authenticated."
        log_info "Run 'gh auth login' to authenticate."
        log_info "Commands will work but may have limited functionality."
    fi

    log_success "Prerequisites check passed"
}

# Make all command scripts executable
make_commands_executable() {
    log_info "Making command scripts executable..."

    local commands_dir="$SCRIPT_DIR/commands"
    if [[ -d "$commands_dir" ]]; then
        find "$commands_dir" -name "*.sh" -type f -exec chmod +x {} \;
        log_success "Commands made executable"
    else
        log_warning "Commands directory not found: $commands_dir"
    fi
}

# Create optional symbolic links for easier access
create_symlinks() {
    log_info "Creating optional symbolic links..."

    local bin_dir="$PROJECT_ROOT/bin"
    local created_links=()

    # Ask user if they want to create symlinks
    echo
    echo "Would you like to create symbolic links in $bin_dir for easier access?"
    echo "This allows you to run commands like: ./bin/user-story-this --issue 25"
    read -p "Create symlinks? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping symbolic link creation"
        return 0
    fi

    # Create bin directory if it doesn't exist
    ensure_directory "$bin_dir"

    # Create symlinks for each command
    local commands_dir="$SCRIPT_DIR/commands"
    if [[ -d "$commands_dir" ]]; then
        for cmd_file in "$commands_dir"/*.sh; do
            if [[ -f "$cmd_file" ]]; then
                local cmd_name=$(basename "$cmd_file" .sh)
                local link_path="$bin_dir/$cmd_name"
                local relative_path="../shared-commands/commands/$cmd_name.sh"

                # Remove existing symlink if it exists
                if [[ -L "$link_path" ]]; then
                    rm "$link_path"
                fi

                # Create new symlink
                ln -s "$relative_path" "$link_path"
                created_links+=("$cmd_name")
            fi
        done
    fi

    if [[ ${#created_links[@]} -gt 0 ]]; then
        log_success "Created symbolic links:"
        for link in "${created_links[@]}"; do
            echo "  - ./bin/$link"
        done
    else
        log_warning "No command files found to link"
    fi
}

# Test commands to ensure they work
test_commands() {
    log_info "Testing command functionality..."

    local commands_dir="$SCRIPT_DIR/commands"
    local test_passed=true

    if [[ -d "$commands_dir" ]]; then
        for cmd_file in "$commands_dir"/*.sh; do
            if [[ -f "$cmd_file" ]]; then
                local cmd_name=$(basename "$cmd_file" .sh)
                log_info "Testing $cmd_name..."

                # Test help flag
                if "$cmd_file" --help &> /dev/null; then
                    log_success "$cmd_name help works"
                else
                    log_error "$cmd_name help failed"
                    test_passed=false
                fi
            fi
        done
    fi

    if [[ "$test_passed" == "true" ]]; then
        log_success "All command tests passed"
    else
        log_warning "Some command tests failed"
    fi
}

# Show usage examples
show_usage_examples() {
    cat << EOF
📋 **Usage Examples**

Direct execution:
  ./shared-commands/commands/create-user-story-issue.sh --title "User Authentication"
  ./shared-commands/commands/create-spec-issue.sh --title "API Authentication" --user-story-issue 25
  ./shared-commands/commands/analyze-issue.sh --issue 25

EOF

    # Show symlink examples if bin directory exists
    if [[ -d "$PROJECT_ROOT/bin" ]] && [[ -L "$PROJECT_ROOT/bin/create-user-story" ]]; then
        cat << EOF
Via symbolic links (if created):
  ./bin/create-user-story --title "User Authentication"
  ./bin/create-spec --title "API Authentication" --user-story-issue 25
  ./bin/analyze-issue --issue 25

EOF
    fi

    cat << EOF
📚 **Available Commands**

- **create-user-story**: Create comprehensive user story documentation
- **create-spec**: Create detailed technical specifications
- **analyze-issue**: Analyze issues for requirements and complexity
- **create-epic**: Create epic documentation
- **generate-spec**: Generate specs from existing issues
- **generate-user-story**: Generate user stories from existing issues

📖 **Documentation**

See shared-commands/README.md for detailed information about the shared commands system.

🔧 **Integration**

These commands are automatically available to:
- Claude Code (via CLAUDE.md configuration)
- Gemini (via GEMINI.md configuration)
- Any other AI assistant using the shared commands

EOF
}

# Execute main function
main "$@"
