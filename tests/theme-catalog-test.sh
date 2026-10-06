#!/usr/bin/env bash
#
# Tests for theme-switcher's community themes: catalog, install, remove, update.
# Offline: the catalog is a local HTML fixture and themes are local git repos
# (file://), one of them hostile. Throwaway HOME; no desktop, terminal or tmux.
#
#   bash tests/theme-catalog-test.sh     (from the repo root; needs macOS and an installed theme engine)

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
COMMAND="$ROOT/local/bin/theme-switcher"

if [[ $(uname) != "Darwin" ]] || ! "$COMMAND" list >/dev/null 2>&1; then
  if [[ ${THEME_SWITCHER_TEST_REQUIRE_ENGINE:-} == "1" ]]; then
    echo "not ok - theme engine is installed (run: theme-switcher engine install <sha>)" >&2
    exit 1
  fi
  echo "skip - needs macOS and an installed theme engine (theme-switcher engine install <sha>)"
  exit 0
fi
ENGINE=$("$COMMAND" engine)
# Gallery repos are named "<engine>-<name>-theme"; the name lives only in theme-switcher.
ENGINE_NAME=$(sed -n 's/^ENGINE_NAME=//p' "$COMMAND")

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

pass() { echo "ok - $1"; }
fail() { echo "not ok - $1" >&2; [[ -z ${2:-} ]] || echo "$2" >&2; exit 1; }

home="$tmp/home"
mkdir -p "$home" "$tmp/sock"
state="$home/.local/state/theme-switcher/current"
themes="$home/.config/theme-switcher/themes"

theme() {
  env -u TMUX TMUX_TMPDIR="$tmp/sock" HOME="$home" THEME_SWITCHER_ENGINE="$ENGINE" \
    THEME_SWITCHER_CATALOG_URL="file://$tmp/catalog.html" THEME_SWITCHER_NO_DESKTOP=1 THEME_SWITCHER_TERMINALS="" \
    "$COMMAND" "$@"
}

make_repo() { # make_repo <dir>: commit whatever is in <dir>
  git -C "$1" init -q
  git -C "$1" add -A
  git -C "$1" -c user.email=test@example.com -c user.name=test commit -qm theme
}

# --- catalog ---------------------------------------------------------------------
cat >"$tmp/catalog.html" <<HTML
<nav><a href="https://github.com/omacom/$ENGINE_NAME" role="button">GitHub</a></nav>
<ul>
<li><a href="https://github.com/someone/$ENGINE_NAME-ayaka-theme" class="group block"><img src="/a.webp" alt="Ayaka theme screenshot"/><span class="mt-2.5 block">Ayaka</span></a></li>
<li><a href="https://github.com/other/$ENGINE_NAME-all-hallows-eve-theme" class="group block">
  <img src="/b.webp" alt="x"/>
  <span class="mt-2.5">All Hallow&#x27;s Eve</span></a></li>
<li><a href="https://github.com/third/Gruvu" class="group block"><img src="/c.webp" alt="x"/><span class="x">Gruvu &amp; Friends</span></a></li>
</ul>
HTML
catalog=$(theme catalog)
[[ $(grep -c . <<<"$catalog") == 3 ]] || fail "the catalog lists the three themes, not the site's own link" "$catalog"
grep -q "^  ayaka  *Ayaka  *https://github.com/someone/$ENGINE_NAME-ayaka-theme\$" <<<"$catalog" || fail "a theme's install name drops the prefix and -theme suffix" "$catalog"
grep -q "All Hallow's Eve" <<<"$catalog" || fail "HTML entities are decoded" "$catalog"
grep -q '^  gruvu  *Gruvu & Friends' <<<"$catalog" || fail "names are lowercased, & decoded" "$catalog"
[[ $(theme catalog hallow | grep -c .) == 1 ]] || fail "catalog filters by text"
pass "catalog parses names and repos from the page"

# --- URL safety --------------------------------------------------------------------
for url in "ext::sh -c touch$IFS$tmp/pwned" "-uhttps://x" "ftp://example.com/x.git" "fd::17" "evil://x/y" "x"; do
  if theme install "$url" >/dev/null 2>&1; then fail "install refuses '$url'"; fi
done
[[ ! -e $tmp/pwned && ! -d $themes ]] || fail "a refused URL runs and clones nothing"
pass "helper, option and unknown-transport URLs are refused before cloning"

