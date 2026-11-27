#
# ~/.bashrc (bash stow package). Arch default + Starship prompt.
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Fallback prompt; Starship replaces it when installed.
PS1='[\u@\h \W]\$ '
if command -v starship >/dev/null; then
    eval "$(starship init bash)"
fi
