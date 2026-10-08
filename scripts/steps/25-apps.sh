#!/usr/bin/env bash
# Packages: desktop apps.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

# Comment out what you don't want.
apps=(
  google-chrome
  bitwarden
  rectangle
  # daisydisk
  vlc
  # slack
  telegram
)
brew_casks ${apps[@]+"${apps[@]}"}
