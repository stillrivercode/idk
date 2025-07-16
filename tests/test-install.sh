#!/bin/bash

# Test script for the Information Dense Keywords Dictionary installer

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Information Dense Keywords Dictionary Installer Test${NC}"
echo "===================================================="
echo ""

# Change to parent directory to run tests from project root
cd "$(dirname "$0")/.."

# Test setup
TEST_DIR="test-temp"
CUSTOM_DIR="test-custom-docs"

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up test directories...${NC}"
    rm -rf "$TEST_DIR" "$CUSTOM_DIR" "test-clean-project" "test-docs"
    # Restore AI.md if the test modified it
    if [ -f "AI.md.test-backup" ]; then
        mv AI.md.test-backup AI.md
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT

echo "Test 1: Default installation to test-docs"
echo "-----------------------------------------"
rm -rf test-docs  # Clean any existing test-docs
./install.sh test-docs
if [ -f "test-docs/information-dense-keywords.md" ] && [ -d "test-docs/dictionary" ] && [ -f "AI.md" ]; then
    echo -e "${GREEN}✓ Test 1 passed: Default installation successful${NC}"
else
    echo -e "${RED}✗ Test 1 failed: Default installation failed${NC}"
    if [ ! -f "test-docs/information-dense-keywords.md" ]; then
        echo -e "${RED}  Missing: test-docs/information-dense-keywords.md${NC}"
    fi
    if [ ! -d "test-docs/dictionary" ]; then
        echo -e "${RED}  Missing: test-docs/dictionary${NC}"
    fi
    if [ ! -f "AI.md" ]; then
        echo -e "${RED}  Missing: AI.md in current directory${NC}"
    fi
    exit 1
fi

echo ""
echo "Test 2: Custom directory installation"
echo "------------------------------------"
mkdir -p "$TEST_DIR"
./install.sh "$TEST_DIR/my-docs"
if [ -f "$TEST_DIR/my-docs/information-dense-keywords.md" ] && [ -d "$TEST_DIR/my-docs/dictionary" ] && [ -f "AI.md" ]; then
    echo -e "${GREEN}✓ Test 2 passed: Custom directory installation successful${NC}"
else
    echo -e "${RED}✗ Test 2 failed: Custom directory installation failed${NC}"
    if [ ! -f "$TEST_DIR/my-docs/information-dense-keywords.md" ]; then
        echo -e "${RED}  Missing: $TEST_DIR/my-docs/information-dense-keywords.md${NC}"
    fi
    if [ ! -d "$TEST_DIR/my-docs/dictionary" ]; then
        echo -e "${RED}  Missing: $TEST_DIR/my-docs/dictionary${NC}"
    fi
    if [ ! -f "AI.md" ]; then
        echo -e "${RED}  Missing: AI.md in current directory${NC}"
    fi
    exit 1
fi

echo ""
echo "Test 3: Verify dictionary structure"
echo "----------------------------------"
EXPECTED_FILES=(
    "test-docs/dictionary/core/create.md"
    "test-docs/dictionary/core/delete.md"
    "test-docs/dictionary/core/fix.md"
    "test-docs/dictionary/core/select.md"
    "test-docs/dictionary/development/analyze-this.md"
    "test-docs/dictionary/development/debug-this.md"
    "test-docs/dictionary/development/optimize-this.md"
    "test-docs/dictionary/documentation/document-this.md"
    "test-docs/dictionary/documentation/explain-this.md"
    "test-docs/dictionary/documentation/research-this.md"
    "test-docs/dictionary/git/comment.md"
    "test-docs/dictionary/git/commit.md"
    "test-docs/dictionary/git/gh.md"
    "test-docs/dictionary/git/pr.md"
    "test-docs/dictionary/git/push.md"
    "test-docs/dictionary/quality-assurance/review-this.md"
    "test-docs/dictionary/quality-assurance/test-this.md"
    "test-docs/dictionary/workflow/plan-this.md"
    "test-docs/dictionary/workflow/spec-this.md"
)

