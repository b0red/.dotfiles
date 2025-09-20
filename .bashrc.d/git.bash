# -----------------------------------------------------------------------------
#
#   .git_aliases
#
# -----------------------------------------------------------------------------

### Compact, colorized git log for easier readability
alias gl="git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

### Visualize git log graphically in terminal (like gitk alternative)
alias lg='git log --graph --full-history --all --color --pretty=format:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s"'

### Git command shortcuts
alias g="git"
alias gmv="git mv"

# Use brace expansion for grouped aliases - safer in newer bash versions
alias gstat='git status'
alias gs='git status'
alias gss="git status -s"
alias gbra='git branch'
alias gb='git branch'
alias gc="git clone"
alias gco='git checkout'
alias go='git checkout'
alias gcob='git checkout -b'
alias gob='git checkout -b'
alias gadd='git add -A .'
alias ga='git add -A .'

# Commit alias with message parameter (note: alias can't take $1; better switch to function)
# Commenting this out and replacing with function below
# alias gcom='git commit -m $1'
# alias gc='git commit' # keep git commit without message

alias gpul='git pull'
alias gl='git pull' # this duplicates alias 'gl' above for git log, potential conflict
alias gpus='git push'
alias gp='git push'

alias gpullom='git pull origin master'
alias g_pull='git pull origin master'

alias gpushom='git push origin master'
alias g_push='git push origin master'

alias gg='git grep'
alias cdgit='cd "$(git rev-parse --show-toplevel 2> /dev/null)"'

# Pull all git repositories in current repo subdirectories with verbose output
alias git-pull-all='find "$(git rev-parse --show-toplevel 2> /dev/null)" -name .git -type d -execdir git pull -v ";"'

# Other common shortcuts
alias glum="git pull upstream master"
alias gpr="git pull --rebase"
alias gppd="git pull && git push origin develop"
alias ggpm="git pull && git push origin master"
alias gfrb="git fetch && git rebase"

### Git helper functions

# Add, commit, and push to current branch with a commit message
function gacp() {
    local CURRENT_BRANCH
    CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    if [ -z "$1" ]; then
        echo "Usage: gacp \"commit message\""
        return 1
    fi
    git add -A . && git commit -m "$1" && git push origin "$CURRENT_BRANCH"
}

# Git merge shortcut, usage: gm branch-name
function gm() {
    if [ -z "$1" ]; then
        echo "Usage: gm <branch>"
        return 1
    fi
    git merge "$1"
}

# Git checkout with optional push after checkout; usage: gco branch-name
function gco() {
    if [ -z "$1" ]; then
        echo "Usage: gco <branch>"
        return 1
    fi
    git checkout "$1" && gp
}

### Commented out test/debug line
# echo ${file##*/}
