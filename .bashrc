# ~/.bashrc - executed by bash(1) for non-login shells.

# -------------------------------------------------------------------
# 0. Only run for interactive shells
# -------------------------------------------------------------------
case $- in
    *i*) ;;
    *) return ;;
esac

# -------------------------------------------------------------------
# 1. Clear old aliases and prevent recursive re-entry
# -------------------------------------------------------------------
# Prevent recursion only if the dotfiles tail has already run.
# This allows manual `source ~/.bashrc` to reapply aliases.
if [ -n "${DOTFILES_BASHRC_DONE:-}" ]; then
    return
fi
# Clear all aliases to avoid conflicts when re-sourcing.
unalias -a 2>/dev/null

# -------------------------------------------------------------------
# 2. ENV file (if set)
# -------------------------------------------------------------------
[ -n "$ENV" ] && [ -f "$ENV" ] && . "$ENV"

# -------------------------------------------------------------------
# 3. Colors and bash-completion
# -------------------------------------------------------------------
# Setup colors for 'ls' and coreutils if dircolors available.
if [ -x /usr/bin/dircolors ]; then
    if [ -r ~/.dircolors ]; then
        eval "$(dircolors -b ~/.dircolors)"
    else
        eval "$(dircolors -b)"
    fi
fi

# Enable programmable completion features if not in POSIX mode.
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# -------------------------------------------------------------------
# 4. Shell options and history
# -------------------------------------------------------------------
shopt -s checkwinsize    # Update LINES and COLUMNS after each command
shopt -s histappend      # Append to history file, don't overwrite
shopt -s cmdhist         # Save multi-line commands as one entry
shopt -s cdspell         # Autocorrect minor spelling errors in cd
shopt -s dirspell        # Autocorrect directory names during completion
shopt -s nocaseglob      # Case-insensitive globbing

# History settings
HISTCONTROL='ignoreboth'
HISTSIZE=100000
HISTFILESIZE=100000
HISTIGNORE="exit:history:l:ls:ll:la:lla:bg:fg:h:q:pwd:clear:cls:cd:man:pwd:x"
HISTTIMEFORMAT="%d/%m/%y %T "

# -------------------------------------------------------------------
# 5. Prompt
# -------------------------------------------------------------------
# Prompt: red for root, green for normal users.
if [ "$(id -u)" -eq 0 ]; then
    PS1='\[\e[1;31m\]\u\[\e[m\]\[\e[0;32m\]@\h:\[\e[m\]\[\e[1;34m\]\w\[\e[m\]\[\e[1;31m\]\$\[\e[m\] '
else
    PS1='\[\e[1;32m\]\u\[\e[m\]\[\e[0;32m\]@\h:\[\e[m\]\[\e[1;34m\]\w\[\e[m\]\[\e[1;32m\]\$\[\e[m\] '
fi

# -------------------------------------------------------------------
# 6. Source modular dotfiles: ~/dotfiles/.bashrc.d/*.bash
# -------------------------------------------------------------------
BASHRC_DIR="$HOME/dotfiles/.bashrc.d"

