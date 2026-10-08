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
# settings.json as strict JSON: comment lines and trailing commas dropped.
settings_json() { sed '/^[[:space:]]*\/\//d' "$settings" | perl -0pe 's/,(\s*[}\]])/$1/g'; }
generated="$home/.local/state/theme-switcher/current/theme/vscode-theme.json"

# A local extension left by an earlier version is removed.
mkdir -p "$home/.vscode/extensions/theme-switcher-theme"
echo '[{"identifier":{"id":"local.theme-switcher-theme"}},{"identifier":{"id":"someone.else"}}]' >"$home/.vscode/extensions/extensions.json"

mkdir -p "$home/.config/theme-switcher/themes/plain"
cp "$ENGINE/themes/nord/colors.toml" "$home/.config/theme-switcher/themes/plain/"
theme set plain >/dev/null 2>"$tmp/err" || fail "set applies a theme without vscode.json" "$(cat "$tmp/err")"
[[ $(color_theme) == "Dark Modern" ]] || fail "a dark generated theme selects Dark Modern" "$(color_theme)"
for key in workbench.colorCustomizations editor.tokenColorCustomizations editor.semanticTokenColorCustomizations; do
  [[ $(grep -c "\"$key\"" "$settings") == 1 ]] || fail "$key is written once, on one line" "$(grep -n "$key" "$settings" | cut -c1-120)"
done
settings_json | jq -e --slurpfile g "$generated" '
  .["workbench.colorCustomizations"]["[Dark Modern]"] == $g[0].colors and
  .["editor.tokenColorCustomizations"]["[Dark Modern]"].textMateRules == $g[0].tokenColors and
  .["editor.semanticTokenColorCustomizations"]["[Dark Modern]"].rules == $g[0].semanticTokenColors' >/dev/null ||
  fail "the generated colors, token and semantic colors are overrides on Dark Modern"
grep -q '// comments and trailing commas survive' "$settings" || fail "the rest of settings.json is kept"
[[ ! -e $home/.vscode/extensions/theme-switcher-theme ]] &&
  jq -e 'map(.identifier.id) == ["someone.else"]' "$home/.vscode/extensions/extensions.json" >/dev/null ||
  fail "the old local extension is removed, other extensions kept" "$(cat "$home/.vscode/extensions/extensions.json")"
pass "a dark theme without an extension becomes overrides on Dark Modern"

theme set lupine >/dev/null
[[ $(color_theme) == "Light Modern" ]] || fail "a light generated theme selects Light Modern" "$(color_theme)"
for key in workbench.colorCustomizations editor.tokenColorCustomizations editor.semanticTokenColorCustomizations; do
  [[ $(grep -c "\"$key\"" "$settings") == 1 ]] || fail "$key is replaced, not added again"
done
settings_json | jq -e --slurpfile g "$generated" '
  (.["workbench.colorCustomizations"] | keys) == ["[Light Modern]"] and
  .["workbench.colorCustomizations"]["[Light Modern]"]["editor.background"] == $g[0].colors["editor.background"]' >/dev/null ||
  fail "switching replaces the overrides with the light theme's"
pass "a light theme replaces them, on Light Modern"

theme set tokyo-night >/dev/null
[[ $(color_theme) == "$name" ]] || fail "a Marketplace theme is selected again" "$(color_theme)"
! grep -qE 'workbench.colorCustomizations|editor.tokenColorCustomizations|editor.semanticTokenColorCustomizations' "$settings" ||
  fail "a Marketplace theme removes the overrides" "$(grep -n Customizations "$settings" | cut -c1-120)"
settings_json | jq -e . >/dev/null || fail "settings.json stays valid" "$(cat "$settings")"
pass "a Marketplace theme removes the overrides"

# Overrides of your own, over several lines, are left alone.
awk 'NR==1 { print; print "  \"workbench.colorCustomizations\": {"; print "    \"editor.background\": \"#123456\""; print "  },"; next } { print }' "$settings" >"$tmp/s" && cat "$tmp/s" >"$settings"
theme set plain >/dev/null 2>"$tmp/err"
grep -q '"editor.background": "#123456"' "$settings" || fail "your own colorCustomizations are kept"
grep -q "workbench.colorCustomizations in VS Code's settings.json is your own" "$tmp/err" || fail "and you are told" "$(cat "$tmp/err")"
[[ $(grep -c '"editor.tokenColorCustomizations"' "$settings") == 1 ]] || fail "the other overrides are still applied"
pass "overrides of your own are left alone"

# --- an empty settings.json, VS Code off THEME_SWITCHER_APPS, and the subcommand -----
rm "$settings"
theme vscode >/dev/null
[[ $(color_theme) == "Dark Modern" ]] && settings_json | jq -e '.["workbench.colorCustomizations"]["[Dark Modern]"] | length > 100' >/dev/null ||
  fail "a missing settings.json is created" "$(head -c 300 "$settings" 2>&1)"
pass "theme-switcher vscode creates settings.json"

before=$(cat "$settings")
env -u TMUX TMUX_TMPDIR="$tmp/sock" HOME="$home" PATH="$tmp/bin:$PATH" THEME_SWITCHER_ENGINE="$ENGINE" \
  THEME_SWITCHER_NO_DESKTOP=1 THEME_SWITCHER_TERMINALS="" THEME_SWITCHER_APPS="" "$COMMAND" set tokyo-night >/dev/null
[[ $(cat "$settings") == "$before" ]] || fail "THEME_SWITCHER_APPS without code leaves VS Code alone"
pass "VS Code is only touched when code is in THEME_SWITCHER_APPS"

echo "all vscode-theme tests passed"
