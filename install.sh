#!/bin/bash

# Agentic Workflow Template Installation Script
# This script sets up the complete AI workflow automation environment
# Usage: ./install.sh [--dev] [--skip-labels] [--auto-yes] [--openrouter-key KEY] [--gh-pat TOKEN]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DEV=false
SKIP_LABELS=false
AUTO_YES=false
CLEANUP_CLI=false
REPO_NAME=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dev)
            INSTALL_DEV=true
            shift
            ;;
        --skip-labels)
            SKIP_LABELS=true
            shift
            ;;
        --auto-yes)
            AUTO_YES=true
            shift
            ;;
        --cleanup-cli)
            CLEANUP_CLI=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --dev               Install development dependencies"
            echo "  --skip-labels       Skip GitHub labels setup"
            echo "  --auto-yes          Automatically answer yes to prompts (non-interactive)"
            echo "  --cleanup-cli       Remove CLI directory after successful installation"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "Example:"
            echo "  ./install.sh --auto-yes --cleanup-cli"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

prompt_user() {
    local message="$1"
    local default="${2:-y}"

    if [[ "$AUTO_YES" == true ]]; then
        echo -e "${BLUE}?${NC} $message ${YELLOW}[auto-yes]${NC}"
        return 0
    fi

    echo -n -e "${BLUE}?${NC} $message [y/N]: "
    # Add timeout of 60 seconds for user input
    if read -t 60 -r response; then
        case "$response" in
            [yY][eE][sS]|[yY])
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    else
        log_warning "Timeout waiting for user input (60s). Assuming 'No'."
        return 1
    fi
}

check_python_version() {
    if check_command python3; then
        local version=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+')
        local major=$(echo $version | cut -d. -f1)
        local minor=$(echo $version | cut -d. -f2)

        if [[ $major -eq 3 && $minor -ge 12 ]]; then
            return 0
        fi
    fi
    return 1
}

create_venv() {
    log_info "Creating Python virtual environment..."

    if [[ -d "venv" ]]; then
        if prompt_user "Virtual environment already exists. Recreate it?"; then
            log_info "Removing existing virtual environment..."
            rm -rf venv
        else
            log_warning "Using existing virtual environment"
            return 0
        fi
    fi

    python3 -m venv venv
    log_success "Virtual environment created"
}

activate_venv() {
    log_info "Activating virtual environment..."

    if [[ -f "venv/bin/activate" ]]; then
        source venv/bin/activate
        log_success "Virtual environment activated"
    else
        log_error "Virtual environment not found"
        return 1
    fi
}

install_node_deps() {
    log_info "Installing Node.js dependencies..."

    if check_command npm; then
        # Check for package-lock.json to ensure consistent dependencies
        if [[ -f "package-lock.json" ]]; then
            log_info "Found package-lock.json, using npm ci for faster, consistent install"
            if [[ "$INSTALL_DEV" == true ]]; then
                npm ci --include=dev
            else
                npm ci --production
            fi
        else
            log_warning "No package-lock.json found, using npm install"
            if [[ "$INSTALL_DEV" == true ]]; then
                npm install --include=dev
            else
                npm install --production
            fi
        fi

        # Run security audit
        log_info "Running security audit..."
        npm audit || log_warning "Some vulnerabilities found. Run 'npm audit fix' to address them."

        log_success "Dependencies installed"
    else
        log_error "npm not found. Please install Node.js and npm"
        return 1
    fi
}

setup_git_hooks() {
    if [[ "$INSTALL_DEV" == true ]]; then
        log_info "Setting up native Git hooks..."

        if [[ -f "scripts/setup-git-hooks.sh" ]]; then
            chmod +x scripts/setup-git-hooks.sh
            ./scripts/setup-git-hooks.sh
            log_success "Native Git hooks setup completed"
        else
            log_warning "Git hooks setup script not found"
            log_info "You can set up hooks manually or use: ./scripts/setup-git-hooks.sh"
        fi
    else
        log_info "Skipping Git hooks setup (dev mode not enabled)"
        log_info "Run with --dev flag to enable Git hooks"
    fi
}