# --- a hostile theme ---------------------------------------------------------------
hostile="$tmp/repos/$ENGINE_NAME-hostile-theme"
mkdir -p "$hostile/backgrounds" "$hostile/sub"
cp "$ENGINE/themes/nord/colors.toml" "$hostile/colors.toml"
printf 'command = "/usr/bin/touch %s/pwned"\n' "$tmp" >"$hostile/ghostty.conf"
printf 'shell /usr/bin/touch %s/pwned\n' "$tmp" >"$hostile/kitty.conf"
printf '[terminal.shell]\nprogram = "/usr/bin/touch"\n' >"$hostile/alacritty.toml"
echo 'os.execute("touch pwned")' >"$hostile/neovim.lua"
echo 'x' >"$hostile/sub/plugin.lua"
echo '{}' >"$hostile/vscode.json"
ln -s "$HOME/.ssh" "$hostile/unlock.png"
ln -s /etc/passwd "$hostile/backgrounds/1-link.png"
echo "# hostile" >"$hostile/README.md"
sips -s format png -z 8 8 /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericDocumentIcon.icns --out "$hostile/backgrounds/2-ok.png" >/dev/null
make_repo "$hostile"

theme install "file://$hostile" >/dev/null 2>"$tmp/err" || fail "a hostile theme installs (filtered)" "$(cat "$tmp/err")"
[[ $(theme current) == "hostile" ]] || fail "install applies the theme"
for f in ghostty.conf kitty.conf alacritty.toml neovim.lua sub/plugin.lua vscode.json unlock.png; do
  grep -q "$f" "$tmp/err" || fail "the dropped $f is named" "$(cat "$tmp/err")"
done
! grep -rq "pwned\|/usr/bin/touch" "$state/theme" || fail "no hostile content reaches the staged theme"
[[ -z $(find "$state/theme" -type l) ]] || fail "no symlink reaches the staged theme"
grep -q '^background = #2e3440$' "$state/theme/ghostty.conf" || fail "terminal configs are generated from the theme's colors"
[[ $(head -n 1 "$state/background") == "$themes/hostile/backgrounds/2-ok.png" ]] || fail "the theme's own regular background is used in place" "$(cat "$state/background")"
[[ ! -e $home/.local/share/theme-switcher/hostile ]] || fail "an installed theme's backgrounds are not copied"
[[ ! -e $tmp/pwned ]] || fail "nothing from the theme ran"
pass "a cloned theme supplies colors and images only; code, terminal configs and symlinks are dropped"

# --- a theme from before colors.toml -----------------------------------------------
legacy="$tmp/repos/$ENGINE_NAME-oldie-theme"
mkdir -p "$legacy"
cat >"$legacy/alacritty.toml" <<'TOML'
[colors.primary]
background = "#121212"
foreground = "#dddddd"

[colors.normal]
black = "#121212"
red = "#cc3333"
green = "#33cc33"
yellow = "#cccc33"
blue = "#3333cc"
magenta = "#cc33cc"
cyan = "#33cccc"
white = "#dddddd"

[colors.bright]
black = "#555555"
red = "#ff5555"
green = "#55ff55"
yellow = "#ffff55"
blue = "#5555ff"
magenta = "#ff55ff"
cyan = "#55ffff"
white = "#ffffff"

[terminal.shell]
program = "/usr/bin/touch"
TOML
make_repo "$legacy"
theme install "file://$legacy" >/dev/null 2>"$tmp/err" || fail "a theme with only alacritty.toml installs" "$(cat "$tmp/err")"
grep -q '^background = #121212$' "$state/theme/ghostty.conf" || fail "its colors come from alacritty.toml" "$(head -3 "$state/theme/ghostty.conf")"
! grep -q 'terminal.shell\|/usr/bin/touch' "$state/theme/alacritty.toml" || fail "its alacritty.toml itself is not used"
pass "a theme with only alacritty.toml gets its colors, not its config"

# --- update and remove -------------------------------------------------------------
echo 'accent = "#ff0000"' >>"$legacy/alacritty.toml.note"
git -C "$legacy" add -A && git -C "$legacy" -c user.email=test@example.com -c user.name=test commit -qm more
theme update >"$tmp/out" 2>&1 || fail "update runs" "$(cat "$tmp/out")"
[[ -f $themes/oldie/alacritty.toml.note ]] || fail "update pulls new commits"
pass "update pulls installed themes"

mkdir -p "$themes/mine" && cp "$ENGINE/themes/nord/colors.toml" "$themes/mine/"
mkdir -p "$tmp/repos/mine" && cp "$ENGINE/themes/nord/colors.toml" "$tmp/repos/mine/" && make_repo "$tmp/repos/mine"
if theme install "file://$tmp/repos/mine" >/dev/null 2>&1; then fail "install never replaces a hand-written theme"; fi
[[ ! -d $themes/mine/.git ]] || fail "the hand-written theme is untouched"
theme remove hostile >/dev/null
[[ ! -e $themes/hostile ]] || fail "remove deletes the installed theme"
if theme remove ../themes >/dev/null 2>&1; then fail "remove refuses a path"; fi
pass "remove deletes installed themes; install never overwrites a hand-written one"

echo "all theme-catalog tests passed"