ALL_PRESENT=true
for file in "${EXPECTED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}Missing: $file${NC}"
        ALL_PRESENT=false
    fi
done

if [ "$ALL_PRESENT" = true ]; then
    echo -e "${GREEN}✓ Test 3 passed: All dictionary files present${NC}"
else
    echo -e "${RED}✗ Test 3 failed: Some dictionary files missing${NC}"
    exit 1
fi

echo ""
echo "Test 4: Overwrite existing installation"
echo "--------------------------------------"
echo "test content" > "test-docs/information-dense-keywords.md"
./install.sh test-docs
if grep -q "# Information Dense Keywords Dictionary" "test-docs/information-dense-keywords.md"; then
    echo -e "${GREEN}✓ Test 4 passed: Overwrite successful${NC}"
else
    echo -e "${RED}✗ Test 4 failed: Overwrite failed${NC}"
    exit 1
fi

echo ""
echo "Test 5: Installation with spaces in path"
echo "---------------------------------------"
mkdir -p "$CUSTOM_DIR/my docs with spaces"
./install.sh "$CUSTOM_DIR/my docs with spaces"
if [ -f "$CUSTOM_DIR/my docs with spaces/information-dense-keywords.md" ] && [ -d "$CUSTOM_DIR/my docs with spaces/dictionary" ] && [ -f "AI.md" ]; then
    echo -e "${GREEN}✓ Test 5 passed: Installation with spaces in path successful${NC}"
else
    echo -e "${RED}✗ Test 5 failed: Installation with spaces in path failed${NC}"
    if [ ! -f "$CUSTOM_DIR/my docs with spaces/information-dense-keywords.md" ]; then
        echo -e "${RED}  Missing: $CUSTOM_DIR/my docs with spaces/information-dense-keywords.md${NC}"
    fi
    if [ ! -d "$CUSTOM_DIR/my docs with spaces/dictionary" ]; then
        echo -e "${RED}  Missing: $CUSTOM_DIR/my docs with spaces/dictionary${NC}"
    fi
    if [ ! -f "AI.md" ]; then
        echo -e "${RED}  Missing: AI.md in current directory${NC}"
    fi
    exit 1
fi

echo ""
echo "Test 6: AI.md content validation"
echo "--------------------------------"
if grep -q "# AI.md - Shared Instructions for All AI Assistants" AI.md && grep -q "Information Dense Keywords" AI.md; then
    echo -e "${GREEN}✓ Test 6 passed: AI.md content is valid${NC}"
else
    echo -e "${RED}✗ Test 6 failed: AI.md content is invalid${NC}"
    if ! grep -q "# AI.md - Shared Instructions for All AI Assistants" AI.md; then
        echo -e "${RED}  Missing: AI.md header${NC}"
    fi
    if ! grep -q "Information Dense Keywords" AI.md; then
        echo -e "${RED}  Missing: Information Dense Keywords content${NC}"
    fi
    exit 1
fi

echo ""
echo "Test 7: System directory protection"
echo "-----------------------------------"
if ./install.sh / 2>&1 | grep -q "Installation in system directory '/' is not allowed"; then
    echo -e "${GREEN}✓ Test 7 passed: System directory protection works${NC}"
else
    echo -e "${RED}✗ Test 7 failed: System directory protection failed${NC}"
    exit 1
fi

echo ""
echo "Test 8: Top-level directory installation"
echo "----------------------------------------"
mkdir -p "$CUSTOM_DIR/my-project"
./install.sh "$CUSTOM_DIR/my-project"
if [ -f "$CUSTOM_DIR/my-project/information-dense-keywords.md" ] && [ -d "$CUSTOM_DIR/my-project/dictionary" ] && [ -f "AI.md" ]; then
    echo -e "${GREEN}✓ Test 8 passed: Top-level directory installation successful${NC}"
