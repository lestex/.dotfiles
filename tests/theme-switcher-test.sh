#!/usr/bin/env bash
#
# Tests for local/bin/theme-switcher. Runs against a throwaway HOME, a fake
# terminal and a stub osascript, so the real desktop and terminals are untouched.
#
#   tests/theme-switcher-test.sh     (from the repo root; needs macOS and an installed theme engine)

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
COMMAND="$ROOT/local/bin/theme-switcher"

if [[ $(uname) != "Darwin" ]] || ! "$COMMAND" list >/dev/null 2>&1; then
  # CI installs the pinned engine with `make` first, so there a missing engine
  # is a failure, not a reason to skip.
  if [[ ${THEME_SWITCHER_TEST_REQUIRE_ENGINE:-} == "1" ]]; then
    echo "not ok - theme engine is installed (run: theme-switcher engine install <sha>)" >&2
    exit 1
  fi
  echo "skip - needs macOS and an installed theme engine (theme-switcher engine install <sha>)"
  exit 0
fi

# Resolve the engine against the real HOME before switching to a throwaway one.
THEME_SWITCHER_ENGINE=$("$COMMAND" engine)
export THEME_SWITCHER_ENGINE

tmp=$(mktemp -d)
cleanup() {
  pkill -f "$tmp/bin/faketerm" 2>/dev/null || true
  rm -rf "$tmp"
}
trap cleanup EXIT

pass() { echo "ok - $1"; }
fail() { echo "not ok - $1" >&2; [[ -z ${2:-} ]] || echo "$2" >&2; exit 1; }

home="$tmp/home"
state="$home/.local/state/theme-switcher/current"
mkdir -p "$home" "$tmp/bin"

# osascript stub: records the picture path it was asked to set.
cat >"$tmp/bin/osascript" <<SH
#!/bin/sh
printf '%s\n' "\$2" >"$tmp/desktop"
SH
chmod +x "$tmp/bin/osascript"

theme() {
  HOME="$home" PATH="$tmp/bin:$PATH" THEME_SWITCHER_TERMINALS="faketerm" "$COMMAND" "$@"
}

# --- set ---------------------------------------------------------------------
theme set "Tokyo Night" >/dev/null 2>"$tmp/err" || fail "set applies a shipped theme" "$(cat "$tmp/err")"
[[ $(theme current) == "tokyo-night" ]] || fail "set records the theme name"
for file in ghostty.conf alacritty.toml kitty.conf; do
  [[ -f $state/theme/$file ]] || fail "set generates $file"
done
grep -q '^background = #1a1b26$' "$state/theme/ghostty.conf" || fail "ghostty.conf carries the palette background"
! grep -rIqE '\{\{[^}]*\}\}' "$state/theme" || fail "no placeholder survives rendering"
[[ ! -e $state/theme/backgrounds ]] || fail "backgrounds are not copied into the state dir"
[[ $(ls "$home/.local/state") == "theme-switcher" && ! -e $home/.config ]] || fail "the engine writes nothing outside theme-switcher's own dirs" "$(ls "$home/.local/state" "$home/.config" 2>&1)"
first=$(head -n 1 "$state/background")
[[ $first == "$home/.local/share/theme-switcher/tokyo-night/backgrounds/"* && -f $first ]] || fail "set picks an imported background" "$first"
[[ $first =~ \.(jpe?g|png)$ ]] || fail "the theme ships a jpeg or png background" "$first"
[[ $(cat "$tmp/desktop") == "$first" ]] || fail "a jpeg or png background reaches the desktop as-is" "$(cat "$tmp/desktop")"
pass "set renders, imports backgrounds and sets the desktop"

# --- refusal -----------------------------------------------------------------
mkdir -p "$home/.config/theme-switcher/themed"
printf 'x = "{{ not_a_palette_key }}"\n' >"$home/.config/theme-switcher/themed/broken.conf.tpl"
if theme set nord >/dev/null 2>"$tmp/err"; then
  fail "an unresolved placeholder refuses the theme"
fi
grep -q 'not_a_palette_key' "$tmp/err" || fail "the refusal names the placeholder" "$(cat "$tmp/err")"
[[ $(theme current) == "tokyo-night" ]] || fail "the current theme stays applied"
[[ ! -e $state/next-theme ]] || fail "staging is cleaned up"
rm "$home/.config/theme-switcher/themed/broken.conf.tpl"
pass "an unresolved placeholder keeps the current theme"

# --- terminals ---------------------------------------------------------------
ln -s /usr/bin/script "$tmp/bin/faketerm"
"$tmp/bin/faketerm" -q /dev/null sleep 30 >"$tmp/screen" 2>&1 </dev/null &
for _ in {1..50}; do
  pid=$(pgrep -x faketerm || true)
  [[ -n $pid ]] && [[ -n $(pgrep -P "$pid" || true) ]] && break
  sleep 0.1
done
[[ -n ${pid:-} ]] || fail "fake terminal starts"

theme set nord >/dev/null 2>"$tmp/err" || fail "set applies with a running terminal" "$(cat "$tmp/err")"
sleep 0.3
screen=$(cat "$tmp/screen")
[[ $screen == *$'\e]11;#2e3440\a'* ]] || fail "the running terminal receives OSC 11 with the nord background" "$(printf '%q' "$screen")"
[[ $screen == *$'\e]4;15;'* ]] || fail "the running terminal receives the ANSI palette"
pass "a running terminal is repainted through its child's tty"

# --- background ----------------------------------------------------------------
theme bg none
[[ -z $(head -n 1 "$state/background") ]] || fail "bg none empties the background state"
solid=$(cat "$tmp/desktop")
[[ $solid == *solid-2e3440.png ]] || fail "bg none sets a solid image named by the palette color" "$solid"
sips -s format bmp "$solid" --out "$tmp/solid.bmp" >/dev/null
pixel=$(od -An -tx1 -j "$(( $(od -An -tu4 -j 10 -N 4 "$tmp/solid.bmp") ))" -N 3 "$tmp/solid.bmp" | tr -d ' \n')
[[ $pixel == "40342e" || $pixel == "40342eff" ]] || fail "the solid image is the palette background (BGR)" "$pixel"
pass "bg none shows the solid theme color"

theme bg next >/dev/null
one=$(head -n 1 "$state/background")
theme bg next >/dev/null
two=$(head -n 1 "$state/background")
[[ -n $one && -n $two && $one != "$two" ]] || fail "bg next cycles backgrounds" "$one / $two"
pass "bg next cycles the theme's backgrounds"

cp "$solid" "$tmp/mine.png"
theme bg set "$tmp/mine.png"
[[ $(head -n 1 "$state/background") == "$tmp/mine.png" ]] || fail "bg set stores the path as text"
[[ $(cat "$tmp/desktop") == "$tmp/mine.png" ]] || fail "bg set applies a png as-is"
[[ -f $state/background && ! -L $state/background ]] || fail "background state is a plain file"
pass "bg set stores a plain-text path"

# Formats the desktop may not accept (webp, tiff, ...) are converted to png.
sips -s format tiff "$solid" --out "$tmp/mine.tiff" >/dev/null
theme bg set "$tmp/mine.tiff"
converted=$(cat "$tmp/desktop")
[[ $converted == "$home/.cache/theme-switcher/desktop/"*.png && -f $converted ]] || fail "a tiff background reaches the desktop as png" "$converted"
[[ $(head -n 1 "$state/background") == "$tmp/mine.tiff" ]] || fail "the state keeps the original path"
pass "other image formats reach the desktop as png"

echo "all theme-switcher tests passed"
