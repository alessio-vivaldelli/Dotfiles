#
# ~/.bashrc
#
eval "$(starship init bash)"
bind 'TAB:menu-complete'
bind 'set show-all-if-ambiguous on'

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='eza -lah -G --icons --color=auto'
alias lls='eza -a --long --icons'
alias tree='eza --tree --icons -a'
alias grep='grep --color=auto'
alias mkdir='mkdir -pZ'
PS1='[\u@\h \W]\$ '

export PATH=$PATH:/home/alessio/.spicetify


#######################################################
# EXPORTS
#######################################################

# Disable the bell
if [[ $iatest > 0 ]]; then bind "set bell-style visible"; fi

# Expand the history size
export HISTFILESIZE=10000
export HISTSIZE=500

# Don't put duplicate lines in the history and do not add lines that start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Show auto-completion list automatically, without double tab
if [[ $iatest > 0 ]]; then bind "set show-all-if-ambiguous On"; fi

source ~/.local/share/blesh/ble.sh
source /usr/share/nvm/init-nvm.sh
