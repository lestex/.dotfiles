#!/usr/bin/env bash
# Desktop apps.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

apps=(
  google-chrome
  bitwarden
  rectangle
  # daisydisk
  vlc
  # slack
  telegram
)
brew_casks "${apps[@]}"