setup_openrouter_api() {
    log_info "Configuring OpenRouter API (replaces Claude CLI)..."

    echo ""
    echo -e "${BLUE}ℹ️  OpenRouter API Configuration${NC}"
    echo "This repository now uses OpenRouter API for AI functionality."
    echo "No CLI installation is required."
    echo ""
    echo "Setup requirements:"
    echo "1. OpenRouter API key (set OPENROUTER_API_KEY secret)"
    echo "2. Optional: AI model selection (set AI_MODEL variable)"
    echo ""
    echo "Benefits:"
    echo "• Faster execution (no CLI installation delays)"
    echo "• Multi-model support"
    echo "• Direct API integration"
    echo ""

    log_info "You'll need to set the OpenRouter API key as a repository secret"
}

setup_github_labels() {
    if [[ "$SKIP_LABELS" == true ]]; then
        log_info "Skipping GitHub labels setup (--skip-labels)"
        return 0
    fi

    log_info "Setting up GitHub labels..."

    if ! check_command gh; then
        log_warning "GitHub CLI not found, skipping labels setup"
        log_info "Install GitHub CLI: https://cli.github.com/"
        return 0
    fi

    # Check if we're in a Git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_warning "Not in a Git repository, skipping labels setup"
        return 0
    fi

    # Check if we have a remote repository
    if ! git remote get-url origin >/dev/null 2>&1; then
        log_warning "No Git remote found, skipping labels setup"
        return 0
    fi

    if [[ -f "scripts/setup-labels.sh" ]]; then
        chmod +x scripts/setup-labels.sh
        ./scripts/setup-labels.sh
    else
        log_warning "Labels setup script not found"
    fi
}

setup_shared_commands() {
    log_info "Setting up shared commands for AI assistants..."

    if [[ -d "shared-commands/commands" ]]; then
        # Simple approach: just make commands executable, skip symlinks
        find shared-commands/commands -name "*.sh" -type f -exec chmod +x {} \;
        log_success "Made command scripts executable"
        log_info "Commands available at: ./shared-commands/commands/"
    else
        log_warning "Commands directory not found: shared-commands/commands"
    fi
}

setup_template_upstream() {
    log_info "Setting up template upstream remote..."

    # Check if we're in a git repository (already checked earlier, but being safe)
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_warning "Not in a git repository, skipping upstream setup"
        return 0
    fi

    local template_url="https://github.com/stillrivercode/agentic-workflow-template.git"
    local upstream_name="template"

    # Check if upstream remote already exists
    if git remote get-url "$upstream_name" >/dev/null 2>&1; then
        local existing_url=$(git remote get-url "$upstream_name")
        if [ "$existing_url" = "$template_url" ]; then
            log_success "Template upstream remote already configured correctly"
        else
            log_warning "Upstream remote '$upstream_name' exists but points to different URL"
            log_info "Current: $existing_url"
            log_info "Expected: $template_url"
            log_info "You can update it later with: git remote set-url $upstream_name $template_url"
        fi
    else
        git remote add "$upstream_name" "$template_url"
        log_success "Added template upstream remote"
    fi

    # Fetch latest changes from template
    log_info "Fetching latest template changes..."
    if git fetch "$upstream_name" >/dev/null 2>&1; then
        log_success "Template changes fetched"
    else
        log_warning "Could not fetch template changes (network issue?)"
    fi
}

show_manual_setup_instructions() {
    echo ""
    echo "Manual setup instructions:"
    echo "1. Get OpenRouter API key: https://openrouter.ai"
    echo "2. Set secret via GitHub web interface:"
    echo "   - Go to Settings > Secrets and variables > Actions"
    echo "   - Click 'New repository secret'"
    echo "   - Name: OPENROUTER_API_KEY"
    echo "   - Value: Your OpenRouter API key"
    echo "3. Or use GitHub CLI (if available):"
    echo "   gh secret set OPENROUTER_API_KEY"
    echo ""
}

check_github_secrets() {
    log_info "Checking GitHub secrets configuration..."

    if ! check_command gh; then
        log_warning "GitHub CLI not found, cannot check secrets"
        log_info "You'll need to manually set up secrets in GitHub Settings > Secrets and variables > Actions"
        show_manual_setup_instructions
        return 0
    fi

    if ! git remote get-url origin >/dev/null 2>&1; then
        log_warning "No Git remote found, skipping secrets check"
        show_manual_setup_instructions
        return 0
    fi

    # Check if gh is authenticated and has access
    if ! gh auth status >/dev/null 2>&1; then
        log_warning "GitHub CLI not authenticated"
        log_info "Run 'gh auth login' to authenticate, then rerun this script"
        show_manual_setup_instructions
        return 0
    fi

    # Check existing secrets with error handling
    local secrets_missing=false
    local secrets_output

    if secrets_output=$(gh secret list 2>/dev/null) && echo "$secrets_output" | grep -q "OPENROUTER_API_KEY"; then
        log_success "OPENROUTER_API_KEY secret found"
    else
        if [[ -z "$secrets_output" ]]; then
            log_warning "Unable to check secrets (permission denied or repository access issue)"
        else
            log_warning "OPENROUTER_API_KEY secret not found"
        fi
        secrets_missing=true
    fi

    # Provide manual setup instructions if secrets are missing
    if [[ "$secrets_missing" == true ]]; then
        if prompt_user "Would you like to see manual setup instructions?"; then
            show_manual_setup_instructions
        fi
    fi
}

