# Language version managers: pyenv, goenv, and cargo if Rust is installed.

# pyenv
eval "$(pyenv init -)"

# goenv
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"

# Rust is not installed by these dotfiles; load cargo only if it is there.
if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi
