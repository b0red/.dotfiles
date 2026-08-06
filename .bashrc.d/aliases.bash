#                                                                                                            2025-01-15
#=======================================================================================================================
# .bash_aliases - Refined collection of bash aliases for Linux/Ubuntu with error checks and modern alternatives
#=======================================================================================================================
# This file provides productivity aliases grouped logically:
# 1. Reload/Sourcing (general)
# 2. Navigation/Directory listings (core ls/tree)
# 3. File operations (mv/rm/cat)
# 4. System monitoring (ps/du/df/top)
# 5. Package/Debian tools (apt/deborphan - Ubuntu-specific)
# 6. Networking/Tools (ssh/ip/ports)
# 7. Git/Tmux/Dev (git/tmux)
# 8. Modern alternatives (eza/bat/broot/fd - non-Ubuntu preferred)
# 9. Misc utilities (weather/cron)
#
# Error handling: All aliases use safe quoting; conditionals check commands before overriding.
# Cross-platform: Ubuntu-first, with fallbacks (e.g., eza if installed, else ls).
#=======================================================================================================================

#--------------------------------------
# 0. Helper Functions (originals fixed)
# =============================================================================
# INTERACTIVE SHELL GUARD
# =============================================================================
# [[ $- == *i* ]] || return 0

#--------------------------------------
command_exists() {
  if command -v "$1" >/dev/null 2>&1; then
    echo -e "${ORANGE}$1 ${RESET}${GREEN}is installed/found!${RESET}"
    return 0
  else
    echo -e "${ORANGE}$1${RESET} ${RED}is not installed/found!${RESET}"
    return 1
  fi
}

#--------------------------------------
# 1. Reload and Sourcing - IMPROVED FOR TMUX
#--------------------------------------
# Standard reload - forces load even in tmux using BOTH methods
alias reload='unset BASHRC_SOURCED 2>/dev/null; BASHRC_FORCE_LOAD=1 source ~/.bashrc && clear'

# Alternative reload methods
alias src='unset BASHRC_SOURCED 2>/dev/null; BASHRC_FORCE_LOAD=1 source ~/.bashrc'  # Force reload without clear
alias bashrc='${EDITOR:-vim} ~/.bashrc'                    # Edit .bashrc
alias srcquiet='BASHRC_FORCE_LOAD=1 source ~/.bashrc 2>/dev/null'  # Silent reload

# Toggle tmux behavior without editing files
alias bashrc-toggle-tmux='_bashrc_toggle_tmux_behavior'

# Reset ask-mode decision
alias bashrc-reset-choice='_bashrc_reset_tmux_choice'

#--------------------------------------
# 1.1 Functions for TMUX behavior control
#--------------------------------------

_bashrc_toggle_tmux_behavior() {
    ### Toggle BASHRC_SKIP_IN_TMUX setting interactively
    local current="${BASHRC_SKIP_IN_TMUX:-yes}"
    echo "Current TMUX behavior: $current"
    echo ""
    echo "Choose new behavior:"
    echo "  [1] Skip in tmux (load only on terminal start) - RECOMMENDED"
    echo "  [2] Always load in tmux panes/windows"
    echo "  [3] Ask on first pane"
    echo "  [c] Cancel"
    echo ""
    read -r -p "Choice [1/2/3/c]: " choice
    
    case "$choice" in
        1)
            export BASHRC_SKIP_IN_TMUX="yes"
            echo "✓ Set to skip in tmux. Add to ~/.bash_profile to persist:"
            echo '  export BASHRC_SKIP_IN_TMUX="yes"'
            ;;
        2)
            export BASHRC_SKIP_IN_TMUX="no"
            echo "✓ Set to always load in tmux. Add to ~/.bash_profile to persist:"
            echo '  export BASHRC_SKIP_IN_TMUX="no"'
            ;;
        3)
            export BASHRC_SKIP_IN_TMUX="ask"
            rm -f "$HOME/.bashrc_tmux_choice" 2>/dev/null
            echo "✓ Set to ask mode. Add to ~/.bash_profile to persist:"
            echo '  export BASHRC_SKIP_IN_TMUX="ask"'
            ;;
        *)
            echo "Cancelled - no changes made"
            return 0
            ;;
    esac
    
    echo ""
    echo "Run 'reload' to apply changes to current shell"
}

