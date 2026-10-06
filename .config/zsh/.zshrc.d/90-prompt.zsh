# Pure (github.com/sindresorhus/pure), last: other files may touch the prompt.
#
#   ~/projects/dotfiles master* ⇡ 6s
#   ❯
#
# Path, git branch (* when dirty, ⇣⇡ behind/ahead, fetched in the background),
# the last command's time when it took over 5 s, then ❯ (red after a failure).
# Colors are ANSI names only, so the prompt follows theme-switcher's palette.

# Pure ships with Homebrew; a non-login shell has not run `brew shellenv`.
fpath=("${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh/site-functions" $fpath)

zstyle :prompt:pure:path color blue
zstyle :prompt:pure:git:branch color 8
zstyle :prompt:pure:git:dirty color 8
zstyle :prompt:pure:git:arrow color cyan
zstyle :prompt:pure:execution_time color yellow
zstyle :prompt:pure:prompt:success color magenta
zstyle :prompt:pure:prompt:error color red
zstyle :prompt:pure:prompt:continuation color 8

autoload -U promptinit && promptinit
prompt pure