if [ -d "$BASHRC_DIR" ]; then
    # Load specific files first (order matters).
    for f in exports.bash env.bash functions.bash git.bash docker.bash; do
        if [ -f "$BASHRC_DIR/$f" ]; then
            if command -v log >/dev/null 2>&1; then
                log "Sourcing $BASHRC_DIR/$f"
            else
                echo "[bashrc] Sourcing $BASHRC_DIR/$f"
            fi
            # shellcheck disable=SC1090
            source "$BASHRC_DIR/$f"
        fi
    done

    # Load any remaining *.bash files not already loaded above.
    for f in "$BASHRC_DIR"/*.bash; do
        [ -f "$f" ] || continue
        case "$(basename "$f")" in
            exports.bash|env.bash|functions.bash|git.bash|docker.bash) continue ;;
        esac
        if command -v log >/dev/null 2>&1; then
            log "Sourcing $f"
        else
            echo "[bashrc] Sourcing $f"
        fi
        # shellcheck disable=SC1090
        source "$f"
    done
fi
unset BASHRC_DIR f

# -------------------------------------------------------------------
# 7. Source profile fragments: ~/dotfiles/.profile.d/*.sh
# -------------------------------------------------------------------
if [ -d "$HOME/dotfiles/.profile.d" ]; then
    for f in "$HOME/dotfiles/.profile.d"/*.sh; do
        [ -f "$f" ] && . "$f"
    done
    unset f
fi

# -------------------------------------------------------------------
# 8. tmux helpers and OS-specific helpers
# -------------------------------------------------------------------
# Extra tmux git status script (if present).
if [ -f ~/.tmux-extras/tmux-gittmux-gittmux.sh ]; then
    . ~/.tmux-extras/tmux-gittmux-gittmux.sh
fi

# tmux git integration if inside tmux.
if [ -n "$TMUX" ] && [ -f "$HOME/.tmux-git/tmux-git.sh" ]; then
    . "$HOME/.tmux-git/tmux-git.sh"
fi

# OS detection and setting standard commands (if your functions exist).
# if command -v get_os >/dev/null 2>&1; then
#     get_os >/dev/null 2>&1
#     setting_standard_commands >/dev/null 2>&1
# fi

# -------------------------------------------------------------------
# 9. Fix tmux socket permissions
# -------------------------------------------------------------------
umask 0022
TMUX_TMPDIR="/tmp/tmux-$(id -u)"
if [ -d "$TMUX_TMPDIR" ]; then
    chmod 0700 "$TMUX_TMPDIR" 2>/dev/null
    if [ "$(stat -c '%a' "$TMUX_TMPDIR" 2>/dev/null)" != "700" ]; then
        rm -rf "$TMUX_TMPDIR" 2>/dev/null
        mkdir -p "$TMUX_TMPDIR" 2>/dev/null
        chmod 0700 "$TMUX_TMPDIR" 2>/dev/null
    fi
else
    mkdir -p "$TMUX_TMPDIR" 2>/dev/null
    chmod 0700 "$TMUX_TMPDIR" 2>/dev/null
fi
unset TMUX_TMPDIR

# -------------------------------------------------------------------
# 10. SSH agent / keychain integration
# -------------------------------------------------------------------
# Start ssh-agent if not already running (simple version).
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    [ -f "$HOME/.ssh/id_rsa" ] && ssh-add "$HOME/.ssh/id_rsa" >/dev/null 2>&1 || true
fi

# SSH agent with keychain (if available).
if command -v keychain >/dev/null 2>&1; then
    SSH_KEYS=()
    for key in id_ed25519 id_rsa id_ecdsa id_dsa; do
        [ -f "$HOME/.ssh/$key" ] && SSH_KEYS+=("$key")
    done
    if [ ${#SSH_KEYS[@]} -gt 0 ]; then
        eval "$(keychain --eval --agents ssh --quiet "${SSH_KEYS[@]}" 2>/dev/null)"
    fi
    unset SSH_KEYS key
fi

# -------------------------------------------------------------------
# 11. Auto-start tmux (custom script)
# -------------------------------------------------------------------
if [ -z "$TMUX" ] && [ -x "$HOME/bin/start_tmux.sh" ]; then
    "$HOME/bin/start_tmux.sh"
fi

# -------------------------------------------------------------------
# 12. Welcome message
# -------------------------------------------------------------------
if [ -n "$PS1" ]; then
    echo -e "\n${GREEN:-}Welcome to $(hostname)${NC:-}"
    echo -e "${BLUE:-}$(date)${NC:-}\n"
fi

# Optional: extra alias file (commented)
# source ~/.dcp_alias

# -------------------------------------------------------------------
# 13. Package manager aliases (from pkg_aliases.bash)
# -------------------------------------------------------------------
# This expects ~/dotfiles/.bashrc.d/pkg_aliases.bash to define set_package_aliases.
if command -v set_package_aliases >/dev/null 2>&1; then
    set_package_aliases
fi

# Mark that dotfiles bashrc tail has run (for recursion guard).
DOTFILES_BASHRC_DONE=1
export DOTFILES_BASHRC_DONE
