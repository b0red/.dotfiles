#!/usr/bin/env bash
# =============================================================================
# diagnose-dotfiles.sh - Check current state of dotfiles
# =============================================================================

DOTFILES_DIR="$HOME/dotfiles/.bashrc.d"

echo "========================================"
echo "Dotfiles Diagnostic Report"
echo "========================================"
echo ""

# Check which files exist
echo "=== Files in .bashrc.d/ ==="
ls -1 "$DOTFILES_DIR"/*.bash 2>/dev/null | while read -r file; do
    basename "$file"
done
echo ""

# Check for guards in each file
echo "=== Guard Status ==="
for file in exports.bash env.bash functions.bash pkg_aliases.bash git.bash docker.bash aliases.bash variables.bash profile.bash logout.bash colorcodes.bash; do
    filepath="$DOTFILES_DIR/$file"
    if [ -f "$filepath" ]; then
        if grep -q "^\[\[ \$- == \*i\* \]\] || return 0" "$filepath" 2>/dev/null; then
            echo "✓ $file - HAS GUARD (interactive only)"
        else
            echo "○ $file - NO GUARD (loads everywhere)"
        fi
    else
        echo "✗ $file - FILE NOT FOUND"
    fi
done
echo ""

# Check for Docker installation check in docker.bash
echo "=== Docker.bash Special Checks ==="
if [ -f "$DOTFILES_DIR/docker.bash" ]; then
    if grep -q "command -v docker" "$DOTFILES_DIR/docker.bash" 2>/dev/null; then
        echo "✓ docker.bash has Docker installation check"
    else
        echo "✗ docker.bash missing Docker installation check"
    fi
else
    echo "✗ docker.bash not found"
fi
echo ""

# Check current shell state
echo "=== Current Shell State ==="
echo "Interactive: $-"
echo "DISTROBASE: ${DISTROBASE:-NOT SET}"
echo "EDITOR: ${EDITOR:-NOT SET}"
echo ""

# Check if functions exist
echo "=== Package Functions ==="
if declare -f p_install >/dev/null 2>&1; then
    echo "✓ p_install function EXISTS"
else
    echo "✗ p_install function NOT FOUND"
fi

if declare -f set_package_aliases >/dev/null 2>&1; then
    echo "✓ set_package_aliases function EXISTS"
else
    echo "✗ set_package_aliases function NOT FOUND"
fi
echo ""

# Check if aliases exist (only in interactive)
if [[ $- == *i* ]]; then
    echo "=== Aliases (Interactive Mode) ==="
    if alias install 2>/dev/null | grep -q "p_install"; then
        echo "✓ install alias EXISTS"
    else
        echo "✗ install alias NOT FOUND"
    fi
    
    if alias ll 2>/dev/null >/dev/null; then
        echo "✓ ll alias EXISTS"
    else
        echo "✗ ll alias NOT FOUND"
    fi
    
    if alias gs 2>/dev/null >/dev/null; then
        echo "✓ gs alias EXISTS (git)"
    else
        echo "✗ gs alias NOT FOUND (git)"
    fi
else
    echo "=== Skipping Alias Checks (non-interactive) ==="
fi
echo ""

# Check shopt settings
echo "=== Shell Options ==="
if shopt histappend 2>/dev/null | grep -q "on"; then
    echo "✓ histappend is ON"
else
    echo "✗ histappend is OFF or not set"
fi
echo ""

# Check for problematic lines
echo "=== Checking for Common Issues ==="

# Check if any core files have guards they shouldn't
for file in exports.bash env.bash pkg_aliases.bash; do
    if [ -f "$DOTFILES_DIR/$file" ]; then
        if grep -q "^\[\[ \$- == \*i\* \]\] || return 0" "$DOTFILES_DIR/$file" 2>/dev/null; then
            echo "⚠️  WARNING: $file has guard (should NOT have guard)"
        fi
    fi
done

# Check if docker.bash has guard BEFORE Docker check
if [ -f "$DOTFILES_DIR/docker.bash" ]; then
    # Get line numbers
    docker_check_line=$(grep -n "command -v docker" "$DOTFILES_DIR/docker.bash" 2>/dev/null | head -1 | cut -d: -f1)
    guard_line=$(grep -n "^\[\[ \$- == \*i\* \]\] || return 0" "$DOTFILES_DIR/docker.bash" 2>/dev/null | head -1 | cut -d: -f1)
    
    if [ -n "$docker_check_line" ] && [ -n "$guard_line" ]; then
        if [ "$docker_check_line" -gt "$guard_line" ]; then
            echo "⚠️  WARNING: docker.bash guard BEFORE Docker check (should be AFTER)"
        else
            echo "✓ docker.bash: Docker check before guard (correct order)"
        fi
    fi
fi

echo ""
echo "========================================"
echo "Diagnostic Complete"
echo "========================================"