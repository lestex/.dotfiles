#!/usr/bin/env bash
#
# Tests for `theme-switcher preview` and the fzf picker (`theme-switcher pick`),
# against a throwaway HOME: the picker runs in a real pty, filters, and applies
# the theme on Enter. No desktop, terminal or tmux is touched.
#
#   bash tests/theme-picker-test.sh     (from the repo root; needs macOS, fzf and an installed theme engine)

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
COMMAND="$ROOT/local/bin/theme-switcher"

if [[ $(uname) != "Darwin" ]] || ! "$COMMAND" list >/dev/null 2>&1 || ! command -v fzf >/dev/null; then
  if [[ ${THEME_SWITCHER_TEST_REQUIRE_ENGINE:-} == "1" ]]; then
    echo "not ok - theme engine and fzf are installed" >&2
    exit 1
  fi
  echo "skip - needs macOS, fzf and an installed theme engine"
  exit 0
fi
ENGINE=$("$COMMAND" engine)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

pass() { echo "ok - $1"; }
fail() { echo "not ok - $1" >&2; [[ -z ${2:-} ]] || echo "$2" >&2; exit 1; }

home="$tmp/home"
mkdir -p "$home" "$tmp/sock"
theme() {
  env -u TMUX TMUX_TMPDIR="$tmp/sock" HOME="$home" THEME_SWITCHER_ENGINE="$ENGINE" \
    THEME_SWITCHER_NO_DESKTOP=1 THEME_SWITCHER_TERMINALS="" "$COMMAND" "$@"
}

# --- preview ---------------------------------------------------------------------
preview=$(FZF_PREVIEW_COLUMNS=60 FZF_PREVIEW_LINES=20 theme preview nord)
[[ $preview == *$'\e[48;2;46;52;64m'* ]] || fail "the preview is drawn on the theme's background (nord #2e3440)"
plain=$(sed $'s/\033\\[[0-9;?]*[a-zA-Z]//g' <<<"$preview")
[[ $plain == *"nord  (dark)"* && $plain == *"greet(name)"* ]] || fail "the preview names the theme and shows a sample" "$plain"
[[ $(theme preview no-such-theme) == "no-such-theme: no colors.toml" ]] || fail "an unknown theme previews as such"
[[ $(theme preview --repo https://evil.example/x) == "no preview for https://evil.example/x" ]] || fail "gallery previews only fetch from GitHub repos"
pass "preview draws a theme's palette and sample in its colors"

# --- the picker, driven through a pty ------------------------------------------------
export TMP="$tmp" HOME_DIR="$home" ENGINE COMMAND
python3 - <<'PY' || fail "the picker filters and applies the chosen theme"
import fcntl, os, pty, re, select, struct, sys, termios, time
tmp, home = os.environ["TMP"], os.environ["HOME_DIR"]
env = dict(os.environ, HOME=home, THEME_SWITCHER_ENGINE=os.environ["ENGINE"], THEME_SWITCHER_NO_DESKTOP="1",
           THEME_SWITCHER_TERMINALS="", TMUX_TMPDIR=f"{tmp}/sock", TERM="xterm-256color")
env.pop("TMUX", None)
pid, fd = pty.fork()
if pid == 0:
    os.execvpe(os.environ["COMMAND"], [os.environ["COMMAND"], "pick"], env)
fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 140, 0, 0))
out = b""
def drain(seconds):
    global out
    end = time.time() + seconds
    while time.time() < end:
        if select.select([fd], [], [], 0.1)[0]:
            try:
                out += os.read(fd, 65536)
            except OSError:
                return
drain(3)
os.write(fd, b"kanag")
drain(3)
screen = re.sub(rb"\x1b\[[0-9;?]*[a-zA-Z]", b"", out).decode(errors="replace")
if "greet(name)" not in screen:
    sys.exit("the preview pane never showed the highlighted theme")
os.write(fd, b"\r")
drain(4)
try:
    os.waitpid(pid, 0)
except ChildProcessError:
    pass
applied = open(f"{home}/.local/state/theme-switcher/current/theme.name").read().strip()
if applied != "kanagawa":
    sys.exit(f"applied {applied!r}, expected 'kanagawa'")
PY
pass "the picker filters, previews, and applies the chosen theme on Enter"

echo "all theme-picker tests passed"
