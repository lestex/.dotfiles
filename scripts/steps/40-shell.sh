#!/usr/bin/env bash
# oh-my-zsh, its plugins and ~/.zshrc.
#
# Runs after 10-homebrew: the oh-my-zsh installer clones with git, which on a
# fresh Mac is only a stub until Homebrew has installed the Command Line Tools.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  pretty_print "${green}Installing oh-my-zsh...${neutral}"
  # --unattended: no shell change and no zsh started at the end.
  curl -fsSL https://install.ohmyz.sh | sh -s -- --unattended
else
  pretty_print "${yellow}oh-my-zsh is already installed, skipping ...${neutral}"
fi

plugins="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  if [ ! -d "$plugins/$plugin" ]; then
    pretty_print "${green}Installing zsh plugin $plugin${neutral}"
    git clone --depth=1 "https://github.com/zsh-users/$plugin" "$plugins/$plugin"
  else
    pretty_print "${yellow}zsh plugin $plugin is already installed, skipping ...${neutral}"
  fi
done

pretty_print "${green}Copying .zshrc${neutral}"
cp .config/zsh/.zshrc "$HOME/.zshrc"
