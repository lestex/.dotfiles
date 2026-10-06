#!/usr/bin/env bash
# Cloud and Kubernetes tools.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

brew_casks gcloud-cli
brew_formulae kubectx krew k9s helm kind podman
