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

# Path Variables
EDITOR='nvim'
VISUAL='nvim'

# Fzf shell integration
source <(fzf --zsh)
