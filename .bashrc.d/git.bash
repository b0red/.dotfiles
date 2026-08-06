#!/usr/bin/env bash
# =================================================================================================
# git.bash - Git Shortcuts & Helper Functions
# =================================================================================================
# Purpose: 50+ git aliases and convenience functions for interactive git workflows
# Dependencies: functions.bash (optional command_check helper)
# 
# 🔒 INTERACTIVE ONLY - This file contains:
#    - Git command shortcuts (gs, gco, gpush, etc.)
#    - Git workflow helpers (gacp, gcom, gnew, etc.)
#    - Git information functions (gbranches, gsize, etc.)
#    - Pretty git log formatters
# 
# ⚠️ WHY GUARDED?
#    1. Aliases are for human convenience, not script automation
#    2. Git aliases don't expand in non-interactive scripts
#    3. These shortcuts are designed for interactive terminal work
#    4. Scripts should use full git commands for clarity and portability
# =================================================================================================

# =============================================================================
# INTERACTIVE SHELL GUARD
# =============================================================================
# Check if shell is interactive ($- contains 'i')
# If NOT interactive → return immediately (don't load aliases/functions)
# If interactive → continue loading below
[[ $- == *i* ]] || return 0

# =============================================================================
# We're in an INTERACTIVE shell - load git shortcuts
# =============================================================================

#--------------------------------------
# Status & Branch Aliases
#--------------------------------------
### Git command shortcuts
alias g="git"
alias gmv="git mv"
alias grm="git rm"

### Status aliases
alias gstat='git status'
alias gs='git status'
alias gss='git status -s'

### Branch aliases
alias gbra='git branch'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'

#--------------------------------------
# Checkout & Add
#--------------------------------------
### Checkout aliases
alias go='git checkout'
alias gcob='git checkout -b'
alias gob='git checkout -b'

### Add aliases
alias gadd='git add -A .'
alias ga='git add -A .'
alias gap='git add -p'

#--------------------------------------
# Commit & Push/Pull
#--------------------------------------
### Commit aliases (use functions for commits with messages)
alias gc='git commit'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'

### Push/Pull aliases
alias gpul='git pull'
alias gpus='git push'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpu='git push -u origin HEAD'

### Remote aliases
alias gpullom='git pull origin main'
alias gpushom='git push origin main'
alias g_pull='git pull origin main'
alias g_push='git push origin main'

#--------------------------------------
# Rebase/Merge/Diff/Log
#--------------------------------------
### Rebase and merge aliases
alias gpr='git pull --rebase'
alias grb='git rebase'
alias grbi='git rebase -i'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'

### Diff aliases
alias gd='git diff'
alias gdc='git diff --cached'
alias gdh='git diff HEAD'

### Log aliases - colorized and formatted
alias glog="git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias glo='git log --oneline'
alias glg='git log --graph --oneline --decorate --all'
alias glga='git log --graph --all --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)" --abbrev-commit --date=relative'

#--------------------------------------
# Grep/Search
#--------------------------------------
### Search aliases
alias gg='git grep'
alias ggi='git grep -i'

#--------------------------------------
# Stash/Clean/Fetch & More
#--------------------------------------
### Stash aliases
alias gst='git stash'
alias gsta='git stash apply'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gstd='git stash drop'

### Other useful aliases
alias gf='git fetch'
alias gfa='git fetch --all'
alias gm='git merge'
alias gr='git remote'
alias grv='git remote -v'
alias gtag='git tag'
alias gshow='git show'
alias gcp='git cherry-pick'
alias gcpc='git cherry-pick --continue'
alias gcpa='git cherry-pick --abort'

### Navigation aliases
alias cdgit='cd "$(git rev-parse --show-toplevel 2>/dev/null)" || echo "Not in a git repository"'

### Bulk operations
alias git-pull-all='find . -name .git -type d -prune -execdir git pull -v \;'

#--------------------------------------
# Functions
#--------------------------------------

function gcom() {
    ### Commit with message
    if [[ -z "$1" ]]; then
        echo "Usage: gcom <commit message>"
        return 1
    fi
    git commit -m "$*"
}

function gacp() {
    ### Add, commit, and push to current branch
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -z "$current_branch" ]]; then
        echo "Error: Not in git repo"
        return 1
    fi
    if [[ -z "$1" ]]; then
        echo "Usage: gacp <commit msg>"
        return 1
    fi
    git add -A . && git commit -m "$*" && git push origin "$current_branch"
}

function gco() {
    ### Checkout branch
    if [[ -z "$1" ]]; then
        echo "Usage: gco <branch>"
        return 1
    fi
    git checkout "$1"
}

function gcop() {
    ### Checkout branch and pull
    if [[ -z "$1" ]]; then
        echo "Usage: gcop <branch>"
        return 1
    fi
    git checkout "$1" && git pull
}

