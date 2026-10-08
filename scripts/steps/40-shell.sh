#!/usr/bin/env bash
# Base: oh-my-zsh, its plugins, the Pure prompt, ~/.zshrc and ~/.zshrc.d.
#
# Runs after 20-tools: the oh-my-zsh installer clones with git, which on a
# fresh Mac is only a stub until Homebrew has installed the Command Line Tools.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

brew_formulae pure

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

# ~/.zshrc loads oh-my-zsh, then sources ~/.zshrc.d/*.zsh in name order. Only
# the repo's files are replaced there; files of your own are left alone. The
# names installed are recorded, so one the repo has since dropped or renamed is
# removed instead of still being sourced.
pretty_print "${green}Copying .zshrc and .zshrc.d${neutral}"
cp .config/zsh/.zshrc "$HOME/.zshrc"
zshrc_d="$HOME/.zshrc.d"
installed="$HOME/.local/state/dotfiles/zshrc.d"
mkdir -p "$zshrc_d" "$(dirname "$installed")"
if [ -f "$installed" ]; then
  while IFS= read -r name; do
    if [ -n "$name" ] && [ ! -e ".config/zsh/.zshrc.d/$name" ] && [ -f "$zshrc_d/$name" ]; then
      pretty_print "${yellow}Removing ~/.zshrc.d/$name, no longer in the repo${neutral}"
      rm -f "$zshrc_d/$name"
    fi
  done <"$installed"
fi
cp .config/zsh/.zshrc.d/*.zsh "$zshrc_d/"
(cd .config/zsh/.zshrc.d && ls -1 -- *.zsh) >"$installed"
