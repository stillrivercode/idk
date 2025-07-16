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

# Test setup
TEST_DIR="test-temp"
CUSTOM_DIR="test-custom-docs"

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up test directories...${NC}"
    rm -rf "$TEST_DIR" "$CUSTOM_DIR"
    # Note: We keep AI.md in the project root as it's part of the installation
}

# Set trap to cleanup on exit
trap cleanup EXIT

echo "Test 1: Default installation to ./docs"
echo "--------------------------------------"
rm -rf docs  # Clean any existing docs
rm -f AI.md  # Clean any existing AI.md
./install.sh
if [ -f "docs/information-dense-keywords.md" ] && [ -d "docs/dictionary" ] && [ -f "AI.md" ]; then
    echo -e "${GREEN}✓ Test 1 passed: Default installation successful${NC}"
else
    echo -e "${RED}✗ Test 1 failed: Default installation failed${NC}"
    if [ ! -f "docs/information-dense-keywords.md" ]; then
        echo -e "${RED}  Missing: docs/information-dense-keywords.md${NC}"
    fi
    if [ ! -d "docs/dictionary" ]; then
        echo -e "${RED}  Missing: docs/dictionary${NC}"
    fi
    if [ ! -f "AI.md" ]; then
        echo -e "${RED}  Missing: AI.md in project root${NC}"
    fi
    exit 1
fi

echo ""
echo "Test 2: Custom directory installation"
echo "------------------------------------"
mkdir -p "$TEST_DIR"
rm -f "$TEST_DIR/AI.md"  # Clean any existing AI.md
./install.sh "$TEST_DIR/my-docs"
if [ -f "$TEST_DIR/my-docs/information-dense-keywords.md" ] && [ -d "$TEST_DIR/my-docs/dictionary" ] && [ -f "$TEST_DIR/AI.md" ]; then
    echo -e "${GREEN}✓ Test 2 passed: Custom directory installation successful${NC}"
else
    echo -e "${RED}✗ Test 2 failed: Custom directory installation failed${NC}"
    if [ ! -f "$TEST_DIR/my-docs/information-dense-keywords.md" ]; then
        echo -e "${RED}  Missing: $TEST_DIR/my-docs/information-dense-keywords.md${NC}"
    fi
    if [ ! -d "$TEST_DIR/my-docs/dictionary" ]; then
        echo -e "${RED}  Missing: $TEST_DIR/my-docs/dictionary${NC}"
    fi
    if [ ! -f "$TEST_DIR/AI.md" ]; then
        echo -e "${RED}  Missing: $TEST_DIR/AI.md in project root${NC}"
    fi
    exit 1
fi

echo ""
echo "Test 3: Verify dictionary structure"
echo "----------------------------------"
EXPECTED_FILES=(
    "docs/dictionary/core/create.md"
    "docs/dictionary/core/delete.md"
    "docs/dictionary/core/fix.md"
    "docs/dictionary/core/select.md"
    "docs/dictionary/development/analyze-this.md"
    "docs/dictionary/development/debug-this.md"
    "docs/dictionary/development/optimize-this.md"
    "docs/dictionary/documentation/document-this.md"
    "docs/dictionary/documentation/explain-this.md"
    "docs/dictionary/documentation/research-this.md"
    "docs/dictionary/git/comment.md"
    "docs/dictionary/git/commit.md"
    "docs/dictionary/git/gh.md"
    "docs/dictionary/git/pr.md"
    "docs/dictionary/git/push.md"
    "docs/dictionary/quality-assurance/review-this.md"
    "docs/dictionary/quality-assurance/test-this.md"
    "docs/dictionary/workflow/plan-this.md"
    "docs/dictionary/workflow/spec-this.md"
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
echo "test content" > "docs/information-dense-keywords.md"
./install.sh
if grep -q "# Information Dense Keywords Dictionary" "docs/information-dense-keywords.md"; then
    echo -e "${GREEN}✓ Test 4 passed: Overwrite successful${NC}"
else
    echo -e "${RED}✗ Test 4 failed: Overwrite failed${NC}"
    exit 1
fi

echo ""
echo "Test 5: Installation with spaces in path"
echo "---------------------------------------"
mkdir -p "$CUSTOM_DIR/my docs with spaces"
rm -f "$CUSTOM_DIR/AI.md"  # Clean any existing AI.md
./install.sh "$CUSTOM_DIR/my docs with spaces"
if [ -f "$CUSTOM_DIR/my docs with spaces/information-dense-keywords.md" ] && [ -d "$CUSTOM_DIR/my docs with spaces/dictionary" ] && [ -f "$CUSTOM_DIR/AI.md" ]; then
    echo -e "${GREEN}✓ Test 5 passed: Installation with spaces in path successful${NC}"
else
    echo -e "${RED}✗ Test 5 failed: Installation with spaces in path failed${NC}"
    if [ ! -f "$CUSTOM_DIR/my docs with spaces/information-dense-keywords.md" ]; then
        echo -e "${RED}  Missing: $CUSTOM_DIR/my docs with spaces/information-dense-keywords.md${NC}"
    fi
    if [ ! -d "$CUSTOM_DIR/my docs with spaces/dictionary" ]; then
        echo -e "${RED}  Missing: $CUSTOM_DIR/my docs with spaces/dictionary${NC}"
    fi
    if [ ! -f "$CUSTOM_DIR/AI.md" ]; then
        echo -e "${RED}  Missing: $CUSTOM_DIR/AI.md in project root${NC}"
    fi
    exit 1
fi

echo ""
echo "Test 6: AI.md content validation"
echo "--------------------------------"
if grep -q "# AI.md - Shared Instructions for All AI Assistants" AI.md; then
    echo -e "${GREEN}✓ Test 6 passed: AI.md content is valid${NC}"
else
    echo -e "${RED}✗ Test 6 failed: AI.md content is invalid${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}All tests passed!${NC}"
echo ""
echo "Summary:"
echo "- Default installation: ✓"
echo "- Custom directory: ✓"
echo "- File structure: ✓"
echo "- Overwrite: ✓"
echo "- Spaces in path: ✓"
echo "- AI.md content: ✓"

# Cleanup test directories (docs stays for user)
rm -rf "$TEST_DIR" "$CUSTOM_DIR"
