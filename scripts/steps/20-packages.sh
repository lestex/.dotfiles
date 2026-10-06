#!/usr/bin/env bash
# Formulae and casks from install/Brewfile and install/Caskfile.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

pretty_print "${green}Installing formulae (install/Brewfile)${neutral}"
brew bundle --file install/Brewfile
# Liga SFMono used to be copied into ~/Library/Fonts from this repo; its cask
# refuses to install over those files, so remove them until the cask is in.
if ! brew list --cask font-sf-mono-nerd-font-ligaturized >/dev/null 2>&1; then
  rm -f "$HOME"/Library/Fonts/LigaSFMonoNerdFont-*.otf
fi
pretty_print "${green}Installing casks (install/Caskfile)${neutral}"
brew bundle --file install/Caskfile
