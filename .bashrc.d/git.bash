# -----------------------------------------------------------------------------
#
#	.git_aliases
#
# -----------------------------------------------------------------------------

###		Compact, colorized git log
#
alias gl="git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

###	Visualise git log (like gitk, in the terminal)
#
alias lg='git log --graph --full-history --all --color --pretty=format:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s"'

###		Git command shortcuts
#
alias g="git"
alias gm="git merge"
alias gmv="git mv"
alias {gstat,gs}='git status' 
alias gss="git status -s"
alias {gbra,gb}='git branch'
alias gc="git clone"
alias {gco,go}='git checkout'
alias {gcob,gob}='git checkout -b '
alias {gadd,ga}='git add -A .'
alias {gcom,gc}='git commit -m $1'
alias {gpul,gl}='git pull '
alias {gpus,gp}='git push '
alias {gpullom,g_pull}='git pull origin master'
alias {gpushom,g_push}='git push origin master'
alias gg='git grep '
alias cdgit='cd "$(git rev-parse --show-toplevel 2> /dev/null)"'
alias git-pull-all='find $(git rev-parse --show-toplevel 2> /dev/null) -name .git -type d -execdir git pull -v ";"'
alias glum="git pull upstream master"
alias gpr="git pull --rebase"
alias gppd="git pull && git push origin develop"
alias ggpm="git pull && git push origin master"
alias gfrb="git fetch && git rebase"

###     git functions
#
function gcp() {
          git commit -am "$1" && git push origin master
      }

###     Just checking
#
# echo ${file##*/}
