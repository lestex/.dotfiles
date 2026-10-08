#!/usr/bin/env bash
#
# Tests terminal-switcher in a throwaway HOME: names it accepts, the state file
# Hammerspoon reads, and that an unknown name changes nothing.
#
#   bash tests/terminal-switcher-test.sh     (from the repo root)

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
COMMAND="$ROOT/local/bin/terminal-switcher"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
state="$tmp/.local/state/terminal-switcher/current"

pass() { echo "ok - $1"; }
fail() { echo "not ok - $1" >&2; [[ -z ${2:-} ]] || echo "$2" >&2; exit 1; }
ts() { env HOME="$tmp" "$COMMAND" "$@"; }

for name in ghostty alacritty kitty; do
  ts "$name" >/dev/null || fail "$name is accepted"
  [[ $(cat "$state") == "$name" ]] || fail "$name is written for Hammerspoon" "$(cat "$state")"
done
pass "ghostty, alacritty and kitty are set"

! ts iterm >/dev/null 2>"$tmp/err" || fail "an unknown terminal is refused"
grep -q 'one of: ghostty alacritty kitty' "$tmp/err" || fail "and the choices are named" "$(cat "$tmp/err")"
[[ $(cat "$state") == "kitty" ]] || fail "a refused name leaves the choice as it was"
! ts Kitty >/dev/null 2>&1 || fail "names are lowercase only"
pass "anything else is refused and changes nothing"

ts --help | grep -q 'ghostty|alacritty|kitty' || fail "--help shows the usage"
pass "--help shows the usage"

echo "all terminal-switcher tests passed"
