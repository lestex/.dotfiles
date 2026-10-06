#!/usr/bin/env bash
# Language version managers, and the pinned Terraform and Python versions.
#
# Terraform and Python are installed through tfenv and pyenv at the versions
# pinned in scripts/common.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

brew_formulae tfenv pyenv goenv node nvm

pretty_print "${green}Terraform $TERRAFORM_VERSION (tfenv)${neutral}"
tfenv install "$TERRAFORM_VERSION"
tfenv use "$TERRAFORM_VERSION"

if [ -d "$HOME/.pyenv/versions/$PYTHON_VERSION" ]; then
  pretty_print "${yellow}Python $PYTHON_VERSION is already installed, skipping ...${neutral}"
else
  pretty_print "${green}Installing Python $PYTHON_VERSION (pyenv)${neutral}"
  pyenv install "$PYTHON_VERSION"
fi
