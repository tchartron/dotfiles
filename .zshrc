#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...

# Aliases
alias cod="cd ~/Code"
alias boo="cd ~/Code/web/boootic"
alias t="tmux"
alias v="nvim"
alias gltag="git describe --abbrev=0 --tags"
alias lg="lazygit"
alias ld="lazydocker"
alias stkup="dkc -f ~/Code/web/adcilio/proxy/compose.yaml up -d && dkc -f ~/Code/web/adcilio/dashboard/compose.yaml up -d && dkc -f ~/Code/web/adcilio/showcase/compose.yaml up -d && dkc -f ~/Code/web/adcilio/api/compose.yaml up -d"
alias stkdown="dkc -f ~/Code/web/adcilio/proxy/compose.yaml down && dkc -f ~/Code/web/adcilio/dashboard/compose.yaml down && dkc -f ~/Code/web/adcilio/showcase/compose.yaml down && dkc -f ~/Code/web/adcilio/api/compose.yaml down"
alias proxyup="dkc -f ~/Code/web/adcilio/proxy/compose.yaml up -d"
alias proxydown="dkc -f ~/Code/web/adcilio/proxy/compose.yaml down"
alias ads="cd ~/Code/web/adcilio"

# Path Variables
EDITOR='nvim'
VISUAL='nvim'

# Fzf shell integration
source <(fzf --zsh)
