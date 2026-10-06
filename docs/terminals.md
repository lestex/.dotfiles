# Terminals and tmux

Ghostty and Alacritty start tmux. kitty runs your login shell and uses its own tabs.

## Shared defaults

All three are kept the same; a change to one is made to the other two:
- padding 14, no window decorations, no prompt when closing;
- a block cursor that doesn't blink;
- Shift+Insert pastes, Ctrl+Insert copies;
- Shift+Enter and Alt+Shift+Enter are sent as distinct keys (CSI-u), so apps such as Claude Code can tell them apart from Enter.

Terminal-specific keys:

| | |
|---|---|
| kitty | Cmd+1…0 go to a tab, Cmd+T new tab, Cmd+N new window (both in the current folder) |
| Ghostty | Cmd+Ctrl+Shift+Alt+arrows resize a split |
| Alacritty | Alt+←/→ jump a word, Cmd+←/→ go to the start/end of the line, Cmd+Backspace deletes the line, Cmd+-/= change the font size |

## tmux

| Key | |
|---|---|
| Ctrl+B | prefix |
| prefix r | reload `~/.config/tmux/tmux.conf` |
| prefix x | close the pane |
| prefix & | close the window |
| drag | select text; it's copied to the macOS clipboard |
| v (in copy mode) | start a selection (vi keys) |

The status bar is at the top, and windows are numbered from 1. Its colors are the terminal's color names, so tmux follows the theme with the terminal.

## Opening links

Links open with **Shift+click** inside tmux in every terminal. That covers both URLs and the links programs print (`ls --hyperlink`, `gh`, Claude Code's file links). Only http, https and file links are opened.

| | In tmux | Outside tmux |
|---|---|---|
| Ghostty | Shift+click (tmux opens it) | Cmd+click |
| kitty | Shift+click | click |
| Alacritty | Shift+click | click |
