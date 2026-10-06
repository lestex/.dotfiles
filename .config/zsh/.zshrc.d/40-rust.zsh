# Rust is not installed by these dotfiles; load cargo only if it is there.
if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi
