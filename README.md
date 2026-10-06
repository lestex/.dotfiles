## .dotfiles install software on your mac
[![Maintained by Leandevops.io](https://img.shields.io/badge/maintained%20by-leandevops-green.svg)](https://leandevops.io)
![macOS](https://github.com/lestex/.dotfiles/actions/workflows/mac.yaml/badge.svg)

macOS only. One script installs the software below, copies the configs into `~/.config`, and sets up three terminals (Ghostty, kitty, Alacritty) plus tmux that switch theme and font together.

## Installation
On a fresh Mac:
```sh
bash <(curl -fsSL https://raw.githubusercontent.com/lestex/.dotfiles/master/install.sh)
```
This downloads the repo into `~/.dotfiles` and sets the Mac up. Re-run it (or `./install.sh` from a checkout) to update; it is safe to run again.

The setup is split into independent steps in `scripts/steps/`; run only some of them by name:
```sh
./install.sh --list           # homebrew, packages, alacritty, shell, neovim, languages, vscode, configs, fonts, themes
./install.sh configs themes   # just these, in this order
scripts/steps/80-fonts.sh     # or one step directly, from any directory
```

- `DOTFILES_DIR` changes where the repo is downloaded (default `~/.dotfiles`).
- `DOTFILES_REPO` installs from a fork.
- Configs are **copied**, not symlinked: edit them in the repo and re-run the installer. Re-running overwrites local edits under `~/.config` and `~/.zshrc`.

## Terminals
Ghostty, kitty and Alacritty share the same defaults: padding 14, no window decorations, a non-blinking block cursor, no close prompt, Shift/Ctrl+Insert to paste/copy, and Shift+Enter / Alt+Shift+Enter sent as CSI-u so apps such as Claude can tell them apart from Enter. Ghostty and Alacritty start tmux; kitty uses your login shell and its own tabs (Cmd+1…0, Cmd+T, Cmd+N).

Alacritty has no Homebrew package any more, so the installer downloads the official release, checks it against a pinned SHA-256 (`ALACRITTY_VERSION` / `ALACRITTY_DMG_SHA256` in `scripts/common`) and copies it into `/Applications`.

## Themes
```sh
theme-switcher pick                 # choose in fzf with a live preview; Enter applies
theme-switcher list                 # available themes, current one marked
theme-switcher set "Tokyo Night"    # apply a theme
theme-switcher bg next              # next wallpaper of the current theme
theme-switcher bg set ~/Pictures/x.jpg
theme-switcher bg none              # solid background in the theme's color
```
Community themes from the theme engine's gallery install by name or git URL:
```sh
theme-switcher pick --catalog       # browse the gallery in fzf with previews; Enter installs
theme-switcher catalog              # the gallery's themes, installed ones marked *
theme-switcher catalog gruv         # search it
theme-switcher install ayaka        # clone it into ~/.config/theme-switcher/themes and apply it
theme-switcher install https://github.com/someone/my-theme
theme-switcher update               # pull every installed theme
theme-switcher remove ayaka
```
An installed theme is someone else's git repo, so only its colors and images are used: Lua, terminal configs (which name the program a terminal runs), `vscode.json` and symlinks are dropped and named on screen, and the terminal configs are generated from its colors instead. Themes that only ship an `alacritty.toml` get their colors from it.

A theme recolors Ghostty, kitty, Alacritty, tmux, btop, Neovim and VS Code (including windows that are already open), sets the desktop picture, and carries over to macOS itself: Dark or Light mode from the theme, the macOS accent color matching the theme's accent (Graphite when the accent is muted or between macOS's colors, e.g. rose-pine's teal), and a highlight (selected text) tinted from it. The menu bar follows Dark/Light and the wallpaper; macOS has no way to color it. `theme-switcher appearance` re-applies the macOS part. btop follows through `~/.config/btop/themes/current.theme`; the installer sets `color_theme = "current"` in your `btop.conf` and changes nothing else in it, so your own btop themes stay selectable in btop. Neovim (LazyVim) follows through `~/.config/nvim/lua/plugins/theme.lua`, a link the installer also keeps out of your Neovim repo with `.gitignore`; open Neovims switch colorscheme right away, and a theme whose colorscheme plugin isn't installed yet gets it installed in the background, then applied. VS Code gets the theme's Marketplace extension when the theme names one (installed in the background the first time; open windows switch once it is ready), otherwise a theme generated from the palette, served by a small local extension; theme-switcher only changes `workbench.colorTheme` in your `settings.json`, and `theme-switcher vscode` re-applies it. To go back to macOS's defaults: `defaults delete -g AppleAccentColor; defaults delete -g AppleHighlightColor; defaults delete -g AppleAquaColorVariant`. The first time, macOS asks to let your terminal control System Events; that is needed for the desktop picture.

Themes come from a theme engine the installer fetches at a pinned commit (`THEME_ENGINE_REF` in `scripts/common`) into `~/.local/share/theme-switcher/.engine`. A theme's wallpapers are downloaded the first time you use it. Your own themes go in `~/.config/theme-switcher/themes/<name>/`, your own templates in `~/.config/theme-switcher/themed/`.

## Fonts
```sh
font-switcher pick                          # choose in fzf with a rendered sample; Enter uses it
font-switcher list                          # installed monospace fonts, current one marked
font-switcher set "JetBrainsMono Nerd Font" # change the font in all three terminals
font-switcher size 14                       # change the size in all three terminals
```
The default is Liga SFMono Nerd Font at 14pt. Alacritty picks up a change by itself, kitty is reloaded for you, and Ghostty needs Cmd+Shift+, (or a new window).

## tmux
Your tmux config, with the status bar and borders in palette colors so they follow the theme. Prefix is Ctrl+B; prefix+r reloads the config.

Links inside tmux open with **Shift+click** in every terminal, both URLs and the links programs print (`ls --hyperlink`, `gh`, Claude's file links). A plain drag selects text in tmux and copies it to the macOS clipboard. Only http, https and file links are opened.

| | Open a link in tmux | Outside tmux |
|---|---|---|
| Ghostty | Shift+click (tmux opens it) | Cmd+click |
| kitty | Shift+click | click |
| Alacritty | Shift+click | click |

## Software installed
### Homebrew formulae (`install/Brewfile`)
- **common:** coreutils, findutils, jq, htop, btop, fastfetch, tree, mole, neovim (with ripgrep, fd, lazygit, tree-sitter-cli for LazyVim), vifm, mpv, ssh-copy-id, telnet, tmux, fzf
- **development tools:** bash, git, pyenv, tfenv, goenv, node, helm, gpg, watch, kind, podman, oh-my-posh, kubectx, krew, k9s, ollama, gh, nvm

### Casks (`install/Caskfile`)
- **common:** ghostty, kitty, bitwarden, daisydisk, google-chrome, vlc, rectangle
- **development tools:** gcloud-cli, visual-studio-code
- **messaging:** slack, telegram
- **fonts (Nerd Fonts):** JetBrainsMono, CaskaydiaMono, Meslo LG, FiraCode, VictorMono, Bitstream Vera Sans Mono, Iosevka; plus Liga SFMono and MesloLGS NF from `fonts/`

### Also
- Alacritty, from its pinned release (see Terminals)
- oh-my-zsh with zsh-autosuggestions and zsh-syntax-highlighting
- LazyVim as the Neovim config, from its starter, when `~/.config/nvim` doesn't exist yet (an existing config is left alone); it installs its plugins on the first `nvim` start
- Terraform 1.9.5 (tfenv) and Python 3.12.5 (pyenv); versions are pinned in `scripts/common`
- tmux plugin manager (tpm), vifm color schemes

### VS Code extensions (`install/Codefile`)
anthropic.claude-code, HashiCorp.terraform, ms-python.python (which brings Pylance, debugpy and Python Environments). The color theme comes from theme-switcher.

## Tests
```sh
for t in tests/*-test.sh; do bash "$t"; done
```
CI runs the installer and these tests on `macos-latest` for pull requests. The tests use a throwaway home folder, a private tmux server and stubbed `open`/`osascript`, so they never touch your desktop or running tmux.
