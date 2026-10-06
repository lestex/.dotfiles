#!/usr/bin/env bash
#
# Tests theme-switcher's Neovim support: the lua/plugins/theme.lua link and the
# live reload of running Neovims. Offline: a minimal Neovim config, a local fake
# colorscheme plugin and hand-written themes, in a throwaway HOME, with a
# private TMPDIR so only the test's own headless Neovim is found.
#
#   bash tests/nvim-theme-test.sh     (from the repo root; needs macOS, nvim and an installed theme engine)

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
COMMAND="$ROOT/local/bin/theme-switcher"

if [[ $(uname) != "Darwin" ]] || ! "$COMMAND" list >/dev/null 2>&1 || ! command -v nvim >/dev/null; then
  if [[ ${THEME_SWITCHER_TEST_REQUIRE_ENGINE:-} == "1" ]]; then
    echo "not ok - theme engine and nvim are installed" >&2
    exit 1
  fi
  echo "skip - needs macOS, nvim and an installed theme engine"
  exit 0
fi
ENGINE=$("$COMMAND" engine)

tmp=$(mktemp -d)
home="$tmp/home"
run="$tmp/run"
mkdir -p "$home/.config/nvim/lua/plugins" "$run" "$tmp/sock"
socket() { find "$run" -type s -name 'nvim.*.0' 2>/dev/null | head -n 1; }
cleanup() {
  local s
  s=$(socket)
  [[ -z $s ]] || env HOME="$home" TMPDIR="$run/" nvim --server "$s" --remote-send ':qa!<CR>' >/dev/null 2>&1 || true
  rm -rf "$tmp"
}
trap cleanup EXIT

pass() { echo "ok - $1"; }
fail() { echo "not ok - $1" >&2; [[ -z ${2:-} ]] || echo "$2" >&2; exit 1; }

theme() {
  env -u TMUX TMUX_TMPDIR="$tmp/sock" HOME="$home" TMPDIR="$run/" THEME_SWITCHER_ENGINE="$ENGINE" \
    THEME_SWITCHER_NO_DESKTOP=1 THEME_SWITCHER_TERMINALS="" THEME_SWITCHER_APPS="nvim" "$COMMAND" "$@"
}
nv() { env HOME="$home" TMPDIR="$run/" nvim "$@"; }

# A minimal Neovim (no lazy.nvim): theme-switcher then finds plugins under
# stdpath("data")/lazy, where a local fake colorscheme plugin lives.
# With FAKE_LAZY set, a stand-in for lazy.nvim that knows fake-colors.nvim but
# recorded at startup that it was not installed, as lazy does for a plugin the
# background install adds later; its load() then does nothing.
cat >"$home/.config/nvim/init.lua" <<'LUA'
if vim.env.FAKE_LAZY then
  local root = vim.fn.stdpath("data") .. "/lazy"
  local config = { options = { root = root }, plugins = { ["fake-colors.nvim"] = { _ = { installed = false } } } }
  package.loaded["lazy.core.config"] = config
  package.loaded["lazy"] = {
    load = function(opts)
      for _, name in ipairs(opts.plugins) do
        local plugin = config.plugins[name]
        if plugin and plugin._.installed then vim.opt.rtp:prepend(root .. "/" .. name) end
      end
    end,
  }
end
LUA
plugin="$home/.local/share/nvim/lazy/fake-colors.nvim"
mkdir -p "$plugin/colors" "$plugin/lua/fake-colors"
for name in fake-dark fake-light; do
  printf 'vim.cmd("hi clear")\nvim.g.colors_name = "%s"\nvim.api.nvim_set_hl(0, "Normal", { bg = require("fake-colors").bg or "#000000" })\n' "$name" >"$plugin/colors/$name.lua"
done
printf 'local M = {}\nfunction M.setup(opts) M.bg = opts.bg end\nreturn M\n' >"$plugin/lua/fake-colors/init.lua"

# Two hand-written themes whose neovim.lua uses it; the second passes opts to
# setup(), as aether.nvim takes the palette.
for t in alpha beta; do
  mkdir -p "$home/.config/theme-switcher/themes/$t"
  cp "$ENGINE/themes/nord/colors.toml" "$home/.config/theme-switcher/themes/$t/"
