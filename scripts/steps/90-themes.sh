#!/usr/bin/env bash
# theme-switcher, its pinned theme engine and the default theme.
#
# The engine is fetched at the commit pinned by
# THEME_ENGINE_REF in scripts/common (a sparse checkout under
# ~/.local/share/theme-switcher/.engine; rerunning at the same commit is a
# no-op). Runs after 70-configs: Ghostty, Alacritty, kitty and tmux include the
# files it generates, btop and Neovim are pointed at its btop.theme and
# neovim.lua, and VS Code selects the theme.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"

pretty_print "${green}Installing theme-switcher${neutral}"
mkdir -p "$HOME/.local/bin"
cp local/bin/theme-switcher "$HOME/.local/bin/theme-switcher"

state="$HOME/.local/state/theme-switcher/current"
if ! "$HOME/.local/bin/theme-switcher" engine install "$THEME_ENGINE_REF"; then
  pretty_print "${yellow}Could not install the theme engine, skipping theme setup ...${neutral}"
elif [ -f "$state/theme.name" ]; then
  pretty_print "${yellow}Theme $(cat "$state/theme.name") already set, skipping ...${neutral}"
else
  # Generate the files only: no desktop change or terminal repaint during setup.
  THEME_SWITCHER_NO_DESKTOP=1 THEME_SWITCHER_TERMINALS="" THEME_SWITCHER_APPS="" "$HOME/.local/bin/theme-switcher" set tokyo-night
fi

# btop follows the theme through themes/current.theme, which theme-switcher
# links to the active theme's btop.theme. Point btop at it: change only the
# color_theme line of an existing btop.conf, or start a minimal one. btop
# rewrites btop.conf when it quits, so a running btop could undo this.
btop_conf="$HOME/.config/btop/btop.conf"
btop_theme="$HOME/.config/btop/themes/current.theme"
mkdir -p "$(dirname "$btop_theme")"
if [ -f "$state/theme/btop.theme" ] && { [ -L "$btop_theme" ] || [ ! -e "$btop_theme" ]; }; then
  ln -snf "$state/theme/btop.theme" "$btop_theme"
fi
if [ ! -f "$btop_conf" ]; then
  pretty_print "${green}Creating btop.conf with the theme-switcher theme${neutral}"
  printf 'color_theme = "current"\ntheme_background = true\ntruecolor = true\n' >"$btop_conf"
elif grep -q '^color_theme = "current"$' "$btop_conf"; then
  pretty_print "${yellow}btop already uses the theme-switcher theme, skipping ...${neutral}"
else
  pretty_print "${green}Pointing btop at the theme-switcher theme${neutral}"
  if grep -q '^color_theme' "$btop_conf"; then
    sed -i '' 's/^color_theme = .*/color_theme = "current"/' "$btop_conf"
  else
    printf 'color_theme = "current"\n' >>"$btop_conf"
  fi
  if pgrep -x btop >/dev/null; then
    pretty_print "${yellow}btop is running and rewrites btop.conf when it quits; quit it and re-run ./install.sh themes${neutral}"
  fi
fi

# Neovim (LazyVim): theme-switcher links lua/plugins/theme.lua to the active
# theme's neovim.lua. Create the link now, and keep it out of the Neovim
# config's own git repo.
nvim_dir="$HOME/.config/nvim"
nvim_link="$nvim_dir/lua/plugins/theme.lua"
if [ -d "$nvim_dir/lua/plugins" ]; then
  if [ -f "$state/theme/neovim.lua" ] && { [ -L "$nvim_link" ] || [ ! -e "$nvim_link" ]; }; then
    ln -snf "$state/theme/neovim.lua" "$nvim_link"
  fi
  if [ -d "$nvim_dir/.git" ] && ! grep -qx 'lua/plugins/theme.lua' "$nvim_dir/.gitignore" 2>/dev/null; then
    pretty_print "${green}Keeping Neovim's theme link out of its git repo${neutral}"
    if [ -s "$nvim_dir/.gitignore" ] && [ -n "$(tail -c 1 "$nvim_dir/.gitignore")" ]; then
      echo >>"$nvim_dir/.gitignore"
    fi
    echo 'lua/plugins/theme.lua' >>"$nvim_dir/.gitignore"
  fi
fi

# VS Code: 60-vscode copies settings.json without workbench.colorTheme, so
# select the active theme again (installing its Marketplace extension, or
# generating one from the palette).
if ! command -v code >/dev/null; then
  pretty_print "${yellow}VS Code's code command not found, skipping its theme ...${neutral}"
elif [ -f "$state/theme/colors.toml" ]; then
  pretty_print "${green}Applying the theme to VS Code${neutral}"
  "$HOME/.local/bin/theme-switcher" vscode
fi
