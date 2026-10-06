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

# --- preview and the fzf picker ----------------------------------------------------
preview=$(env -u TMUX TERM=xterm-256color HOME="$home" "$COMMAND" preview menlo)
[[ $preview == "Menlo"* && $preview == *"Styles: Regular"* ]] || fail "a text preview names the font and its styles" "$preview"
[[ $(env -u TMUX TERM=xterm-256color HOME="$home" "$COMMAND" preview "No Such Mono") == *"not an installed monospace font"* ]] ||
  fail "an unknown font previews as such"

if command -v fzf >/dev/null; then
  export TMP="$tmp" HOME_DIR="$home" COMMAND
  python3 - <<'PY2' || fail "the picker filters and uses the chosen font"
import fcntl, os, pty, select, struct, sys, termios, time
home, command = os.environ["HOME_DIR"], os.environ["COMMAND"]
env = dict(os.environ, HOME=home, FONT_SWITCHER_NO_RELOAD="1", TERM="xterm-256color")
env.pop("TMUX", None)
pid, fd = pty.fork()
if pid == 0:
    os.execvpe(command, [command, "pick"], env)
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
os.write(fd, b"^menlo$")
drain(3)
if b"Styles:" not in out:
    sys.exit("the preview pane never showed the highlighted font")
os.write(fd, b"\r")
drain(3)
try:
    os.waitpid(pid, 0)
except ChildProcessError:
    pass
chosen = open(f"{home}/.local/state/font-switcher/current/font.name").read().strip()
if chosen != "Menlo":
    sys.exit(f"chose {chosen!r}, expected 'Menlo'")
PY2
  pass "the picker previews fonts and uses the chosen one on Enter"
else
  echo "skip - fzf not installed; picker not tested"
fi

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
