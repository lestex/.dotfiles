#!/usr/bin/env bash
# Base: mise; packages: the languages and tools in .config/mise/config.toml.
#
# mise manages Python, Go, Terraform, Node and the AWS CLI in place of pyenv,
# goenv, tfenv and nvm. The versions live in .config/mise/config.toml, which
# 70-configs copies into ~/.config/mise; this step installs from the repo's copy,
# since it runs first. mise install skips what is already installed.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

brew_formulae mise

pretty_print "${green}Installing tools from .config/mise/config.toml (mise)${neutral}"
MISE_GLOBAL_CONFIG_FILE="$PWD/.config/mise/config.toml" mise install --yes