_bashrc_reset_tmux_choice() {
    ### Reset the ask-mode decision so you'll be prompted again
    if [[ -f "$HOME/.bashrc_tmux_choice" ]]; then
        local old_choice
        old_choice=$(cat "$HOME/.bashrc_tmux_choice" 2>/dev/null)
        rm -f "$HOME/.bashrc_tmux_choice"
        echo "✓ Reset ask-mode decision (was: $old_choice)"
        echo "Next tmux pane will prompt you again"
        
        # Offer to change mode
        echo ""
        read -r -p "Change BASHRC_SKIP_IN_TMUX mode now? [y/N]: " answer
        if [[ "$answer" =~ ^[Yy] ]]; then
            _bashrc_toggle_tmux_behavior
        fi
    else
        echo "No stored choice found"
        echo "Current mode: ${BASHRC_SKIP_IN_TMUX:-yes}"
        
        if [[ "${BASHRC_SKIP_IN_TMUX}" == "ask" ]]; then
            echo "Next tmux pane will prompt you"
        else
            echo ""
            read -r -p "Switch to ask mode? [y/N]: " answer
            if [[ "$answer" =~ ^[Yy] ]]; then
                export BASHRC_SKIP_IN_TMUX="ask"
                echo "✓ Switched to ask mode"
                echo "Add to ~/.bash_profile to persist:"
                echo '  export BASHRC_SKIP_IN_TMUX="ask"'
            fi
        fi
    fi
}

#----------------------------------------------------------------------------
# 2. Navigation and Directory Listings (Ubuntu ls defaults)
#----------------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias back='cd "$OLDPWD"'
alias p='pwd'
alias x='exit'
alias clr='clear && pwd && ls'
alias cls='clear'

# Standard ls with colors (Ubuntu default)
if [[ -x /usr/bin/dircolors ]]; then
  # shellcheck disable=SC2015
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto --group-directories-first'
fi

# Basic ls variants
alias l='ls -CF'
alias la='ls -A'
alias lll='ls -alFGH --color=always | less -R'
alias kk='ls -alF --group-directories-first'
alias ll='ls -alF --group-directories-first'
alias oo='ls -alF --group-directories-first'
alias lsd='ls -alF | grep "/$"'
alias lf='ls -l | egrep -v "^d"'
alias ldir='ls -l | egrep "^d"'

# Tree-like views
# ltree() is defined in functions.bash (uses real tree with paging — much more capable)
alias treels='find . -type d | sed "s/[^-][^/]*/  /g;s/^-/\ |/"'

#----------------------------------------------------------------------------
# 3. File Operations
#----------------------------------------------------------------------------
alias mv='mv -v'
alias rm='rm -i'  # Interactive confirm
alias nano='nano -c'
alias vi='vim'
alias less='less -R'  # Colored pipe support
function ghost() { ghostwriter "$@"; }

# Colored grep (safe, no deprecated GREP_OPTIONS)
alias grep='grep --color=always --line-number --no-messages --binary-files=without-match'
alias egrep='grep --color=always --line-number --no-messages --binary-files=without-match'
alias fgrep='grep --color=always --line-number --no-messages --binary-files=without-match'

# Comment removal (fixed regex)
alias nocomment="grep -Ev '^(#|$)'"

# No extensions finder
alias no_extensions='find . -type f ! -name "*.*"'

# Extension lister
# double-quoted perl would let bash expand $1 before perl sees it
function list_extensions() {
  find . -type f | perl -ne 'print $1, "\n" if m/\.([^.\/]+)$/' | sort -u
}

# Chmod aliases (originals)
alias mx='chmod a+x'
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'

# Tree levels (originals restored)
alias tree1='tree -L 1 2>/dev/null || ltree'
alias tree2='tree -L 2 2>/dev/null || ltree'
alias tree3='tree -L 3 2>/dev/null || ltree'
alias tree4='tree -L 4 2>/dev/null || ltree'

#----------------------------------------------------------------------------
# 4. System Monitoring
#----------------------------------------------------------------------------
alias df='df -h'
function h() {
  history | grep "$1"
}
alias hr='history | sort -rn'

# Process tools (Ubuntu ps)
alias ps='ps aux'
function psg() {
  pgrep -af -i "$1" || true
}

# Memory/disk hogs (safe escapes)
alias ds='du -ks * 2>/dev/null | sort -n'
alias big='du -ah . 2>/dev/null | sort -rh | head -40'
alias big-files='ls -1Rhs 2>/dev/null | sed -e "s/^ *//" | grep "^[0-9]" | sort -hr | head -n 40'
alias psmem='ps -eo time,ppid,pid,pcpu,pmem,user,comm --sort=-pmem | head -15'
alias freq='cut -f 1 -d " " ~/.bash_history | sort | uniq -c | sort -nr | head -30'

if command -v lazyports > /dev/null 2>&1; then
    alias lzp='lazyports'
fi

# Ports/services (systemd/Ubuntu)
function sstatus() {
  sudo systemctl status "$1"
}
function srestart() {
  sudo systemctl restart "$1"
}

# --- Universal Service Listing ---
if command -v systemctl >/dev/null 2>&1; then
      # Systemd (Modern Ubuntu, Fedora, Arch, Debian)
      alias services='systemctl list-units --type=service --all'
      alias services_run='systemctl list-units --type=service --state=running'
  elif command -v rc-status >/dev/null 2>&1; then
      # OpenRC (Alpine, Gentoo)
      alias services='rc-status --all'
      alias services_run='rc-status --started'
  else
      # Legacy SysVinit (Older systems)
      alias services='service --status-all'
      alias services_run='service --status-all 2>/dev/null | grep "\[ + \]"'
