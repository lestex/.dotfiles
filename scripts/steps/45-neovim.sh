#!/usr/bin/env bash
# Neovim, with LazyVim as its config unless there already is one.
#
# ripgrep, fd, lazygit and tree-sitter-cli are what LazyVim uses (pickers, git
# UI, treesitter parsers; without the CLI nvim-treesitter fetches it through
# mason). Clones the LazyVim starter into ~/.config/nvim and drops its .git, as
# LazyVim's guide does, so the config is the user's own. An existing config is
# never touched. lazy.nvim installs LazyVim, its plugins and the theme's
# colorscheme on the first nvim start; doing that here would also compile
# treesitter parsers, which is slow. Runs before 90-themes, which links
# lua/plugins/theme.lua into the config.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

brew_formulae neovim ripgrep fd lazygit tree-sitter-cli

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
