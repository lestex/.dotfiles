# eza as ls, when installed (steps/20-tools). Its colors are the terminal's
# ANSI names, so it follows the theme; icons need a Nerd Font (steps/80-fonts)
# and are left out when output is piped. oh-my-zsh's l, la, ll and lsa call
# ls, so they use eza too.
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first --icons=auto'
fi
