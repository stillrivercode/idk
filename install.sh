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

# Copy files
echo "Copying information-dense-keywords.md..."
cp "information-dense-keywords.md" "$INSTALL_DIR/"

echo "Copying dictionary directory..."
cp -r "dictionary" "$INSTALL_DIR/"

# Copy AI.md to project root (parent of install directory)
echo "Copying AI.md to project root..."
# If INSTALL_DIR is ./docs, project root is ./
# If INSTALL_DIR is /path/to/custom/docs, project root is /path/to/custom
PROJECT_ROOT=$(dirname "$INSTALL_DIR")
cp "AI.md" "$PROJECT_ROOT/"

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
