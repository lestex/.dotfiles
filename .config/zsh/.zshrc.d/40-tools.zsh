# eza as ls, when installed (steps/20-tools), as omarchy sets it up
# (default/bash/aliases). Its colors are the terminal's ANSI names, so it
# follows the theme; icons need a Nerd Font (steps/80-fonts) and are left out
# when output is piped. oh-my-zsh's l, la and ll call ls, so they use eza too.
if (( $+commands[eza] )); then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi
