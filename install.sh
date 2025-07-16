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

if [ ! -f "AI.md" ]; then
    echo -e "${RED}Error: AI.md not found in current directory${NC}"
    exit 1
fi


# Create docs directory if it doesn't exist
echo -e "${YELLOW}Installing to: ${INSTALL_DIR}${NC}"
mkdir -p "$INSTALL_DIR"

# Copy files (preserving existing content)
echo "Copying information-dense-keywords.md..."
cp "information-dense-keywords.md" "$INSTALL_DIR/"

echo "Copying dictionary directory..."
# Use cp -r to copy dictionary, which will merge with existing content
if [ -d "$INSTALL_DIR/dictionary" ]; then
    echo "  Merging with existing dictionary directory..."
fi
cp -r "dictionary" "$INSTALL_DIR/"

# Copy AI.md to user's working directory (where user ran the command)
echo "Copying AI.md to current directory..."
# Get the directory where the user ran the command (not where the script is located)
USER_DIR="$(pwd)"
# Only copy if AI.md doesn't already exist in user's directory
if [ ! -f "$USER_DIR/AI.md" ]; then
    echo "AI.md not found in current directory. Copying default version..."
    cp "AI.md" "$USER_DIR/AI.md"
else
    echo "User's AI.md already exists in current directory, skipping copy."
fi

# Verify installation
if [ -f "$INSTALL_DIR/information-dense-keywords.md" ] && [ -d "$INSTALL_DIR/dictionary" ] && [ -f "$USER_DIR/AI.md" ]; then
    echo ""
    echo -e "${GREEN}✓ Installation completed successfully!${NC}"
    echo ""
    echo "Installed files:"
    echo "  - $INSTALL_DIR/information-dense-keywords.md"
    echo "  - $INSTALL_DIR/dictionary/"
    echo "  - $USER_DIR/AI.md"
    echo ""
    echo "Dictionary structure:"
    find "$INSTALL_DIR/dictionary" -name "*.md" | sort | sed 's/^/  /'
else
    echo -e "${RED}Error: Installation verification failed${NC}"
    exit 1
fi

echo ""
echo "Usage: You can now reference the dictionary from $INSTALL_DIR/"
