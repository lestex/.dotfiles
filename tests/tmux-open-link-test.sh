#!/usr/bin/env bash
#
# Tests for local/bin/tmux-open-link and the Shift+click binding in
# .config/tmux/tmux.conf. A stub `open` records what would be opened; the tmux
# part runs a private server (never the user's) driven through a real client.
#
#   bash tests/tmux-open-link-test.sh     (from the repo root; needs macOS)

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
COMMAND="$ROOT/local/bin/tmux-open-link"

tmp=$(mktemp -d)
tmx() { env -u TMUX TMUX_TMPDIR="$tmp/sock" tmux "$@"; }
cleanup() {
  tmx kill-server 2>/dev/null || true
  rm -rf "$tmp"
}
trap cleanup EXIT

pass() { echo "ok - $1"; }
fail() { echo "not ok - $1" >&2; [[ -z ${2:-} ]] || echo "$2" >&2; exit 1; }

mkdir -p "$tmp/bin" "$tmp/sock" "$tmp/home/.local/bin"
cat >"$tmp/bin/open" <<SH
#!/bin/sh
[ \$# -eq 1 ] || echo "ARGC=\$#" >>"$tmp/opened"
printf '%s\n' "\$1" >>"$tmp/opened"
SH
chmod +x "$tmp/bin/open"

opens() {
  local expected="$1" description="$2"
  shift 2
  rm -f "$tmp/opened"
  LANG=en_US.UTF-8 PATH="$tmp/bin:$PATH" "$COMMAND" "$@"
  local got
  got=$(cat "$tmp/opened" 2>/dev/null || true)
  [[ $got == "$expected" ]] || fail "$description" "expected '$expected', got '$got'"
}

# --- helper --------------------------------------------------------------------
line='see https://a.example/one, and (https://b.example/two). end'
opens "https://example.com/osc8" "an OSC 8 link wins" "https://example.com/osc8" "$line" 0
opens "https://a.example/one" "the URL under the column is opened, minus a trailing comma" - "$line" 6
opens "https://b.example/two" "the second URL on a line, minus ')' and '.'" - "$line" 35
opens "" "a click beside the URLs opens nothing" - "$line" 26
opens "" "a click on plain text opens nothing" - "-rf https://x.example/ok" 0
opens "https://only.example/x?y=1#z" "with wide characters, the only URL on the line is used" - "a ✓ ✓ wide https://only.example/x?y=1#z." 2
opens "file:///etc/hosts" "file URLs open" - "cat file:///etc/hosts now" 6
opens "" "javascript: links are refused" "javascript:alert(1)" - 0
opens "" "other schemes are refused" "ftp://x.example/f" - 0
opens "" "no link at all opens nothing" - - 0
opens "https://x.example/a\$(touch $tmp/pwned)" "link text reaches open as one argument" "https://x.example/a\$(touch $tmp/pwned)" - 0
[[ ! -e $tmp/pwned ]] || fail "link text is never run by a shell"
pass "tmux-open-link picks the right URL and refuses unsafe ones"

# --- tmux binding, end to end ----------------------------------------------------
cp "$COMMAND" "$tmp/home/.local/bin/tmux-open-link"
rm -f "$tmp/opened"
export TMP="$tmp" ROOT
env -u TMUX HOME="$tmp/home" PATH="$tmp/bin:$PATH" TMUX_TMPDIR="$tmp/sock" LANG=en_US.UTF-8 TERM=xterm-ghostty python3 - <<'PY' || fail "Shift+click through tmux opens links"
import os, pty, subprocess, sys, time
tmp, root = os.environ["TMP"], os.environ["ROOT"]
env = dict(os.environ)

def tx(*args):
    return subprocess.run(["tmux", *args], env=env, capture_output=True, text=True)

def opened():
    try:
        return open(f"{tmp}/opened").read().splitlines()
    except FileNotFoundError:
        return []

tx("-f", "/dev/null", "new-session", "-d", "-s", "t", "-x", "80", "-y", "8",
   "printf '\\033]8;;https://example.com/osc8\\033\\\\osc8-link\\033]8;;\\033\\\\\\n"
   "plain https://example.com/plain/path?x=1.\\n'; sleep 60")
r = tx("source-file", f"{root}/.config/tmux/tmux.conf")
if r.returncode:
    sys.exit(f"repo tmux.conf failed to load: {r.stderr}")

pid, fd = pty.fork()
if pid == 0:
    os.execvpe("tmux", ["tmux", "attach", "-t", "t"], env)
time.sleep(1.5)

# The status bar is at the top (status-position top), so pane row 0 is client row 2.
def shift_click(col, pane_row):
    row = pane_row + 2
    os.write(fd, f"\x1b[<4;{col + 1};{row}M".encode()); time.sleep(0.2)
    os.write(fd, f"\x1b[<4;{col + 1};{row}m".encode()); time.sleep(1.0)

shift_click(2, 0)    # on the OSC 8 link
shift_click(20, 1)   # inside the plain URL
shift_click(1, 1)    # on the word "plain"
got = opened()
tx("kill-server")
expected = ["https://example.com/osc8", "https://example.com/plain/path?x=1"]
if got != expected:
    sys.exit(f"opened {got}, expected {expected}")
PY
pass "Shift+click in tmux opens the OSC 8 link or URL under the mouse, nothing elsewhere"

echo "all tmux-open-link tests passed"
