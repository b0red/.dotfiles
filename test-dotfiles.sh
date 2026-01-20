#!/usr/bin/env bash
# =============================================================================
# test-dotfiles.sh - Verify dotfiles implementation
# =============================================================================
# Purpose: Test that all changes are working correctly
# Usage: bash test-dotfiles.sh
# =============================================================================

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_check() {
    local test_name="$1"
    local test_cmd="$2"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo "========================================"
echo "Dotfiles Implementation Test Suite"
echo "========================================"
echo ""

# =============================================================================
# Test 1: Core Files Loaded
# =============================================================================
echo "=== Testing Core Files ==="

test_check "exports.bash loaded" \
    "[ -n \"\$EDITOR\" ]"

test_check "env.bash loaded (shopt)" \
    "shopt -q histappend 2>/dev/null || shopt histappend 2>/dev/null | grep -q on"

test_check "pkg_aliases.bash loaded" \
    "declare -f p_install >/dev/null 2>&1"

echo ""

# =============================================================================
# Test 2: Package Functions
# =============================================================================
echo "=== Testing Package Functions ==="

test_check "p_install function exists" \
    "declare -f p_install >/dev/null 2>&1"

test_check "p_update function exists" \
    "declare -f p_update >/dev/null 2>&1"

test_check "p_remove function exists" \
    "declare -f p_remove >/dev/null 2>&1"

test_check "DISTROBASE variable set" \
    "[ -n \"\$DISTROBASE\" ]"

echo ""

# =============================================================================
# Test 3: Interactive Aliases (only if interactive)
# =============================================================================
if [[ $- == *i* ]]; then
    echo "=== Testing Interactive Aliases ==="
    
    test_check "install alias exists" \
        "alias install >/dev/null 2>&1"
    
    test_check "update alias exists" \
        "alias update >/dev/null 2>&1"
    
    test_check "ll alias exists" \
        "alias ll >/dev/null 2>&1"
    
    echo ""
else
    echo "=== Skipping Alias Tests (non-interactive) ==="
    echo ""
fi

# =============================================================================
# Test 4: Git Shortcuts (only if interactive)
# =============================================================================
if [[ $- == *i* ]]; then
    echo "=== Testing Git Shortcuts ==="
    
    test_check "gs alias exists" \
        "alias gs >/dev/null 2>&1"
    
    test_check "gcom function exists" \
        "declare -f gcom >/dev/null 2>&1"
    
    echo ""
else
    echo "=== Skipping Git Tests (non-interactive) ==="
    echo ""
fi

# =============================================================================
# Test 5: Docker Integration (only if Docker installed)
# =============================================================================
if command -v docker >/dev/null 2>&1; then
    if [[ $- == *i* ]]; then
        echo "=== Testing Docker Integration ==="
        
        test_check "dps alias exists" \
            "alias dps >/dev/null 2>&1"
        
        test_check "dkln function exists" \
            "declare -f dkln >/dev/null 2>&1"
        
        echo ""
    else
        echo "=== Skipping Docker Tests (non-interactive) ==="
        echo ""
    fi
else
    echo "=== Docker Not Installed (Expected) ==="
    echo "✓ docker.bash should NOT load"
    echo ""
fi

# =============================================================================
# Test 6: Function Exports (for scripts)
# =============================================================================
echo "=== Testing Function Exports ==="

test_check "p_install exported" \
    "bash -c 'declare -F p_install' >/dev/null 2>&1"

test_check "set_package_aliases exported" \
    "bash -c 'declare -F set_package_aliases' >/dev/null 2>&1"

echo ""

# =============================================================================
# Test 7: File Guards Working
# =============================================================================
echo "=== Testing File Guards ==="

# Test that interactive files DON'T load in non-interactive mode
test_check "aliases.bash guard works" \
    "! bash -c 'source ~/dotfiles/.bashrc.d/aliases.bash && alias ll' 2>/dev/null"

test_check "git.bash guard works" \
    "! bash -c 'source ~/dotfiles/.bashrc.d/git.bash && alias gs' 2>/dev/null"

# Test that core files DO load in non-interactive mode
test_check "pkg_aliases.bash NO guard" \
    "bash -c 'source ~/dotfiles/.bashrc.d/pkg_aliases.bash && declare -f p_install' >/dev/null 2>&1"

echo ""

# =============================================================================
# Test 8: Loading Feedback Configuration
# =============================================================================
echo "=== Testing Loading Configuration ==="

test_check "BASHRC_LOAD_DELAY set" \
    "[ -n \"\${BASHRC_LOAD_DELAY:-}\" ]"

test_check "show_loading function exists" \
    "declare -f show_loading >/dev/null 2>&1"

echo ""

# =============================================================================
# Test 9: Distro Detection
# =============================================================================
echo "=== Testing Distro Detection ==="

echo -n "Detected distro: "
if [ -n "${DISTROBASE:-}" ]; then
    echo -e "${GREEN}$DISTROBASE${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}NOT DETECTED${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""

# =============================================================================
# Results
# =============================================================================
echo "========================================"
echo "Test Results"
echo "========================================"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "Your dotfiles are correctly configured:"
    echo "  ✓ Core files load in all contexts"
    echo "  ✓ Interactive files guarded properly"
    echo "  ✓ Package functions exported"
    echo "  ✓ Docker integration conditional"
    echo "  ✓ Distro detection working"
    exit 0
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    echo ""
    echo "Please check:"
    echo "  1. All files updated with artifact content"
    echo "  2. Guards removed from core files"
    echo "  3. Guards kept in interactive files"
    echo "  4. Functions exported in pkg_aliases.bash"
    exit 1
fi