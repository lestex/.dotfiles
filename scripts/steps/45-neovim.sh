#!/usr/bin/env bash
# LazyVim as the Neovim config, unless there already is one.
#
# Clones the LazyVim starter into ~/.config/nvim and drops its .git, as
# LazyVim's guide does, so the config is the user's own. An existing config is
# never touched. lazy.nvim installs LazyVim, its plugins and the theme's
# colorscheme on the first nvim start; doing that here would also compile
# treesitter parsers, which is slow. Runs before 90-themes, which links
# lua/plugins/theme.lua into the config.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"

nvim_dir="$HOME/.config/nvim"
if [ -e "$nvim_dir" ]; then
  pretty_print "${yellow}A Neovim config already exists in ~/.config/nvim, skipping ...${neutral}"
  exit 0
fi

pretty_print "${green}Installing LazyVim into ~/.config/nvim${neutral}"
mkdir -p "$HOME/.config"
git clone --quiet --depth 1 https://github.com/LazyVim/starter "$nvim_dir"
rm -rf "$nvim_dir/.git"
pretty_print "${green}LazyVim installs its plugins the first time you start nvim${neutral}"
