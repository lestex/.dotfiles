#!/usr/bin/env bash
# Formulae and casks from install/Brewfile and install/Caskfile.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

pretty_print "${green}Installing formulae (install/Brewfile)${neutral}"
brew bundle --file install/Brewfile
pretty_print "${green}Installing casks (install/Caskfile)${neutral}"
brew bundle --file install/Caskfile
