#!/usr/bin/env bash
#
# Set up this Mac from these dotfiles. Safe to re-run.
#
# From a checkout:   ./install.sh
# On a fresh Mac:    bash <(curl -fsSL https://raw.githubusercontent.com/lestex/.dotfiles/master/install.sh)
#
# Run from a checkout, it uses that checkout. Otherwise it fetches the repo into
# $DOTFILES_DIR (default ~/.dotfiles) and keeps it updated on later runs: a git
# checkout there is pulled, a downloaded copy is replaced. DOTFILES_REPO points
# it at another copy of the repo (a fork).

set -euo pipefail

REPO="${DOTFILES_REPO:-https://github.com/lestex/.dotfiles}"
TARGET="${DOTFILES_DIR:-$HOME/.dotfiles}"

if [[ $(uname) != "Darwin" ]]; then
  echo "These dotfiles support macOS only." >&2
  exit 1
fi

# On a fresh Mac, git is a stub that asks to install the Command Line Tools
# (Homebrew installs them later, in mac-setup), so fetch with curl and tar.
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
if [[ -n $source_dir && -f $source_dir/scripts/mac-setup ]]; then
  cd "$source_dir"
elif [[ -d $TARGET/.git ]]; then
  echo "Updating $TARGET ..."
  git -C "$TARGET" pull --ff-only
  cd "$TARGET"
else
  download
  cd "$TARGET"
fi

# mac-setup keeps Homebrew's tap trust store and other XDG config in ~/.config.
export XDG_CONFIG_HOME="$HOME/.config"
exec scripts/mac-setup
