#!/usr/bin/env bash
# Rust, and the pinned Terraform and Python versions.
#
# Rust via rustup; Terraform and Python at the versions pinned in scripts/common,
# through tfenv and pyenv (installed by 20-packages).
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

if command -v rustup >/dev/null 2>&1 || [ -x "$HOME/.cargo/bin/rustup" ]; then
  pretty_print "${yellow}Rust is already installed, skipping ...${neutral}"
else
  pretty_print "${green}Installing Rust${neutral}"
  curl -fsSL https://sh.rustup.rs | bash -s -- -y
fi

pretty_print "${green}Terraform $TERRAFORM_VERSION (tfenv)${neutral}"
tfenv install "$TERRAFORM_VERSION"
tfenv use "$TERRAFORM_VERSION"

if [ -d "$HOME/.pyenv/versions/$PYTHON_VERSION" ]; then
  pretty_print "${yellow}Python $PYTHON_VERSION is already installed, skipping ...${neutral}"
else
  pretty_print "${green}Installing Python $PYTHON_VERSION (pyenv)${neutral}"
  pyenv install "$PYTHON_VERSION"
fi
