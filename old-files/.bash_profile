# Load .bashrc for non-login interactive shells (WSL safe)
if [[ -n $PS1 && -f ~/.bashrc ]]; then . ~/.bashrc; fi