verify_installation() {
    log_info "Verifying installation..."

    # Check Node.js environment
    if [[ -f "package.json" ]]; then
        if check_command npm; then
            log_success "Node.js environment verified"
        else
            log_error "npm not found but package.json exists"
        fi
    fi

    # Check if npm dependencies are installed
    if [[ -d "node_modules" ]]; then
        log_success "Node.js dependencies installed"
    else
        log_warning "node_modules directory not found"
    fi

    # Check if scripts are executable
    if [[ -x "scripts/setup-labels.sh" ]]; then
        log_success "Scripts are executable"
    else
        log_warning "Some scripts may need chmod +x"
    fi
}

print_next_steps() {
    echo ""
    echo -e "${GREEN}🎉 Installation completed!${NC}"
    echo ""
    echo "Next steps:"

    echo "1. Verify OpenRouter API key is set as repository secret"

    # Check for missing secrets
    local missing_secrets=""
    if ! gh secret list | grep -q "OPENROUTER_API_KEY" 2>/dev/null; then
        missing_secrets="OPENROUTER_API_KEY " # pragma: allowlist secret
    fi

    if [[ -n "$missing_secrets" ]]; then
        echo "2. Set up repository secret: gh secret set ${missing_secrets% }"
    fi

    echo "3. Create your first AI task issue on GitHub"
    echo "4. Review the documentation: docs/simplified-architecture.md"
    echo ""
    echo "Shared Commands for AI Assistants:"
    echo "- Create user story: ./shared-commands/commands/create-user-story-issue.sh --title \"Feature Name\""
    echo "- Create tech spec: ./shared-commands/commands/create-spec-issue.sh --title \"Feature Architecture\""
    echo "- Analyze issue: ./shared-commands/commands/analyze-issue.sh --issue NUMBER"
    echo ""
    echo "For development:"
    echo "- Run tests: npm test"
    echo "- Run linting: npm run lint"
    echo ""
    echo "Template updates:"
    echo "- Check for updates: git log --oneline template/main ^HEAD"
    echo "- Update scripts: ./dev-scripts/update-from-template.sh"
    echo ""
    echo "Non-interactive installation:"
    echo "- ./install.sh --auto-yes"
    echo ""
}

cleanup_cli_directory() {
    if [[ "$CLEANUP_CLI" == true ]]; then
        log_info "Cleaning up CLI directory..."

        if [[ -d "cli" ]]; then
            if rm -rf cli; then
                log_success "CLI directory removed successfully"
                log_info "CLI directory was used for template installation only"
            else
                log_error "Failed to remove CLI directory"
                return 1
            fi
        else
            log_warning "CLI directory not found, nothing to clean up"
        fi
    fi
}

main() {
    echo -e "${BLUE}🤖 Agentic Workflow Template Installer${NC}"
    echo "Setting up AI-powered development workflow automation..."
    echo ""

    # Prerequisites check
    log_info "Checking prerequisites..."

    if ! check_command node; then
        log_error "Node.js is required"
        log_info "Install Node.js: https://nodejs.org/"
        exit 1
    fi
    log_success "Node.js found"

    if ! check_command npm; then
        log_error "npm is required"
        log_info "npm should come with Node.js installation"
        exit 1
    fi
    log_success "npm found"

    if ! check_command git; then
        log_error "Git is required"
        exit 1
    fi
    log_success "Git found"

    # Main installation steps
    install_node_deps
    setup_git_hooks
    setup_openrouter_api
    setup_github_labels
    setup_shared_commands
    setup_template_upstream
    check_github_secrets
    verify_installation
    cleanup_cli_directory
    print_next_steps
}

# Run main function
main "$@"
