#!/usr/bin/env bash
# Homebrew, up to date, with its third-party taps trusted.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"

if ! command -v brew >/dev/null 2>&1; then
  pretty_print "${green}Installing Homebrew, follow the instructions...${neutral}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  require_brew
else
  pretty_print "${yellow}Homebrew is already installed, skipping ...${neutral}"
fi

pretty_print "${green}Updating Homebrew${neutral}"
brew update

# oh-my-posh ships from a third-party tap, and Homebrew 6 refuses to load
# formulae from untrusted taps (HOMEBREW_REQUIRE_TAP_TRUST defaults to true).
# The trust store lives under $XDG_CONFIG_HOME, which common points at
# ~/.config, so a manual `brew trust` from an interactive shell does not apply
# here.
pretty_print "${green}Tapping and trusting oh-my-posh${neutral}"
brew tap jandedobbeleer/oh-my-posh
if brew trust --help >/dev/null 2>&1; then
  brew trust --tap jandedobbeleer/oh-my-posh
fi