done
cat >"$home/.config/theme-switcher/themes/alpha/neovim.lua" <<'LUA'
return {
  { "someone/fake-colors.nvim" },
  { "LazyVim/LazyVim", opts = { colorscheme = "fake-dark" } },
}
LUA
cat >"$home/.config/theme-switcher/themes/beta/neovim.lua" <<'LUA'
return {
  { "someone/fake-colors.nvim", opts = { bg = "#123456" } },
  { "LazyVim/LazyVim", opts = { colorscheme = "fake-light" } },
}
LUA

# --- the link ------------------------------------------------------------------
theme set alpha >/dev/null 2>"$tmp/err" || fail "set applies a theme" "$(cat "$tmp/err")"
link="$home/.config/nvim/lua/plugins/theme.lua"
[[ -L $link && $(readlink "$link") == "$home/.local/state/theme-switcher/current/theme/neovim.lua" ]] ||
  fail "lua/plugins/theme.lua links to the active theme's neovim.lua" "$(ls -l "$link" 2>&1)"
pass "Neovim's theme.lua links to the active theme"

# --- live reload ---------------------------------------------------------------
nv --headless >/dev/null 2>&1 &
for _ in $(seq 1 50); do [[ -n $(socket) ]] && break; sleep 0.2; done
[[ -n $(socket) ]] || fail "a headless Neovim starts"
colors() { nv --server "$(socket)" --remote-expr 'g:colors_name' 2>/dev/null || true; }
normal_bg() { nv --server "$(socket)" --remote-expr 'printf("#%06x", nvim_get_hl(0, {"name": "Normal"}).bg)' 2>/dev/null || true; }

theme set alpha >/dev/null
[[ $(colors) == "fake-dark" ]] || fail "a running Neovim switches to the theme's colorscheme" "$(colors)"
theme set beta >/dev/null
[[ $(colors) == "fake-light" ]] || fail "it switches again on the next theme" "$(colors)"
[[ $(normal_bg) == "#123456" ]] || fail "the spec's opts reach the plugin's setup()" "$(normal_bg)"
pass "running Neovims switch colorscheme live, with the spec's opts"

env -u TMUX TMUX_TMPDIR="$tmp/sock" HOME="$home" TMPDIR="$run/" THEME_SWITCHER_ENGINE="$ENGINE" THEME_SWITCHER_NO_DESKTOP=1 \
  THEME_SWITCHER_TERMINALS="" THEME_SWITCHER_APPS="" "$COMMAND" set alpha >/dev/null
[[ $(colors) == "fake-light" ]] || fail "THEME_SWITCHER_APPS without nvim leaves running Neovims alone" "$(colors)"
pass "Neovims are only reloaded when nvim is in THEME_SWITCHER_APPS"

# --- a plugin lazy knows but thinks is missing -----------------------------------
nv --server "$(socket)" --remote-send ':qa!<CR>' >/dev/null 2>&1 || true
for _ in $(seq 1 50); do [[ -z $(socket) ]] && break; sleep 0.2; done
env HOME="$home" TMPDIR="$run/" FAKE_LAZY=1 nvim --headless >/dev/null 2>&1 &
for _ in $(seq 1 50); do [[ -n $(socket) ]] && break; sleep 0.2; done
theme set alpha >/dev/null
[[ $(colors) == "fake-dark" ]] || fail "a plugin lazy recorded as not installed at startup is still applied" "$(colors)"
pass "a theme plugin installed after Neovim started is applied"

# --- a real file is left alone --------------------------------------------------
rm "$link" && echo 'return {}' >"$link"
theme set beta >/dev/null 2>"$tmp/err"
[[ ! -L $link && $(cat "$link") == "return {}" ]] || fail "a real theme.lua is left alone"
grep -q "leaving Neovim's theme alone" "$tmp/err" || fail "and the user is told" "$(cat "$tmp/err")"
pass "a hand-written theme.lua is never replaced"

echo "all nvim-theme tests passed"
