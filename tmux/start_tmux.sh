#!/bin/bash
# =============================================================================
# TMUX SESSION STARTUP SCRIPT
# =============================================================================
# Creates a tmux session with panes:
# - Left pane (50%): Full height, starts in ~/bin (or ~)
# - Top-right pane (60% of right side): Starts in ~/docker/compose (or ~)
# - Bottom-right pane: Runs mc if available
# - Optional bottom-most task pane if task is installed
# =============================================================================

set -euo pipefail

#----------------------------------------------------------------------------- 
# 1. NESTING GUARD: Don't run if already inside tmux
#-----------------------------------------------------------------------------
[ -n "${TMUX:-}" ] && exit 0

# Set session name to current nodename
SESSION_NAME="$(uname -s | tr '[:upper:]' '[:lower:]')"
#SESSION_NAME="main"

#----------------------------------------------------------------------------- 
# 2. DETERMINE STARTING DIRECTORIES
#----------------------------------------------------------------------------- 
# Left pane: Use ~/bin if it exists, otherwise use home directory
if [ -d "$HOME/bin" ]; then
    LEFT_DIR="$HOME/bin"
else
    LEFT_DIR="$HOME"
fi

# Top-right pane: Use ~/docker/compose if it exists, otherwise use home directory
if [ -d "$HOME/docker/compose" ]; then
    TOP_RIGHT_DIR="$HOME/docker/compose"
else
    TOP_RIGHT_DIR="$HOME"
fi

#----------------------------------------------------------------------------- 
# 3. ATTACH TO EXISTING SESSION IF IT EXISTS
#----------------------------------------------------------------------------- 
TMUX_CONF="$HOME/.tmux.conf"
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux source-file "$TMUX_CONF" >/dev/null 2>&1 || true
    tmux attach-session -t "$SESSION_NAME"
    exit 0
fi

#----------------------------------------------------------------------------- 
# 4. CREATE NEW SESSION (detached) - This creates pane 0 (left)
#----------------------------------------------------------------------------- 
if tmux list-sessions >/dev/null 2>&1; then
    tmux source-file "$TMUX_CONF" >/dev/null 2>&1 || true
fi

tmux -f "$TMUX_CONF" new-session -s "$SESSION_NAME" -d -c "$LEFT_DIR"

#----------------------------------------------------------------------------- 
# 5. BUILD THE LAYOUT
# NOTE: Using window 1 and pane 1 because .tmux.conf sets base-index 1 and pane-base-index 1
#----------------------------------------------------------------------------- 
# First split: create right pane from the left pane
# -h creates a vertical split (left | right)
# The new pane becomes pane 2
tmux split-window -h -t "$SESSION_NAME":1.1 -c "$TOP_RIGHT_DIR"

# Second split: split the right pane into top-right and bottom-right
# -p 40 means the new bottom-right pane gets 40% height
# The existing right pane remains as top-right
tmux split-window -v -t "$SESSION_NAME":1.2 -p 40 -c "$TOP_RIGHT_DIR"

# Optional: if task is installed, split the bottom-right pane into mc and task
# -p 20 means new task pane gets 20% of the bottom-right pane
if command -v task >/dev/null 2>&1; then
    tmux split-window -v -t "$SESSION_NAME":1.3 -p 20 -c "$TOP_RIGHT_DIR"
fi

#-----------------------------------------------------------------------------
# 6. SET UP EACH PANE WITH COMMANDS
#    (Moved BEFORE attach for execution guarantee)
#-----------------------------------------------------------------------------
# NOTE: With BASHRC_SKIP_IN_TMUX="yes" (default), these panes will NOT
#       re-source .bashrc. They inherit the environment from the parent shell.
#       This makes pane creation much faster!

# Wait for pane shells to finish initializing before sending keys.
# Without this delay, send-keys fires before bash is ready and keys are swallowed.
sleep 1

# Pane 1: left pane
tmux send-keys -t "$SESSION_NAME":1.1 "clear" C-m

# Pane 2: top-right pane
tmux send-keys -t "$SESSION_NAME":1.2 "clear" C-m

# Pane 3: bottom-right pane
if command -v mc >/dev/null 2>&1; then
    tmux send-keys -t "$SESSION_NAME":1.3 "clear && mc" C-m
else
    tmux send-keys -t "$SESSION_NAME":1.3 "clear" C-m
fi

# Pane 4: task pane (only if created)
if command -v task >/dev/null 2>&1; then
    # Use the underlying task command directly, because `tasks` is a shell alias
    # and tmux pane shells may not source the alias definition.
    tmux send-keys -t "$SESSION_NAME":1.4 "clear && task list" C-m
fi

#----------------------------------------------------------------------------- 
# 7. FOCUS MC PANE AND ATTACH TO SESSION
#----------------------------------------------------------------------------- 
tmux select-pane -t "$SESSION_NAME":1.3
# HOOK_CMD='if-shell "[ #{pane_id} = '$SESSION_NAME':1.3 ]" "set-option cursor-style blinking-block ; set-option cursor-colour brightred" "set-option cursor-style default ; set-option cursor-colour default"'
# tmux set-hook -g pane-focus-in "$HOOK_CMD"
tmux attach-session -t "$SESSION_NAME"
