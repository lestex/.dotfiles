# Language versions from mise: ~/.config/mise/config.toml, or a project's own
# mise.toml, .python-version, .go-version, .terraform-version or .nvmrc.
eval "$(mise activate zsh)"

# Rust is not installed by these dotfiles; load cargo only if it is there.
if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi
