#!/usr/bin/env bash
# App hotkeys with Hammerspoon: Cmd+Ctrl+T terminal, Cmd+Ctrl+B browser.
#
# The config is .config/hammerspoon/init.lua, copied by 70-configs; Hammerspoon
# is pointed at ~/.config/hammerspoon instead of its default ~/.hammerspoon.
# terminal-switcher picks the terminal; ~/.config/hammerspoon/local.lua (never in
# the repo) picks other apps.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

brew_casks hammerspoon

# Chooses the terminal Cmd+Ctrl+T opens.
mkdir -p "$HOME/.local/bin"
cp local/bin/terminal-switcher "$HOME/.local/bin/terminal-switcher"

config="$HOME/.config/hammerspoon/init.lua"
if [ "$(defaults read org.hammerspoon.Hammerspoon MJConfigFile 2>/dev/null)" = "$config" ]; then
  pretty_print "${yellow}Hammerspoon already reads ~/.config/hammerspoon, skipping ...${neutral}"
else
  pretty_print "${green}Pointing Hammerspoon at ~/.config/hammerspoon${neutral}"
  defaults write org.hammerspoon.Hammerspoon MJConfigFile "$config"
fi

# Start it; a running Hammerspoon reloads by itself when the config changes.
# CI has no one to grant it anything, so it is not started there.
if [ -n "${CI:-}" ]; then
  pretty_print "${yellow}CI: not starting Hammerspoon${neutral}"
elif pgrep -xq Hammerspoon; then
  pretty_print "${yellow}Hammerspoon is running, skipping ...${neutral}"
else
  pretty_print "${green}Starting Hammerspoon${neutral}"
  open -g -a Hammerspoon
fi
