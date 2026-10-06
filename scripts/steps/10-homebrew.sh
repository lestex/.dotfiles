#!/usr/bin/env bash
# Homebrew, up to date.
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
