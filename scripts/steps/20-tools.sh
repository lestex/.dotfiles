#!/usr/bin/env bash
# Command-line tools, including those the later steps and theme-switcher use.
#
# git (oh-my-zsh, tpm and LazyVim clone with it; on a fresh Mac it is only a
# stub until Homebrew has installed the Command Line Tools), bash 5 and jq
# (theme-switcher's engine and its VS Code support), fzf (the theme and font
# pickers).
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

brew_formulae \
  git bash jq fzf coreutils findutils gnupg gh watch tree \
  htop btop fastfetch mole vifm ssh-copy-id telnet \
  mpv ollama  # mpv as a formula: its cask was disabled on 2026-09-01
