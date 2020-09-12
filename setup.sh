#!/bin/sh
echo "Setup begins"

#Install homebrew if not installed
if ! command -v brew > /dev/null
then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# Update Homebrew
brew update

read -p "Do you want to install from Brewfile ?" -n 1 -r
echo # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    brew tap homebrew/bundle
    brew bundle
fi

# Use zsh
chsh -s $(which zsh)

# Install prezto
cd $HOME
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done

# Symlinks this repo files to home dir
rm -rf "$HOME/.zshrc"
ln -s "$HOME/.dotfiles/.zshrc" "$HOME/.zshrc"
rm -rf "$HOME/.zpreztorc"
ln -s "$HOME/.dotfiles/.zpreztorc" "$HOME/.zpreztorc"
rm -rf "$HOME/.zprofile"
ln -s "$HOME/.dotfiles/.zprofile" "$HOME/.zprofile"
rm -rf "$HOME/.vimrc"
ln -s "$HOME/.dotfiles/.vimrc" "$HOME/.vimrc"
