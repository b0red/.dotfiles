# -----------------------------------------------------------------------------
#
#	.git_aliases
#
# -----------------------------------------------------------------------------

###	Compact, colorized git log
#
alias gl="git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

###	Visualise git log (like gitk, in the terminal)
#
alias lg='git log --graph --full-history --all --color --pretty=format:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s"'

###	Git command shortcuts
#
alias {gstat,gst}='git status' 
# Warning: gst conflicts with gnu-smalltalk (when used).
alias {gbra,gb}='git branch'
alias {gco,go}='git checkout'
alias {gcob,gob}='git checkout -b '
alias {gadd,ga}='git add -A .'
alias {gcom,gc}='git commit -m $1'
alias {gpul,gl}='git pull '
alias {gpus,gh}='git push '
alias {gpullom,gpl}='git pull origin master'
alias {gpushom,gpm}='git push origin master'
alias {gdiff,gd}="git status"
alias gg='git grep '
alias cdgit='cd "$(git rev-parse --show-toplevel 2> /dev/null)"'
alias git-pull-all='find $(git rev-parse --show-toplevel 2> /dev/null) -name .git -type d -execdir git pull -v ";"'
