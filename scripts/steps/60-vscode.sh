#!/usr/bin/env bash
# VS Code extensions (install/Codefile) and settings.
set -euo pipefail
# shellcheck source=scripts/common
source "$(dirname "$0")/../common"
require_brew

while IFS= read -r extension; do
  [ -n "$extension" ] || continue
  pretty_print "Installing VS Code extension: $extension"
  code --install-extension "$extension" --force
done < install/Codefile

# The settings folder only exists once VS Code has run.
settings="$HOME/Library/Application Support/Code/User"
pretty_print "${green}Copying VS Code settings${neutral}"
mkdir -p "$settings"
cp .config/code/settings.json "$settings/settings.json"
