#!/bin/bash
# =============================================================================
# TMUX SESSION STARTUP SCRIPT
# =============================================================================
# Creates a tmux session with panes:
# - Left pane (50%): Full height, starts in ~/bin (or ~)
# - Top-right pane (60% of right side): Starts in ~/docker/compose (or ~)
# - Middle-right pane: Runs mc if available
# - Bottom-right pane: Runs task if available
# =============================================================================

#-----------------------------------------------------------------------------
# 1. NESTING GUARD: Don't run if already inside tmux
#-----------------------------------------------------------------------------
[ -n "$TMUX" ] && exit 0

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
# Bottom-right also uses TOP_RIGHT_DIR
if [ -d "$HOME/docker/compose" ]; then
    TOP_RIGHT_DIR="$HOME/docker/compose"
else
    TOP_RIGHT_DIR="$HOME"
fi

#-----------------------------------------------------------------------------
# 3. ATTACH TO EXISTING SESSION IF IT EXISTS
#-----------------------------------------------------------------------------
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux attach-session -t "$SESSION_NAME"
    exit 0
fi

#-----------------------------------------------------------------------------
# 4. CREATE NEW SESSION (detached) - This creates pane 0 (left)
#-----------------------------------------------------------------------------
tmux new-session -s "$SESSION_NAME" -d -c "$LEFT_DIR"

#-----------------------------------------------------------------------------
# 5. BUILD THE LAYOUT
#-----------------------------------------------------------------------------
# First split: Create right pane (pane 1) with vertical divider
# -h creates a vertical divider (left | right layout)
# After this split, pane 1 (right) becomes the ACTIVE pane
tmux split-window -h -c "$TOP_RIGHT_DIR"

# Second split: Split pane 1 (right pane) horizontally (top / bottom)
# -v creates a horizontal divider (top / bottom layout)
# -p 40 means the NEW pane (bottom-right, becomes pane 2) gets 40% height
# This leaves pane 1 (top-right) with 60% height
# We must target pane 1 explicitly, or use select-pane first
tmux select-pane -t 0
tmux split-window -v -p 40 -c "$TOP_RIGHT_DIR"

# Optional: If task is installed, split pane 3 (mc) to create pane 4 (task) at bottom
# -p 20 means the NEW pane (task) gets 20% height, mc keeps 80%
# Adjust -p value to change task pane size (e.g., -p 40 for 40% height)
if command -v task >/dev/null 2>&1; then
    tmux select-pane -t 3
    tmux split-window -v -p 20 -c "$TOP_RIGHT_DIR"
fi

#-----------------------------------------------------------------------------
# 6. SET UP EACH PANE WITH COMMANDS
#    (Moved BEFORE attach for execution guarantee)
#-----------------------------------------------------------------------------
# NOTE: With BASHRC_SKIP_IN_TMUX="yes" (default), these panes will NOT
#       re-source .bashrc. They inherit the environment from the parent shell.
#       This makes pane creation much faster!

# Pane 0 (left pane): Clear the screen
tmux send-keys -t 0 "clear" C-m

# Pane 1 (top-right pane): Clear the screen
tmux send-keys -t 1 "clear" C-m

# Pane 3 (bottom-right pane, or middle-right if task exists): Launch mc if available
if command -v mc >/dev/null 2>&1; then
    tmux send-keys -t 3 "clear && mc" C-m
else
    tmux send-keys -t 3 "clear" C-m
fi

# Pane 4 (bottom-most right pane): Launch task if available (only if pane was created)
if command -v task >/dev/null 2>&1; then
    tmux send-keys -t 4 "clear && task" C-m
fi

#-----------------------------------------------------------------------------
# 7. FOCUS MC PANE (pane 3) AND ATTACH TO SESSION
#-----------------------------------------------------------------------------
tmux select-pane -t 3
tmux attach-session -t "$SESSION_NAME"
