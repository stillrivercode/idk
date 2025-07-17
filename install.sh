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

# Function to show help
show_help() {
    echo -e "${GREEN}Information Dense Keywords Dictionary Installer${NC}"
    echo "================================================"
    echo ""
    echo "USAGE:"
    echo "  $0 [DIRECTORY]"
    echo "  $0 -h|--help"
    echo ""
    echo "DESCRIPTION:"
    echo "  Installs the Information Dense Keywords Dictionary to a specified directory."
    echo "  The dictionary includes the main reference file, command definitions, and AI instructions."
    echo ""
    echo "ARGUMENTS:"
    echo "  DIRECTORY    Installation directory (default: $DEFAULT_INSTALL_DIR)"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help   Show this help message and exit"
    echo ""
    echo "EXAMPLES:"
    echo "  $0              # Install to default location (./docs)"
    echo "  $0 ~/my-docs    # Install to custom directory"
    echo "  $0 --help       # Show this help message"
    echo ""
    echo "INSTALLED FILES:"
    echo "  - DIRECTORY/information-dense-keywords.md  # Main dictionary reference"
    echo "  - DIRECTORY/dictionary/                   # Command definitions"
    echo "  - DIRECTORY/AI.md                         # AI assistant instructions"
    echo ""
    echo "NOTES:"
    echo "  - Installation in system directories (/etc, /usr, etc.) is not allowed"
    echo "  - Existing files will be preserved and merged where appropriate"
    echo "  - AI.md will only be copied if it doesn't already exist in the target directory"
}

# Parse command line arguments
INSTALL_DIR=""
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            # Assume the first non-flag argument is the directory
            if [[ -z "$INSTALL_DIR" ]]; then
                # Check that it doesn't look like a flag a user might have typo'd
                if [[ "$arg" =~ ^- ]]; then
                    echo -e "${RED}Error: Unknown option '$arg'${NC}"
                    show_help
                    exit 1
                fi
                INSTALL_DIR="$arg"
            fi
            ;;
    esac
done

# If no directory was provided, use the default
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"

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

# Copy AI.md to installation directory (same location as other dictionary files)
echo "Copying AI.md to installation directory..."
# Only copy if AI.md doesn't already exist in installation directory
if [ ! -f "$INSTALL_DIR/AI.md" ]; then
    echo "AI.md not found in installation directory. Copying default version..."
    cp "AI.md" "$INSTALL_DIR/AI.md"
else
    echo "User's AI.md already exists in installation directory, skipping copy."
fi

# Verify installation
if [ -f "$INSTALL_DIR/information-dense-keywords.md" ] && [ -d "$INSTALL_DIR/dictionary" ] && [ -f "$INSTALL_DIR/AI.md" ]; then
    echo ""
    echo -e "${GREEN}✓ Installation completed successfully!${NC}"
    echo ""
    echo "Installed files:"
    echo "  - $INSTALL_DIR/information-dense-keywords.md"
    echo "  - $INSTALL_DIR/dictionary/"
    echo "  - $INSTALL_DIR/AI.md"
    echo ""
    echo "Dictionary structure:"
    find "$INSTALL_DIR/dictionary" -name "*.md" | sort | sed 's/^/  /'
else
    echo -e "${RED}Error: Installation verification failed${NC}"
    exit 1
fi

echo ""
echo "Usage: You can now reference the dictionary from $INSTALL_DIR/"
