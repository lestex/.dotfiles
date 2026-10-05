#!/usr/bin/env bash
# Fonts from fonts/, font-switcher and the default font.
#
# font-switcher gives the three terminals their font family and size. Runs
# after 70-configs, whose terminal configs include font-switcher's files.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"

pretty_print "${green}Installing fonts${neutral}"
mkdir -p "$HOME/Library/Fonts"
cp fonts/*.ttf fonts/*.otf "$HOME/Library/Fonts"

# https://github.com/alacritty/alacritty/releases/tag/v0.11.0
defaults write -g AppleFontSmoothing -int 2

pretty_print "${green}Installing font-switcher${neutral}"
mkdir -p "$HOME/.local/bin"
cp local/bin/font-switcher "$HOME/.local/bin/font-switcher"

# A font copied a moment ago may not be registered with macOS yet; then the
# terminals use their default until it is set.
state="$HOME/.local/state/font-switcher/current"
if [ -f "$state/font.name" ]; then
  pretty_print "${yellow}Font $(cat "$state/font.name") already set, skipping ...${neutral}"
elif ! FONT_SWITCHER_NO_RELOAD=1 "$HOME/.local/bin/font-switcher" set "Liga SFMono Nerd Font"; then
  pretty_print "${yellow}Could not set the default font yet; run: font-switcher set \"Liga SFMono Nerd Font\"${neutral}"
fi
# The main configs set no font size either; state from before font-switcher
# owned the size has a family but no size, so give it the default.
if [ ! -f "$state/font.size" ]; then
  FONT_SWITCHER_NO_RELOAD=1 "$HOME/.local/bin/font-switcher" size 14
fi
