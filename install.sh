#!/bin/bash

# Information Dense Keywords Dictionary Installer
# This script installs the dictionary and index file to a docs/ directory

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default installation directory
DEFAULT_INSTALL_DIR="./docs"

# Parse command line arguments
INSTALL_DIR="${1:-$DEFAULT_INSTALL_DIR}"

# Prevent installation in sensitive system directories
if [[ "$INSTALL_DIR" == "/" || "$INSTALL_DIR" == "/etc" || "$INSTALL_DIR" == "/usr"* || "$INSTALL_DIR" == "/var"* || "$INSTALL_DIR" == "/bin"* || "$INSTALL_DIR" == "/sbin"* ]]; then
    echo -e "${RED}Error: Installation in system directory '$INSTALL_DIR' is not allowed${NC}"
    echo "Please choose a different directory for installation."
    exit 1
fi

echo -e "${GREEN}Information Dense Keywords Dictionary Installer${NC}"
echo "================================================"
echo ""

# Check if source files exist
if [ ! -f "information-dense-keywords.md" ]; then
    echo -e "${RED}Error: information-dense-keywords.md not found in current directory${NC}"
    exit 1
fi

if [ ! -d "dictionary" ]; then
    echo -e "${RED}Error: dictionary/ directory not found in current directory${NC}"
    exit 1
fi

# Create AI.md if it doesn't exist (for backward compatibility)
if [ ! -f "AI.md" ]; then
    echo -e "${YELLOW}AI.md not found, creating default AI.md...${NC}"
    cat > "AI.md" << 'EOF'
# AI.md - Shared Instructions for All AI Assistants

This file provides common guidance for all AI assistants working with the Information Dense Keywords Dictionary project.

## Project Overview

This is the Information Dense Keywords Dictionary - a curated vocabulary for instructing AI assistants. The project provides a shared, efficient vocabulary for common software development tasks using natural language.

## How to Use This Dictionary

As an AI assistant, you should use the `information-dense-keywords.md` file as your primary reference for understanding user intent. When a user issues a command, follow this pattern:

### Usage Pattern

1. **Identify the Keyword**: Parse the user's prompt to identify the core command (e.g., `SELECT`, `CREATE`, `FIX`).

2. **Understand the Definition**: Refer to the `Definition` for that keyword in `information-dense-keywords.md` to understand the user's high-level goal.

3. **Extract Entities**: Identify the specific entities in the user's prompt. For example, in "CREATE a new React component called 'LoginButton'":
   * **Component Type**: React component
   * **Component Name**: LoginButton

4. **Execute the Command**: Based on the keyword and entities, perform the requested action through:
   * Searching for files in the codebase
   * Generating new code
   * Modifying existing code
   * Running shell commands

## Dictionary Commands

The core commands in `information-dense-keywords.md` include:

* **SELECT** - Choose or filter items from a collection
* **CREATE** - Generate new code, files, or components
* **FIX** - Resolve bugs, errors, or issues
* **UPDATE** - Modify existing code or configurations
* **DELETE** - Remove code, files, or configurations
* **ANALYZE** - Examine and understand code or systems
* **DEPLOY** - Release or publish applications

## Working with This Project

When helping users with this dictionary project:

1. **Content Updates**: Help users add new commands or improve existing definitions
2. **Example Enhancement**: Assist in adding practical usage examples
3. **Quality Assurance**: Ensure definitions are clear and actionable
4. **Validation**: Test that commands work effectively with AI assistants

## File Structure

Key files you'll work with:

* `information-dense-keywords.md` - The core dictionary content
* `README.md` - Project documentation and usage guide
* `docs/roadmaps/ROADMAP.md` - Development priorities and future plans
* `examples/` - Usage examples and guides
* `adrs/` - Architecture decision records
* `AI.md` - This shared AI instruction file

## Core Principles

Remember: This project focuses on creating a clear, actionable vocabulary for human-AI collaboration in software development. Prioritize:

* **Clarity**: Make definitions unambiguous and easy to understand
* **Practical Utility**: Focus on commands that solve real development problems
* **Broad Applicability**: Ensure commands work across different technologies and contexts
* **Consistency**: Maintain consistent patterns and structures throughout the dictionary

## AI-Specific Considerations

This file provides general guidance for all AI assistants. You are encouraged to customize this file with project-specific details and considerations relevant to your specific use case.
EOF
fi

# Create docs directory if it doesn't exist
echo -e "${YELLOW}Installing to: ${INSTALL_DIR}${NC}"
mkdir -p "$INSTALL_DIR"

# Copy files
echo "Copying information-dense-keywords.md..."
cp "information-dense-keywords.md" "$INSTALL_DIR/"

echo "Copying dictionary directory..."
cp -r "dictionary" "$INSTALL_DIR/"

# Copy AI.md to project root (parent of install directory)
echo "Copying AI.md to project root..."
# Use realpath to resolve the absolute path of the parent directory ('project root').
# This robustly handles cases like relative paths (e.g., './docs') or nested paths.
PROJECT_ROOT=$(realpath "$INSTALL_DIR/..")
# Only copy if source and destination are different
if [ "$(realpath AI.md)" != "$(realpath "$PROJECT_ROOT/AI.md" 2>/dev/null || echo "$PROJECT_ROOT/AI.md")" ]; then
    cp "AI.md" "$PROJECT_ROOT/"
else
    echo "AI.md already exists in project root, skipping copy"
fi

# Verify installation
if [ -f "$INSTALL_DIR/information-dense-keywords.md" ] && [ -d "$INSTALL_DIR/dictionary" ] && [ -f "$PROJECT_ROOT/AI.md" ]; then
    echo ""
    echo -e "${GREEN}✓ Installation completed successfully!${NC}"
    echo ""
    echo "Installed files:"
    echo "  - $INSTALL_DIR/information-dense-keywords.md"
    echo "  - $INSTALL_DIR/dictionary/"
    echo "  - $PROJECT_ROOT/AI.md"
    echo ""
    echo "Dictionary structure:"
    find "$INSTALL_DIR/dictionary" -name "*.md" | sort | sed 's/^/  /'
else
    echo -e "${RED}Error: Installation verification failed${NC}"
    exit 1
fi

echo ""
echo "Usage: You can now reference the dictionary from $INSTALL_DIR/"
