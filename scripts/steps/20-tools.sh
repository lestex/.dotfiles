#!/usr/bin/env bash
# Packages: command-line tools (git, bash, jq and fzf are base).
#
# The base tools are what the framework itself runs on: git (oh-my-zsh, tpm and
# LazyVim clone with it; on a fresh Mac it is only a stub until Homebrew has
# installed the Command Line Tools), bash 5 and jq (theme-switcher, its engine
# and VS Code support), fzf (the theme, font and terminal pickers).
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

# Base: keep these.
brew_formulae git bash jq fzf

# Comment out what you don't want.
packages=(
  coreutils
  findutils
  gnupg
  gh
  watch
  tree
  htop
  btop
  fastfetch
  mole
  vifm
  ssh-copy-id
  telnet
  mpv # as a formula: its cask was disabled on 2026-09-01
  ollama
)
brew_formulae ${packages[@]+"${packages[@]}"}
