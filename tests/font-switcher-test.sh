#!/usr/bin/env bash
#
# Tests for local/bin/font-switcher, against a throwaway HOME. The just-installed
# case downloads a monospace font that is not installed (Fira Mono) and copies it
# into that HOME's ~/Library/Fonts, where macOS has not registered it.
#
#   bash tests/font-switcher-test.sh     (from the repo root; needs macOS)

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
COMMAND="$ROOT/local/bin/font-switcher"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

pass() { echo "ok - $1"; }
fail() { echo "not ok - $1" >&2; [[ -z ${2:-} ]] || echo "$2" >&2; exit 1; }

home="$tmp/home"
state="$home/.local/state/font-switcher/current"
mkdir -p "$home/Library/Fonts"
fonts() { HOME="$home" FONT_SWITCHER_NO_RELOAD=1 "$COMMAND" "$@"; }

# --- listing and validation --------------------------------------------------------
# Captured first: under pipefail, grep -q exiting early would fail the pipe.
list=$(fonts list)
grep -qx '  Menlo' <<<"$list" || fail "list shows installed monospace families" "$list"
! grep -qx '  Helvetica' <<<"$list" || fail "list leaves out proportional fonts"
pass "list shows monospace families only"

if fonts set "No Such Font" 2>"$tmp/err"; then fail "an unknown font is refused"; fi
if fonts set 'Menlo"; rm -rf /' 2>"$tmp/err"; then fail "a font name with quotes is refused"; fi
[[ ! -e $state/font.name ]] || fail "a refused font writes no state"
pass "unknown fonts and unsafe names are refused"

fonts set "menlo" >/dev/null
[[ $(cat "$state/font.name") == "Menlo" ]] || fail "names match case-insensitively and are stored as installed"
grep -qx 'font-family = "Menlo"' "$state/ghostty.conf" || fail "ghostty.conf gets the family"
grep -qx 'font_family Menlo' "$state/kitty.conf" || fail "kitty.conf gets the family"
grep -qx 'family = "Menlo"' "$state/alacritty.toml" || fail "alacritty.toml gets the family"
fonts size 16 >/dev/null
grep -qx 'font-size = 16' "$state/ghostty.conf" && grep -qx 'font-family = "Menlo"' "$state/ghostty.conf" || fail "size keeps the family"
pass "set and size write all three terminal files"

# --- a font installed a moment ago -------------------------------------------------
if ! curl -fsSL -o "$tmp/FiraMono-Regular.ttf" https://github.com/google/fonts/raw/main/ofl/firamono/FiraMono-Regular.ttf; then
  echo "skip - could not download Fira Mono; just-installed font not tested"
elif osascript -l JavaScript -e 'ObjC.import("AppKit"); ObjC.deepUnwrap($.NSFontManager.sharedFontManager.availableFontFamilies).includes("Fira Mono")' | grep -q true; then
  echo "skip - Fira Mono is already installed here; just-installed font not tested"
else
  cp "$tmp/FiraMono-Regular.ttf" "$home/Library/Fonts/"
  fonts set "Fira Mono" >/dev/null 2>"$tmp/err" || fail "a font copied into ~/Library/Fonts a moment ago is accepted" "$(cat "$tmp/err")"
  grep -qx 'font-family = "Fira Mono"' "$state/ghostty.conf" || fail "the just-installed font is written"
  osascript -l JavaScript -e 'ObjC.import("AppKit"); ObjC.deepUnwrap($.NSFontManager.sharedFontManager.availableFontFamilies).includes("Fira Mono")' | grep -q false ||
    fail "the lookup leaves nothing registered with macOS"
  pass "a font macOS has not registered yet is still accepted"
fi

echo "all font-switcher tests passed"
