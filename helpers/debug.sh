#!/usr/bin/env bash
# Test script to debug pkg_aliases.bash loading

echo "=== Testing pkg_aliases.bash loading ==="
echo "Shell interactive status: $-"
echo ""

# Test 1: Check file exists
if [ -f ~/.dotfiles/.bashrc.d/pkg_aliases.bash ]; then
    echo "✓ File exists"
else
    echo "✗ File NOT found"
    exit 1
fi

# Test 2: Check first 20 lines
echo ""
echo "=== First 20 lines of file ==="
head -20 ~/.dotfiles/.bashrc.d/pkg_aliases.bash
echo ""

# Test 3: Look for guards
echo "=== Checking for guards ==="
grep -n "^\[\[.*\]\].*return" ~/.dotfiles/.bashrc.d/pkg_aliases.bash || echo "No guards found"
echo ""

# Test 4: Source the file
echo "=== Sourcing file ==="
source ~/.dotfiles/.bashrc.d/pkg_aliases.bash
echo "Source completed (exit code: $?)"
echo ""

# Test 5: Check if function exists
echo "=== Checking for set_package_aliases function ==="
if declare -f set_package_aliases >/dev/null 2>&1; then
    echo "✓ set_package_aliases function EXISTS"
else
    echo "✗ set_package_aliases function NOT FOUND"
fi
echo ""

# Test 6: List all functions from the file
echo "=== Functions defined ==="
declare -F | grep -E "(set_package|p_install|p_remove|command_check)"
echo ""

# Test 7: Try calling the function
echo "=== Calling set_package_aliases ==="
if declare -f set_package_aliases >/dev/null 2>&1; then
    DEBUG=1 set_package_aliases
    echo ""
    echo "=== Checking for p_install after calling set_package_aliases ==="
    if declare -f p_install >/dev/null 2>&1; then
        echo "✓ p_install function EXISTS"
    else
        echo "✗ p_install function NOT FOUND"
    fi
else
    echo "✗ Cannot call set_package_aliases (not defined)"
fi  