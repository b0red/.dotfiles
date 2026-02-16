#!/bin/bash
# Enhanced diagnostic - run this with: source diagnose_enhanced.sh

echo "======================================"
echo "Enhanced TMUX Environment Diagnostic"
echo "======================================"
echo ""

echo "1. Shell Type Detection:"
if [[ $- == *i* ]]; then
    echo "   ✓ INTERACTIVE shell (contains 'i')"
else
    echo "   ⚠️  NON-INTERACTIVE shell (no 'i')"
    echo "   This is why aliases/functions might not show!"
    echo "   TIP: Run this IN your shell, don't execute as script:"
    echo "        source diagnose_enhanced.sh"
fi
echo "   Full \$- flags: $-"
echo ""

echo "2. TMUX State:"
if [ -n "$TMUX" ]; then
    echo "   ✓ Inside TMUX"
    echo "   Session: $TMUX"
else
    echo "   ○ Not in TMUX"
fi
echo "   BASHRC_SKIP_IN_TMUX: ${BASHRC_SKIP_IN_TMUX:-[not set]}"
echo ""

echo "3. Critical Exports:"
echo "   EDITOR: ${EDITOR:-[NOT SET]}"
echo "   HISTSIZE: ${HISTSIZE:-[NOT SET]}"
echo "   DOTFILES_DIR: ${DOTFILES_DIR:-[NOT SET]}"
echo "   PATH has go/bin: $(echo $PATH | grep -q 'go/bin' && echo 'YES' || echo 'NO')"
echo ""

echo "4. Functions:"
for func in p_install gacp gcom up mcd; do
    if declare -f $func >/dev/null 2>&1; then
        echo "   ✓ $func"
    else
        echo "   ✗ $func"
    fi
done
echo ""

echo "5. Aliases:"
if [[ $- == *i* ]]; then
    for al in ll gs gadd reload install; do
        if alias $al 2>/dev/null >/dev/null; then
            echo "   ✓ $al"
        else
            echo "   ✗ $al"
        fi
    done
else
    echo "   ⚠️  Skipped (not interactive)"
fi
echo ""

echo "6. Prompt:"
if [ -n "$PS1" ]; then
    echo "   ✓ PS1 is set"
else
    echo "   ✗ PS1 not set"
fi
echo ""

echo "======================================"
echo "To see aliases, run: source diagnose_enhanced.sh"
echo "======================================"
