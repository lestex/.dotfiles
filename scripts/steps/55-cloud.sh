#!/usr/bin/env bash
# Packages: cloud and Kubernetes tools.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

# Comment out what you don't want.
casks=(
  gcloud-cli
)
formulae=(
  kubectx
  krew
  k9s
  helm
  kind
  podman
)
brew_casks ${casks[@]+"${casks[@]}"}
brew_formulae ${formulae[@]+"${formulae[@]}"}
