#!/bin/bash

# Verify Cursor Commands Integration
# This script checks that all required files are in place

echo "🔍 Verifying Cursor Commands Integration..."
echo "═══════════════════════════════════════════════════════════════"
echo ""

EXIT_CODE=0

# Check 1: commands.json exists
echo "✓ Checking: .cursor/skills/_templates/commands.json"
if [ -f ".cursor/skills/_templates/commands.json" ]; then
    echo "  ✅ Found"
    # Validate JSON syntax
    if node -e "require('./.cursor/skills/_templates/commands.json')" 2>/dev/null; then
        echo "  ✅ Valid JSON"
    else
        echo "  ❌ Invalid JSON syntax"
        EXIT_CODE=1
    fi
else
    echo "  ❌ Missing"
    EXIT_CODE=1
fi
echo ""

# Check 2: settings.json exists
echo "✓ Checking: .vscode/settings.json"
if [ -f ".vscode/settings.json" ]; then
    echo "  ✅ Found"
    # Validate JSON syntax
    if node -e "require('./.vscode/settings.json')" 2>/dev/null; then
        echo "  ✅ Valid JSON"
    else
        echo "  ❌ Invalid JSON syntax"
        EXIT_CODE=1
    fi
else
    echo "  ❌ Missing"
    EXIT_CODE=1
fi
echo ""

# Check 3: keybindings.json exists
echo "✓ Checking: .vscode/keybindings.json"
if [ -f ".vscode/keybindings.json" ]; then
    echo "  ✅ Found (optional)"
    # Validate JSON syntax
    if node -e "require('./.vscode/keybindings.json')" 2>/dev/null; then
        echo "  ✅ Valid JSON"
    else
        echo "  ❌ Invalid JSON syntax"
        EXIT_CODE=1
    fi
else
    echo "  ⚠️  Missing (optional - keyboard shortcuts won't work)"
fi
echo ""

# Check 4: README.md updated
echo "✓ Checking: .cursor/skills/_templates/README.md"
if [ -f ".cursor/skills/_templates/README.md" ]; then
    echo "  ✅ Found"
    if grep -q "Using Cursor Commands" ".cursor/skills/_templates/README.md"; then
        echo "  ✅ Contains Cursor Commands section"
    else
        echo "  ⚠️  Missing Cursor Commands section"
    fi
else
    echo "  ❌ Missing"
    EXIT_CODE=1
fi
echo ""

# Check 5: Root README.md updated
echo "✓ Checking: README.md"
if [ -f "README.md" ]; then
    echo "  ✅ Found"
    if grep -q "Skill Builder System" "README.md"; then
        echo "  ✅ Contains Skill Builder section"
    else
        echo "  ⚠️  Missing Skill Builder section"
    fi
else
    echo "  ❌ Missing"
    EXIT_CODE=1
fi
echo ""

# Check 6: builder.js exists
echo "✓ Checking: .cursor/skills/_templates/builder.js"
if [ -f ".cursor/skills/_templates/builder.js" ]; then
    echo "  ✅ Found"
    if [ -x ".cursor/skills/_templates/builder.js" ]; then
        echo "  ✅ Executable"
    fi
else
    echo "  ❌ Missing"
    EXIT_CODE=1
fi
echo ""

# Check 7: Node.js dependencies
echo "✓ Checking: Node.js dependencies"
if [ -f ".cursor/skills/_templates/package.json" ]; then
    echo "  ✅ package.json found"
    cd .cursor/skills/_templates
    if [ -d "node_modules" ]; then
        echo "  ✅ node_modules exists"
    else
        echo "  ⚠️  node_modules not found - run 'npm install'"
    fi
    cd - > /dev/null
else
    echo "  ❌ package.json missing"
    EXIT_CODE=1
fi
echo ""

# Summary
echo "═══════════════════════════════════════════════════════════════"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ All checks passed!"
    echo ""
    echo "Next steps:"
    echo "  1. Reload Cursor IDE window (Cmd+Shift+P → 'Reload Window')"
    echo "  2. Press Cmd+Shift+P and type 'Skill Builder'"
    echo "  3. You should see three commands available"
    echo ""
    echo "Commands available:"
    echo "  • Skill Builder: Generate from JSON"
    echo "  • Skill Builder: Generate from NotebookLM"
    echo "  • Skill Builder: Generate from PDFs"
    echo ""
    echo "Documentation:"
    echo "  • Usage guide: .cursor/skills/_templates/README.md"
    echo "  • Implementation details: .cursor/skills/_templates/CURSOR_COMMANDS_INTEGRATION.md"
else
    echo "❌ Some checks failed - review errors above"
    echo ""
    echo "Common solutions:"
    echo "  • Run from project root directory"
    echo "  • Ensure all files were created correctly"
    echo "  • Check JSON syntax for errors"
    echo "  • Run 'npm install' in .cursor/skills/_templates/"
fi
echo "═══════════════════════════════════════════════════════════════"

exit $EXIT_CODE
