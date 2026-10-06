#!/usr/bin/env bash
# Desktop apps.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

brew_casks \
  google-chrome bitwarden rectangle daisydisk vlc \
  slack telegram
