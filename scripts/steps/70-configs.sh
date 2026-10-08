#!/usr/bin/env bash
# Base: configs into ~/.config, tmux plugin manager and link opener, vifm colors.
#
# Configs are copied, not linked: edit them in the repo and re-run this step.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

# zsh is not read from ~/.config: 40-shell installs ~/.zshrc and ~/.zshrc.d.
pretty_print "${green}Copying configs to ~/.config${neutral}"
mkdir -p "$HOME/.config"
for dir in .config/*; do
  [ "$dir" = .config/zsh ] || cp -R "$dir" "$HOME/.config"
done

# Ghostty and Alacritty need an absolute path for the command they launch
# (GUI launches inherit no shell PATH) and the Homebrew prefix differs between
# Apple Silicon and Intel.
sed -i '' "s|@BREW_PREFIX@|$(brew --prefix)|g" "$HOME/.config/ghostty/config" "$HOME/.config/alacritty/alacritty.toml"

# Opens links on Shift+click inside tmux (bound in .config/tmux/tmux.conf).
mkdir -p "$HOME/.local/bin"
cp local/bin/tmux-open-link "$HOME/.local/bin/tmux-open-link"

if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
  pretty_print "${green}Installing tmux plugin manager${neutral}"
  git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
else
  pretty_print "${yellow}tmux plugin manager is already installed, skipping ...${neutral}"
fi

if [ ! -d "$HOME/.config/vifm/colors" ]; then
  pretty_print "${green}Installing vifm color schemes${neutral}"
  git clone https://github.com/vifm/vifm-colors "$HOME/.config/vifm/colors"
else
  pretty_print "${yellow}vifm color schemes are already installed, skipping ...${neutral}"
fi
