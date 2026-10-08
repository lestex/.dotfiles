#!/usr/bin/env bash
# Base: Ghostty, kitty, Alacritty (pinned, checksum-verified release) and tmux.
#
# Alacritty: no formula, and the cask is disabled for failing Gatekeeper, so
# install the official release DMG, pinned by version and checksum in
# scripts/common. The app is unsigned; the quarantine flag is cleared only after
# the checksum matches.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

brew_casks ghostty kitty
brew_formulae tmux

installed=$(defaults read /Applications/Alacritty.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || true)
if [ "$installed" = "$ALACRITTY_VERSION" ]; then
  pretty_print "${yellow}Alacritty $ALACRITTY_VERSION is already installed, skipping ...${neutral}"
  exit 0
fi

pretty_print "${green}Installing Alacritty $ALACRITTY_VERSION${neutral}"
tmp=$(mktemp -d)
trap 'hdiutil detach -quiet "$tmp/mnt" 2>/dev/null || true; rm -rf "$tmp"' EXIT

curl -fsSL -o "$tmp/alacritty.dmg" \
  "https://github.com/alacritty/alacritty/releases/download/v$ALACRITTY_VERSION/Alacritty-v$ALACRITTY_VERSION.dmg"
if ! echo "$ALACRITTY_DMG_SHA256  $tmp/alacritty.dmg" | shasum -a 256 -c - >/dev/null; then
  pretty_print "${red}Alacritty DMG checksum mismatch, refusing to install${neutral}"
  exit 1
fi
hdiutil attach -quiet -nobrowse -readonly -mountpoint "$tmp/mnt" "$tmp/alacritty.dmg"
rm -rf /Applications/Alacritty.app
cp -R "$tmp/mnt/Alacritty.app" /Applications/
xattr -dr com.apple.quarantine /Applications/Alacritty.app 2>/dev/null || true
