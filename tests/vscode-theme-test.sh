#!/usr/bin/env bash
#
# Tests theme-switcher's VS Code support: a theme's Marketplace extension, the
# local extension serving a theme generated from the palette, and the in-place
# edit of a JSONC settings.json. Offline: a stub `code` records what would be
# installed, in a throwaway HOME.
#
#   bash tests/vscode-theme-test.sh     (from the repo root; needs macOS, jq and an installed theme engine)

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
COMMAND="$ROOT/local/bin/theme-switcher"

if [[ $(uname) != "Darwin" ]] || ! "$COMMAND" list >/dev/null 2>&1 || ! command -v jq >/dev/null; then
  if [[ ${THEME_SWITCHER_TEST_REQUIRE_ENGINE:-} == "1" ]]; then
    echo "not ok - theme engine and jq are installed" >&2
    exit 1
  fi
  echo "skip - needs macOS, jq and an installed theme engine"
  exit 0
fi
ENGINE=$("$COMMAND" engine)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
home="$tmp/home"
mkdir -p "$home" "$tmp/bin" "$tmp/sock"

pass() { echo "ok - $1"; }
fail() { echo "not ok - $1" >&2; [[ -z ${2:-} ]] || echo "$2" >&2; exit 1; }

# A stub `code`: extensions "installed" are lines in a file.
cat >"$tmp/bin/code" <<'SH'
#!/bin/bash
db="$HOME/code-extensions"
case "$1" in
  --list-extensions) cat "$db" 2>/dev/null || true ;;
  --install-extension) echo "$2" >>"$db" ;;
esac
SH
chmod +x "$tmp/bin/code"

theme() {
  env -u TMUX TMUX_TMPDIR="$tmp/sock" HOME="$home" PATH="$tmp/bin:$PATH" THEME_SWITCHER_ENGINE="$ENGINE" \
    THEME_SWITCHER_NO_DESKTOP=1 THEME_SWITCHER_TERMINALS="" THEME_SWITCHER_APPS="code" "$COMMAND" "$@"
}
settings="$home/Library/Application Support/Code/User/settings.json"
color_theme() { sed -n 's/.*"workbench\.colorTheme"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$settings"; }
wait_for() { for _ in $(seq 1 50); do eval "$1" && return 0; sleep 0.1; done; return 1; }

# --- a theme with a Marketplace extension ------------------------------------------
mkdir -p "$(dirname "$settings")"
cat >"$settings" <<'JSON'
{
  // comments and trailing commas survive
  "editor.fontSize": 13,
}
JSON
name=$(jq -r .name "$ENGINE/themes/tokyo-night/vscode.json")
extension=$(jq -r .extension "$ENGINE/themes/tokyo-night/vscode.json")
theme set tokyo-night >/dev/null 2>"$tmp/err" || fail "set applies a theme" "$(cat "$tmp/err")"
wait_for 'grep -qx "$extension" "$home/code-extensions" 2>/dev/null' || fail "the theme's extension is installed"
wait_for '[[ $(color_theme) == "$name" ]]' || fail "the extension's theme is selected" "$(cat "$settings")"
grep -q '// comments and trailing commas survive' "$settings" && grep -q '"editor.fontSize": 13,' "$settings" ||
  fail "the rest of settings.json is left as it was" "$(cat "$settings")"
pass "a theme's Marketplace extension is installed and selected"

theme set tokyo-night >/dev/null
[[ $(grep -cx "$extension" "$home/code-extensions") == 1 ]] || fail "an installed extension is not installed again"
[[ $(grep -c workbench.colorTheme "$settings") == 1 ]] || fail "colorTheme is replaced, not added twice" "$(cat "$settings")"
pass "an installed extension is reused"

# --- a theme generated from the palette ----------------------------------------------
mkdir -p "$home/.config/theme-switcher/themes/plain"
cp "$ENGINE/themes/nord/colors.toml" "$home/.config/theme-switcher/themes/plain/"
theme set plain >/dev/null 2>"$tmp/err" || fail "set applies a theme without vscode.json" "$(cat "$tmp/err")"
local_ext="$home/.vscode/extensions/theme-switcher-theme"
[[ -L $local_ext/themes/color-theme.json && -f $local_ext/themes/color-theme.json ]] ||
  fail "the local extension links the generated theme" "$(ls -l "$local_ext/themes" 2>&1)"
jq -e '.contributes.themes | length == 2' "$local_ext/package.json" >/dev/null || fail "the local extension contributes the theme"
jq -e 'map(select(.identifier.id == "local.theme-switcher-theme")) | length == 1' "$home/.vscode/extensions/extensions.json" >/dev/null ||
  fail "the local extension is registered" "$(cat "$home/.vscode/extensions/extensions.json")"
first=$(color_theme)
[[ $first == "Theme Switcher"* ]] || fail "the generated theme is selected" "$first"
pass "a theme without an extension is generated and selected"

theme set plain >/dev/null
second=$(color_theme)
[[ $second == "Theme Switcher"* && $second != "$first" ]] || fail "each switch selects the other label" "$first / $second"
jq -e 'map(select(.identifier.id == "local.theme-switcher-theme")) | length == 1' "$home/.vscode/extensions/extensions.json" >/dev/null ||
  fail "the local extension is registered once"
pass "re-applying swaps labels, so VS Code re-reads the theme"

# --- an empty settings.json, VS Code off THEME_SWITCHER_APPS, and the subcommand -----
rm "$settings"
theme vscode >/dev/null
[[ $(color_theme) == "Theme Switcher"* ]] && jq -e . "$settings" >/dev/null || fail "a missing settings.json is created" "$(cat "$settings" 2>&1)"
pass "theme-switcher vscode creates settings.json"

before=$(cat "$settings")
env -u TMUX TMUX_TMPDIR="$tmp/sock" HOME="$home" PATH="$tmp/bin:$PATH" THEME_SWITCHER_ENGINE="$ENGINE" \
  THEME_SWITCHER_NO_DESKTOP=1 THEME_SWITCHER_TERMINALS="" THEME_SWITCHER_APPS="" "$COMMAND" set tokyo-night >/dev/null
[[ $(cat "$settings") == "$before" ]] || fail "THEME_SWITCHER_APPS without code leaves VS Code alone"
pass "VS Code is only touched when code is in THEME_SWITCHER_APPS"

echo "all vscode-theme tests passed"
