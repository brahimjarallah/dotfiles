#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

alias vim='nvim'
export QT_QPA_PLATFORMTHEME=gtk3
ydotoold &
export PATH=$HOME/.npm-global/bin:$PATH
