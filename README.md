## .dotfiles install software on your mac
[![Maintained by Leandevops.io](https://img.shields.io/badge/maintained%20by-leandevops-green.svg)](https://leandevops.io)
![macOS](https://github.com/lestex/.dotfiles/actions/workflows/mac.yaml/badge.svg)

macOS only. One script installs the software, copies the configs into place, and sets up three terminals (Ghostty, kitty, Alacritty) plus tmux, Neovim and VS Code that all switch theme together, and switch font together.

## Install
On a fresh Mac:
```sh
bash <(curl -fsSL https://raw.githubusercontent.com/lestex/.dotfiles/master/install.sh)
```
This downloads the repo into `~/.dotfiles` and sets the Mac up. From a checkout, run `./install.sh`. Re-running is safe: finished work is skipped.

```sh
./install.sh --list           # the steps
./install.sh fonts themes     # run only these
```
Configs are **copied**, not linked: edit them in the repo, then re-run the installer. See [the installer](docs/installer.md).

## Everyday commands
```sh
theme-switcher pick           # choose a theme with a live preview
theme-switcher pick --catalog # browse and install community themes
theme-switcher bg next        # next wallpaper of the current theme
font-switcher pick            # choose the terminal font
font-switcher size 14         # change the terminal font size
terminal-switcher kitty       # the terminal Cmd+Ctrl+T opens (ghostty, alacritty, kitty)
exec zsh                      # pick up shell config changes in an open terminal
# Cmd+Ctrl+T terminal, Cmd+Ctrl+B browser, from anywhere
```

## Documentation
| | |
|---|---|
| [Installer](docs/installer.md) | the steps, what each installs, re-running, adding a package |
| [Themes](docs/themes.md) | theme-switcher, what follows the theme and how, community themes, limits |
| [Fonts](docs/fonts.md) | font-switcher and how each terminal picks up a change |
| [Terminals and tmux](docs/terminals.md) | shared defaults, keys, opening links |
| [Shell](docs/shell.md) | `.zshrc`, `~/.zshrc.d`, the Pure prompt |
| [Hotkeys](docs/hotkeys.md) | Cmd+Ctrl+T terminal, Cmd+Ctrl+B browser, terminal-switcher, other apps |
| [Troubleshooting](docs/troubleshooting.md) | known errors and their fixes |

## Tests
```sh
for t in tests/*-test.sh; do bash "$t"; done
```
CI runs the installer and these tests on `macos-latest` for pull requests. The tests use a throwaway home folder, a private tmux server and stubbed `open`/`osascript`/`defaults`/`code`, so they never touch your desktop, running tmux or real settings.
