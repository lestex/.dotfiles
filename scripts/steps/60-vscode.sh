#!/usr/bin/env bash
# VS Code extensions (install/Codefile) and settings.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

if ! command -v code >/dev/null; then
  pretty_print "${yellow}VS Code's code command not found, skipping VS Code setup ...${neutral}"
  exit 0
fi

installed=$(code --list-extensions)
while IFS= read -r extension; do
  [ -n "$extension" ] || continue
  if grep -Fxiq -- "$extension" <<<"$installed"; then
    pretty_print "${yellow}VS Code extension $extension already installed, skipping ...${neutral}"
  else
    pretty_print "Installing VS Code extension: $extension"
    code --install-extension "$extension"
  fi
done < install/Codefile

# The settings folder only exists once VS Code has run.
settings="$HOME/Library/Application Support/Code/User"
pretty_print "${green}Copying VS Code settings${neutral}"
mkdir -p "$settings"
cp .config/code/settings.json "$settings/settings.json"