function gnew() {
    ### Create and checkout new branch
    if [[ -z "$1" ]]; then
        echo "Usage: gnew <branch>"
        return 1
    fi
    git checkout -b "$1"
}

function gdel() {
    ### Delete local and remote branch
    if [[ -z "$1" ]]; then
        echo "Usage: gdel <branch>"
        return 1
    fi
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ "$1" == "$current_branch" ]]; then
        echo "Error: Cannot delete current branch"
        return 1
    fi
    echo "Delete local $1? (y/n)"
    read -r confirm
    [[ "$confirm" =~ ^[Yy] ]] && git branch -D "$1"
    echo "Delete remote $1? (y/n)"
    read -r confirm
    [[ "$confirm" =~ ^[Yy] ]] && git push origin --delete "$1"
}

function gclone() {
    ### Clone repository and cd into it
    if [[ -z "$1" ]]; then
        echo "Usage: gclone <repo-url>"
        return 1
    fi
    git clone "$1" && cd "$(basename "$1" .git)" || return 1
}

function gclean() {
    ### Remove untracked files/directories (with confirmation)
    echo "WARNING: Delete all untracked files/directories? (y/n)"
    read -r confirm
    [[ "$confirm" =~ ^[Yy] ]] && git clean -fd || echo "Cancelled"
}

function gundo() {
    ### Undo last commit (keeps changes staged)
    if [[ -z "$1" ]]; then
        git reset --soft HEAD~1
    else
        git reset --soft HEAD~"$1"
    fi
}

function gundohard() {
    ### Undo last commit (discards changes)
    echo "WARNING: Discard last commit changes? (y/n)"
    read -r confirm
    [[ "$confirm" =~ ^[Yy] ]] && git reset --hard HEAD~1 || echo "Cancelled"
}

function greset() {
    ### Reset to specific commit
    if [ -z "$1" ]; then
        echo "Usage: greset <commit-hash>"
        return 1
    fi
    
    echo "Reset to commit $1? This will discard uncommitted changes. (y/n)"
    read -r confirm
    if [[ "$confirm" == "y" ]]; then
        git reset --hard "$1"
    else
        echo "Cancelled"
    fi
}

function gbranches() {
    ### List branches sorted by last commit date
    git for-each-ref --sort=-committerdate refs/heads/ \
        --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'
}

function gsize() {
    ### Show size of git repository
    local repo_path
    repo_path="$(git rev-parse --show-toplevel 2>/dev/null)"
    
    if [ -z "$repo_path" ]; then
        echo "Not in a git repository"
        return 1
    fi
    
    echo "Repository size:"
    du -sh "$repo_path/.git"
    echo ""
    echo "Working tree size:"
    du -sh "$repo_path" --exclude='.git'
}

function gcontrib() {
    ### Show contribution stats for all authors
    git shortlog -sn --all --no-merges
}

function gfiles() {
    ### List files tracked by git
    git ls-tree -r HEAD --name-only
}

function gignore() {
    ### Add pattern to .gitignore
    if [ -z "$1" ]; then
        echo "Usage: gignore <pattern>"
        return 1
    fi
    echo "$1" >> .gitignore
    echo "Added '$1' to .gitignore"
}

function gwho() {
    ### Show who changed a specific line in a file
    if [ $# -ne 2 ]; then
        echo "Usage: gwho <file> <line-number>"
        return 1
    fi
    git blame -L "$2,$2" "$1"
}

function gsync() {
    ### Sync current branch with remote (fetch, rebase, push)
    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    
    if [ -z "$current_branch" ]; then
        echo "Error: Not in a git repository"
        return 1
    fi
    
    echo "Syncing $current_branch with remote..."
    git fetch origin && \
    git rebase "origin/$current_branch" && \
    git push origin "$current_branch"
}

function gcleanup() {
    ### Remove merged branches except main/master/develop
    local protected_branches="main|master|develop"
    
    echo "Fetching latest changes..."
    git fetch --prune
    
    echo "Branches that will be deleted:"
    git branch --merged | grep -vE "^\*|$protected_branches"
    
    echo "Delete these branches? (y/n)"
    read -r confirm
    if [[ "$confirm" == "y" ]]; then
        git branch --merged | grep -vE "^\*|$protected_branches" | xargs -r git branch -d
        echo "Cleanup complete"
    else
        echo "Cancelled"
    fi
}

function gtree() {
    ### Show tree of commits
    git log --graph --oneline --decorate --all
}

function gdiff-word() {
    ### Word-by-word diff instead of line-by-line
    git diff --word-diff "$@"
}

function gfind() {
    ### Find commits that mention a specific string
    if [ -z "$1" ]; then
        echo "Usage: gfind <search-string>"
        return 1
    fi
    git log --all --grep="$1"
}

# End of git.bash (Interactive Only)