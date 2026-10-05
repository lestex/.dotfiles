#!/usr/bin/env bash
#
# Set up this Mac from these dotfiles. Safe to re-run.
#
# From a checkout:   ./install.sh [step ...]
# On a fresh Mac:    bash <(curl -fsSL https://raw.githubusercontent.com/lestex/.dotfiles/master/install.sh)
#
# The setup is a series of independent steps in scripts/steps/ (NN-name.sh, run
# in NN order). With no arguments all of them run; name steps to run just those,
# in the order given (e.g. ./install.sh fonts themes). --list shows them. A step
# can also be run on its own: scripts/steps/80-fonts.sh.
#
# Run from a checkout, it uses that checkout. Otherwise it fetches the repo into
# $DOTFILES_DIR (default ~/.dotfiles) and keeps it updated on later runs: a git
# checkout there is pulled, a downloaded copy is replaced. DOTFILES_REPO points
# it at another copy of the repo (a fork).

set -euo pipefail

usage() {
  sed -n '3,16p' "${BASH_SOURCE[0]:-install.sh}" 2>/dev/null | sed 's/^# \{0,1\}//' ||
    echo "Usage: install.sh [--list] [step ...]"
}

list_only=0
requested=()
for arg in "$@"; do
  case "$arg" in
    -h | --help) usage; exit 0 ;;
    -l | --list) list_only=1 ;;
    -*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *) requested+=("$arg") ;;
  esac
done

REPO="${DOTFILES_REPO:-https://github.com/lestex/.dotfiles}"
TARGET="${DOTFILES_DIR:-$HOME/.dotfiles}"

if [[ $(uname) != "Darwin" ]]; then
  echo "These dotfiles support macOS only." >&2
  exit 1
fi

# On a fresh Mac, git is a stub that asks to install the Command Line Tools
# (Homebrew installs them later, in steps/10-homebrew), so fetch with curl and tar.
download() {
  local tmp
  tmp=$(mktemp -d)
  echo "Downloading $REPO into $TARGET ..."
  curl -fsSL "$REPO/archive/refs/heads/master.tar.gz" | tar -xz -C "$tmp" --strip-components=1
  rm -rf "$TARGET"
  mkdir -p "$(dirname "$TARGET")"
  mv "$tmp" "$TARGET"
}

# Only a script read from a regular file can be inside a checkout. Under
# `bash <(curl ...)` BASH_SOURCE is a pipe (/dev/fd/N), and under `curl | bash`
# it is empty; the current directory must not count then, or running the
# one-liner from inside any checkout would set up from that checkout instead.
source_dir=""
if [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]]; then
  source_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi
if [[ -n $source_dir && -d $source_dir/scripts/steps ]]; then
  cd "$source_dir"
elif [[ -d $TARGET/.git ]]; then
  echo "Updating $TARGET ..."
  git -C "$TARGET" pull --ff-only
  cd "$TARGET"
else
  download
  cd "$TARGET"
fi

steps=(scripts/steps/[0-9][0-9]-*.sh)

step_name() {
  local name
  name=$(basename "$1" .sh)
  printf '%s' "${name#[0-9][0-9]-}"
}

if (( list_only )); then
  for step in "${steps[@]}"; do
    printf '%-12s %s\n' "$(step_name "$step")" "$(sed -n '2s/^# //p' "$step")"
  done
  exit 0
fi

# Resolve requested names (with or without the NN- prefix) before running
# anything, so a typo does not leave a half-run setup behind.
selected=()
if (( ${#requested[@]} == 0 )); then
  selected=("${steps[@]}")
else
  for name in "${requested[@]}"; do
    match=""
    for step in "${steps[@]}"; do
      if [[ $name == "$(step_name "$step")" || $name == "$(basename "$step" .sh)" ]]; then
        match="$step"
      fi
    done
    if [[ -z $match ]]; then
      echo "Unknown step: $name (see ./install.sh --list)" >&2
      exit 1
    fi
    selected+=("$match")
  done
fi

for step in "${selected[@]}"; do
  printf '\n\033[1m==> %s\033[0m\n' "$(step_name "$step")"
  if ! "$step"; then
    echo "Step $(step_name "$step") failed; fix it and re-run: ./install.sh $(step_name "$step")" >&2
    exit 1
  fi
done

printf '\n\033[0;32mAll done.\033[0m\n'
