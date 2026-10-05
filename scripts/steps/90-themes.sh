#!/usr/bin/env bash
# theme-switcher, its pinned theme engine and the default theme.
#
# The engine is fetched at the commit pinned by
# THEME_ENGINE_REF in scripts/common (a sparse checkout under
# ~/.local/share/theme-switcher/.engine; rerunning at the same commit is a
# no-op). Runs after 70-configs: Ghostty, Alacritty, kitty and tmux include the
# files it generates.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"

pretty_print "${green}Installing theme-switcher${neutral}"
mkdir -p "$HOME/.local/bin"
cp local/bin/theme-switcher "$HOME/.local/bin/theme-switcher"

state="$HOME/.local/state/theme-switcher/current"
if ! "$HOME/.local/bin/theme-switcher" engine install "$THEME_ENGINE_REF"; then
  pretty_print "${yellow}Could not install the theme engine, skipping theme setup ...${neutral}"
elif [ -f "$state/theme.name" ]; then
  pretty_print "${yellow}Theme $(cat "$state/theme.name") already set, skipping ...${neutral}"
else
  # Generate the files only: no desktop change or terminal repaint during setup.
  THEME_SWITCHER_NO_DESKTOP=1 THEME_SWITCHER_TERMINALS="" "$HOME/.local/bin/theme-switcher" set tokyo-night
fi
