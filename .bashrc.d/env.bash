#!/usr/bin/env bash
# =================================================================================================
# env.bash - Shell Environment Configuration
# =================================================================================================
# Purpose: Shell options, history settings, terminal setup
# Dependencies: exports.bash (loads before)
# 
# ⚠️ NO INTERACTIVE GUARD - Shell options needed in all contexts
# Even scripts benefit from proper shell behavior settings
# =================================================================================================

# =============================================================================
# SHELL OPTIONS (apply to all bash contexts)
# =============================================================================
shopt -s checkwinsize 2>/dev/null || true    # Resize windows properly
shopt -s cmdhist 2>/dev/null || true         # Save multi-line as one
shopt -s histappend 2>/dev/null || true      # Append history, don't overwrite
shopt -s cdspell 2>/dev/null || true         # Auto-correct cd typos
shopt -s dirspell 2>/dev/null || true        # Auto-correct dir names
shopt -s nocaseglob 2>/dev/null || true      # Case-insensitive globs

# =============================================================================
# LESSPIPE (enhanced less for compressed files)
# =============================================================================
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"

# =============================================================================
# PROCESS ALIASES (only if not already defined)
# =============================================================================
# Check if psg function exists, if not create function version
if ! command -v psg >/dev/null 2>&1; then
    psg() {
        pgrep -i -f "$1" || true
    }
fi

# Modern process viewer (procs) if available, else standard ps
if command -v procs >/dev/null 2>&1; then
    alias ps='procs'
else
    alias ps='ps aux'
fi

# End of env.bash
