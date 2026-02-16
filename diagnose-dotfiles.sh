#!/bin/bash
# Diagnostic script to check tmux environment loading

echo "======================================"
echo "TMUX Environment Diagnostic"
echo "======================================"
echo ""

echo "1. Current Shell State:"
echo "   TMUX: ${TMUX:-[not set]}"
echo "   BASHRC_SKIP_IN_TMUX: ${BASHRC_SKIP_IN_TMUX:-[not set]}"
echo "   BASHRC_FORCE_LOAD: ${BASHRC_FORCE_LOAD:-[not set]}"
echo "   Interactive: $-"
echo ""

echo "2. Critical Exports Check:"
echo "   EDITOR: ${EDITOR:-[NOT SET]}"
echo "   HISTSIZE: ${HISTSIZE:-[NOT SET]}"
echo "   DOTFILES_DIR: ${DOTFILES_DIR:-[NOT SET]}"
echo "   PATH has go/bin: $(echo $PATH | grep -q 'go/bin' && echo 'YES' || echo 'NO')"
echo ""

echo "3. Function Check:"
if declare -f p_install >/dev/null 2>&1; then
    echo "   ✓ p_install function EXISTS"
else
    echo "   ✗ p_install function MISSING"
fi
if declare -f gacp >/dev/null 2>&1; then
    echo "   ✓ gacp function EXISTS (git)"
else
    echo "   ✗ gacp function MISSING (git)"
fi
echo ""

echo "4. Alias Check:"
if alias ll 2>/dev/null >/dev/null; then
    echo "   ✓ ll alias EXISTS"
else
    echo "   ✗ ll alias MISSING"
fi
if alias gs 2>/dev/null >/dev/null; then
    echo "   ✓ gs alias EXISTS (git)"
else
    echo "   ✗ gs alias MISSING (git)"
fi
echo ""

echo "5. Check exports.bash file:"
if [ -f ~/dotfiles/.bashrc.d/exports.bash ]; then
    echo "   File exists: YES"
    echo "   First 3 lines:"
    head -3 ~/dotfiles/.bashrc.d/exports.bash | sed 's/^/      /'
    echo ""
    if head -10 ~/dotfiles/.bashrc.d/exports.bash | grep -q "PROMPT SETUP"; then
        echo "   ⚠️  WARNING: exports.bash contains PROMPT SETUP (WRONG FILE!)"
        echo "   This means exports.bash is still a copy of .bashrc!"
    else
        echo "   ✓ exports.bash looks correct (no prompt setup)"
    fi
else
    echo "   ✗ File NOT FOUND"
fi
echo ""

echo "6. Prompt Check:"
echo "   PS1 set: $([ -n "$PS1" ] && echo 'YES' || echo 'NO')"
echo ""

echo "======================================"
echo "Run this script in different contexts:"
echo "  1. In initial terminal (before tmux)"
echo "  2. In tmux pane"
echo "  3. After running 'reload'"
echo "======================================"
