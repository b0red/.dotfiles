#!/usr/bin/env bash
# =================================================================================================
# git.bash - COMPLETE Git shortcuts & helpers
# =================================================================================================
# Purpose: 50+ aliases (gstat/gco/gpush) + functions (gcom/gacp/gnew/gsync).
# Dependencies: functions.bash (optional helpers).
# All original preserved + safe params/returns.
# =================================================================================================

[[ $- == *i* ]] || return 0

#--------------------------------------
# Status & Branch Aliases (originals)
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
# Checkout & Add (originals)
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
# Commit & Push/Pull (originals + safe)
#--------------------------------------
### Commit aliases (note: use functions for commits with messages)
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
# Rebase/Merge/Diff/Log (originals)
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
# Grep/Search (originals)
#--------------------------------------
### Search aliases
alias gg='git grep'
alias ggi='git grep -i'

#--------------------------------------
# Stash/Clean/Fetch & More (originals)
#--------------------------------------
### Stash aliases
alias gst='git stash'
alias gsta='git stash apply'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gstd='git stash drop'

### Other useful aliases
alias gclean='git clean -fd'
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
# Functions (originals fixed: params/quoting/returns)
#--------------------------------------
function gcom() {
    if [[ -z "$1" ]]; then echo "Usage: gcom <commit message>"; return 1; fi
    git commit -m "$*"
}

function gacp() {
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -z "$current_branch" ]]; then echo "Error: Not in git repo"; return 1; fi
    if [[ -z "$1" ]]; then echo "Usage: gacp <commit msg>"; return 1; fi
    git add -A . && git commit -m "$*" && git push origin "$current_branch"
}

function gco() {
    if [[ -z "$1" ]]; then echo "Usage: gco <branch>"; return 1; fi
    git checkout "$1"
}

function gcop() {
    if [[ -z "$1" ]]; then echo "Usage: gcop <branch>"; return 1; fi
    git checkout "$1" && git pull
}

function gnew() {
    if [[ -z "$1" ]]; then echo "Usage: gnew <branch>"; return 1; fi
    git checkout -b "$1"
}

function gdel() {
    if [[ -z "$1" ]]; then echo "Usage: gdel <branch>"; return 1; fi
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ "$1" == "$current_branch" ]]; then echo "Error: Cannot delete current branch"; return 1; fi
    echo "Delete local $1? (y/n)"; read -r confirm
    [[ "$confirm" =~ ^[Yy] ]] && git branch -D "$1"
    echo "Delete remote $1? (y/n)"; read -r confirm
    [[ "$confirm" =~ ^[Yy] ]] && git push origin --delete "$1"
}

function gclone() {
    if [[ -z "$1" ]]; then echo "Usage: gclone <repo-url>"; return 1; fi
    git clone "$1" && cd "$(basename "$1" .git)"
}

function gundo() {
    if [[ -z "$1" ]]; then echo "Usage: gundo <n>"; return 1; fi
    git reset --soft HEAD~$1
}

function gundohard() {
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
    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    
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

### Git helper functions

function gcom() {
    ### Commit with message
    if [ -z "$1" ]; then
        echo "Usage: gcom \"commit message\""
        return 1
    fi
    git commit -m "$1"
}

function gacp() {
    ### Add, commit, and push to current branch
    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    
    if [ -z "$current_branch" ]; then
        echo "Error: Not in a git repository"
        return 1
    fi
    
    if [ -z "$1" ]; then
        echo "Usage: gacp \"commit message\""
        return 1
    fi
    
    git add -A . && \
    git commit -m "$1" && \
    git push origin "$current_branch"
}

function gco() {
    ### Checkout branch
    if [ -z "$1" ]; then
        echo "Usage: gco <branch>"
        return 1
    fi
    git checkout "$1"
}

function gcop() {
    ### Checkout branch and push
    if [ -z "$1" ]; then
        echo "Usage: gcop <branch>"
        return 1
    fi
    git checkout "$1" && git push
}

function gnew() {
    ### Create and checkout new branch
    if [ -z "$1" ]; then
        echo "Usage: gnew <branch-name>"
        return 1
    fi
    git checkout -b "$1"
}

function gdel() {
    ### Delete local and remote branch
    if [ -z "$1" ]; then
        echo "Usage: gdel <branch-name>"
        return 1
    fi
    
    local branch="$1"
    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    
    if [ "$branch" = "$current_branch" ]; then
        echo "Error: Cannot delete the currently checked out branch"
        return 1
    fi
    
    echo "Delete local branch '$branch'? (y/n)"
    read -r confirm
    if [[ "$confirm" == "y" ]]; then
        git branch -d "$branch" || git branch -D "$branch"
    fi
    
    echo "Delete remote branch '$branch'? (y/n)"
    read -r confirm
    if [[ "$confirm" == "y" ]]; then
        git push origin --delete "$branch"
    fi
}

function gclone() {
    ### Clone repository and cd into it
    if [ -z "$1" ]; then
        echo "Usage: gclone <repository-url>"
        return 1
    fi
    
    git clone "$1" && cd "$(basename "$1" .git)" || return 1
}

function gundo() {
    ### Undo last commit (keeps changes staged)
    git reset --soft HEAD~1
}

function gundohard() {
    ### Undo last commit (discards changes)
    echo "WARNING: This will discard all changes in the last commit!"
    echo "Continue? (y/n)"
    read -r confirm
    if [[ "$confirm" == "y" ]]; then
        git reset --hard HEAD~1
    else
        echo "Cancelled"
    fi
}

