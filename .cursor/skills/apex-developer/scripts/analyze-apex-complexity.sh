#!/bin/bash

# Apex Code Complexity Analyzer
# Uses PMD to analyze Apex code complexity and identify potential issues

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Configuration
PMD_VERSION="7.0.0"
PMD_DIR="$HOME/.pmd"
PMD_BIN="$PMD_DIR/pmd-bin-${PMD_VERSION}/bin/pmd"
RULESET="category/apex/design.xml,category/apex/bestpractices.xml,category/apex/performance.xml,category/apex/security.xml"

echo "================================================"
echo "  Salesforce Apex Complexity Analyzer"
echo "================================================"
echo ""

# Function to download PMD if not exists
install_pmd() {
    if [ ! -f "$PMD_BIN" ]; then
        echo "PMD not found. Installing PMD ${PMD_VERSION}..."
        mkdir -p "$PMD_DIR"
        cd "$PMD_DIR"

        # Download PMD
        echo "Downloading PMD..."
        curl -L "https://github.com/pmd/pmd/releases/download/pmd_releases%2F${PMD_VERSION}/pmd-dist-${PMD_VERSION}-bin.zip" -o pmd.zip

        # Extract
        echo "Extracting PMD..."
        unzip -q pmd.zip
        rm pmd.zip

        echo -e "${GREEN}PMD installed successfully${NC}"
        cd - > /dev/null
    fi
}

# Check if directory provided
if [ -z "$1" ]; then
    # Default to force-app if exists, otherwise current directory
    if [ -d "force-app" ]; then
        TARGET_DIR="force-app"
    else
        TARGET_DIR="."
    fi
else
    TARGET_DIR="$1"
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Directory '$TARGET_DIR' not found${NC}"
    exit 1
fi

echo "Analyzing Apex code in: $TARGET_DIR"
echo ""

# Install PMD if needed
install_pmd

# Run PMD analysis
echo "Running complexity analysis..."
echo ""

# Create temp output file
TEMP_OUTPUT=$(mktemp)

# Run PMD with specific rulesets
"$PMD_BIN" check \
    -d "$TARGET_DIR" \
    -R "$RULESET" \
    -f text \
    --cache "$PMD_DIR/.pmd-cache" \
    --short-names \
    > "$TEMP_OUTPUT" 2>&1 || true

# Parse and display results
if [ -s "$TEMP_OUTPUT" ]; then
    echo -e "${YELLOW}=== Issues Found ===${NC}"
    echo ""

    # Count issues by severity
    VIOLATIONS=$(grep -c ":" "$TEMP_OUTPUT" || true)

    if [ "$VIOLATIONS" -gt 0 ]; then
        cat "$TEMP_OUTPUT"
        echo ""
        echo -e "${YELLOW}Total violations found: ${VIOLATIONS}${NC}"
        echo ""

        # Categorize issues
        COMPLEXITY=$(grep -i "complexity\|cyclomatic" "$TEMP_OUTPUT" | wc -l || true)
        SECURITY=$(grep -i "security\|sanitize\|soql injection" "$TEMP_OUTPUT" | wc -l || true)
        PERFORMANCE=$(grep -i "avoid\|loop\|optimize" "$TEMP_OUTPUT" | wc -l || true)

        echo "Breakdown:"
        echo "  - Complexity issues: $COMPLEXITY"
        echo "  - Security issues: $SECURITY"
        echo "  - Performance issues: $PERFORMANCE"
        echo ""

        # Provide recommendations
        if [ "$COMPLEXITY" -gt 0 ]; then
            echo -e "${YELLOW}Recommendation:${NC} Consider refactoring complex methods into smaller units"
        fi
        if [ "$SECURITY" -gt 0 ]; then
            echo -e "${RED}Recommendation:${NC} Review security issues immediately - use WITH SECURITY_ENFORCED or Security.stripInaccessible()"
        fi
        if [ "$PERFORMANCE" -gt 0 ]; then
            echo -e "${YELLOW}Recommendation:${NC} Review performance issues - avoid SOQL/DML in loops"
        fi
    else
        echo -e "${GREEN}No violations found!${NC}"
    fi
else
    echo -e "${GREEN}✓ No issues found! Code looks clean.${NC}"
fi

# Cleanup
rm "$TEMP_OUTPUT"

echo ""
echo "================================================"
echo "  Analysis Complete"
echo "================================================"

# Additional metrics using cloc if available
if command -v cloc &> /dev/null; then
    echo ""
    echo "Code Statistics:"
    cloc --quiet --include-lang="Visualforce,Apex" "$TARGET_DIR" 2>/dev/null || true
fi

# Check for common Salesforce anti-patterns
echo ""
echo "Checking for common anti-patterns..."
echo ""

FOUND_ISSUES=0

# Check for SOQL in loops
if grep -r "for.*{" "$TARGET_DIR" --include="*.cls" --include="*.trigger" | grep -q "SELECT.*FROM"; then
    echo -e "${RED}⚠ Potential SOQL in loops detected${NC}"
    FOUND_ISSUES=1
fi

# Check for DML in loops
if grep -r "for.*{" "$TARGET_DIR" --include="*.cls" --include="*.trigger" | grep -qE "(insert|update|delete|upsert) "; then
    echo -e "${RED}⚠ Potential DML in loops detected${NC}"
    FOUND_ISSUES=1
fi

# Check for hardcoded IDs
if grep -rE "['\"]00[A-Za-z0-9]{15}['\"]|['\"]00[A-Za-z0-9]{18}['\"]" "$TARGET_DIR" --include="*.cls" --include="*.trigger" | grep -v "@isTest" > /dev/null; then
    echo -e "${YELLOW}⚠ Hardcoded Salesforce IDs found (not in test classes)${NC}"
    FOUND_ISSUES=1
fi

# Check for System.debug in non-test classes
DEBUG_COUNT=$(grep -r "System.debug" "$TARGET_DIR" --include="*.cls" | grep -v "@isTest" | wc -l || true)
if [ "$DEBUG_COUNT" -gt 10 ]; then
    echo -e "${YELLOW}⚠ High number of System.debug statements ($DEBUG_COUNT) - consider removing before deployment${NC}"
    FOUND_ISSUES=1
fi

if [ "$FOUND_ISSUES" -eq 0 ]; then
    echo -e "${GREEN}✓ No common anti-patterns detected${NC}"
fi

echo ""

# Test coverage check if sfdx is available
if command -v sf &> /dev/null; then
    echo "To check test coverage, run:"
    echo "  sf apex run test --test-level RunLocalTests --code-coverage --result-format human"
fi

exit 0