else
    echo -e "${RED}✗ Test 8 failed: Top-level directory installation failed${NC}"
    if [ ! -f "$CUSTOM_DIR/my-project/information-dense-keywords.md" ]; then
        echo -e "${RED}  Missing: $CUSTOM_DIR/my-project/information-dense-keywords.md${NC}"
    fi
    if [ ! -d "$CUSTOM_DIR/my-project/dictionary" ]; then
        echo -e "${RED}  Missing: $CUSTOM_DIR/my-project/dictionary${NC}"
    fi
    if [ ! -f "AI.md" ]; then
        echo -e "${RED}  Missing: AI.md in current directory${NC}"
    fi
    exit 1
fi

echo ""
echo "Test 9: AI.md copying when missing from installation directory"
echo "----------------------------------------------------"
# Test in a clean subdirectory where AI.md doesn't exist in project root
mkdir -p test-clean-project
cd test-clean-project
rm -rf test-docs  # Clean any existing test-docs
# Copy necessary files from parent directory (including AI.md as the package source)
cp ../information-dense-keywords.md .
cp -r ../dictionary .
cp ../AI.md .
cp ../install.sh .
# Note: AI.md exists in current directory (package) but not in installation directory
# Since we're in test-clean-project, there's no AI.md in the installation directory initially
./install.sh test-docs
if [ -f "test-docs/information-dense-keywords.md" ] && [ -d "test-docs/dictionary" ] && [ -f "test-docs/AI.md" ]; then
    echo -e "${GREEN}✓ Test 9 passed: AI.md copied to installation directory successfully${NC}"
else
    echo -e "${RED}✗ Test 9 failed: AI.md copying failed${NC}"
    if [ ! -f "test-docs/information-dense-keywords.md" ]; then
        echo -e "${RED}  Missing: test-docs/information-dense-keywords.md${NC}"
    fi
    if [ ! -d "test-docs/dictionary" ]; then
        echo -e "${RED}  Missing: test-docs/dictionary${NC}"
    fi
    if [ ! -f "test-docs/AI.md" ]; then
        echo -e "${RED}  Missing: test-docs/AI.md in installation directory${NC}"
    fi
    cd ..
    exit 1
fi
# Return to parent directory
cd ..

echo ""
echo "Test 10: Installer does not overwrite existing custom AI.md"
echo "----------------------------------------------------------"
# Backup existing AI.md
cp AI.md AI.md.test-backup

# Setup: Create a custom AI.md with unique content
CUSTOM_CONTENT="This is a custom AI.md file that should not be overwritten."
echo "$CUSTOM_CONTENT" > AI.md
rm -rf test-docs  # Clean any existing test-docs

# Run installer to test-docs
./install.sh test-docs > /dev/null 2>&1  # Suppress output for clean test log

# Verify
if grep -q "$CUSTOM_CONTENT" AI.md; then
    echo -e "${GREEN}✓ Test 10 passed: Custom AI.md was preserved${NC}"
else
    echo -e "${RED}✗ Test 10 failed: Custom AI.md was overwritten!${NC}"
    # Restore backup before exiting
    mv AI.md.test-backup AI.md
    exit 1
fi

# Restore original AI.md
mv AI.md.test-backup AI.md

echo ""
echo -e "${GREEN}All tests passed!${NC}"
echo ""
echo "Summary:"
echo "- Default installation to test-docs: ✓"
echo "- Custom directory: ✓"
echo "- File structure: ✓"
echo "- Overwrite: ✓"
echo "- Spaces in path: ✓"
echo "- AI.md content: ✓"
echo "- System directory protection: ✓"
echo "- Top-level directory installation: ✓"
echo "- AI.md copying when missing: ✓"
echo "- AI.md preservation when existing: ✓"

# Cleanup test directories (docs stays for user)
rm -rf "$TEST_DIR" "$CUSTOM_DIR"