fi

alias ports='sudo netstat -tulanp 2>/dev/null || sudo ss -tulanp'

#----------------------------------------------------------------------------
# 5. Package/Debian Tools (Ubuntu-specific)
#----------------------------------------------------------------------------
# Moved to pkg_aliases.bash in .bashrc.d/pkg_aliases.bash. Using more comprehensive package management aliases there.
# Keeping this section commented out for reference.
# # APT with sudo (Ubuntu)
# alias apt='sudo apt'
# clean commented out as incomplete
# alias latest='grep " install " /var/log/dpkg.log* 2>/dev/null'

# SSH restart (Ubuntu service)
alias sshrestart='sudo service ssh restart 2>/dev/null || sudo systemctl restart ssh'

# Midnight Commander
command -v mc >/dev/null 2>&1 && alias mc='sudo mc'

#----------------------------------------------------------------------------
# 6. Networking/Tools
#----------------------------------------------------------------------------
alias ifconfig='ip -c a'
alias ip='ip -br -c a'
# myip() is defined in functions.bash (detects active NIC — more reliable than curl)
alias week='date +%V'
alias diff='colordiff 2>/dev/null || diff'
function f() {
  find . -type f | grep "$1"
}
alias root='sudo su -'
alias su='sudo -i'
# shellcheck disable=SC2046
function please() { sudo $(fc -ln -1); }
# alias wget="wget -c $1"
alias wget='wget -c'

# SSH agent check (fixed quoting)
alias ssh='if [ "$(ssh-add -l 2>/dev/null)" = "The agent has no identities." ]; then ssh-add; fi; /usr/bin/ssh'

# Crontab interactive
alias crontab='crontab -i'

#----------------------------------------------------------------------------
# 7. Git/Tmux/Dev
#----------------------------------------------------------------------------
# shellcheck disable=SC2139
alias {module-update,modup}='git submodule foreach '"'"'git pull origin master'"'"
alias tm='tmux new-session -s main \; split-window -h \; split-window -v -p 30'
alias tmx='tmux attach -t 0 2>/dev/null || tmux new-session'
alias tmkill='tmux ls 2>/dev/null | grep : | cut -d: -f1 | xargs -r tmux kill-session -t'

# Updates (dotfiles/bin)
alias dotupdate='cd ~/.dotfiles && git pull && source ~/.bashrc'
alias binupdate='cd ~/bin && git pull origin master 2>/dev/null'

# Youtube-dl (fixed path/args)
# command -v yt-dlp >/dev/null 2>&1 && alias youtube='yt-dlp' || alias youtube='/usr/bin/python3 /usr/local/bin/youtube-dl'
# Youtube (full path check)
if [[ -x /usr/local/bin/youtube-dl ]]; then
  function youtube() {
    /usr/bin/python3 /usr/local/bin/youtube-dl "$@"
  }
fi

# Wireguard (path-safe)
alias wgup='sudo wg-quick up ~/wireguard/conf/SeStockholm.conf 2>/dev/null'
alias wgdown='sudo wg-quick down ~/wireguard/conf/SeStockholm.conf 2>/dev/null'

#----------------------------------------------------------------------------
# 8. Modern Alternatives (Non-Ubuntu preferred; conditional overrides)
#----------------------------------------------------------------------------
# eza (modern ls replacement)
command -v eza >/dev/null 2>&1 && {
  alias ls='eza'
  alias ll='eza -lha --group-directories-first'
  alias la='eza -lhaa'
}

# bat (modern cat)
command -v bat >/dev/null 2>&1 && alias cat='bat'

# broot (modern tree/cd)
command -v broot >/dev/null 2>&1 && alias tree='broot'

# fd (modern find)
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'

# btop/bottom/procs (modern top/ps)
command -v btop >/dev/null 2>&1 && alias top='btop'
command -v bottom >/dev/null 2>&1 && alias btm='bottom'
command -v procs >/dev/null 2>&1 && alias ps='procs'

# ncdu (modern du)
command -v ncdu >/dev/null 2>&1 && alias du='ncdu'

# prettyping
command -v prettyping >/dev/null 2>&1 && alias ping='prettyping --nolegend'

#----------------------------------------------------------------------------
# 9. Misc Utilities
#----------------------------------------------------------------------------
alias weather='curl wttr.in/Stockholm'
alias weather2='curl v2.wttr.in'
# comstat (original, fixed push→echo)
alias comstat='echo "Command ran! ($(uname -n))" || echo "Command failed!" >&2'
# mount alias commented; use `mount | column -t` manually

# taskwarrior (original)
command -v task >/dev/null 2>&1 && alias tasks='clear; task list'

#echo "Aliases loaded successfully."
