# Installer

`install.sh` is the only entry point. It runs the steps in `scripts/steps/` in order, each one independent and safe to re-run.

```sh
./install.sh                  # every step
./install.sh --list           # the steps, with a one-line summary each
./install.sh fonts themes     # only these, in this order
scripts/steps/80-fonts.sh     # one step directly, from any directory
```

If a step fails, the run stops and tells you how to resume it, e.g. `./install.sh fonts`.

## The steps

| Step | Installs and sets up |
|---|---|
| `homebrew` | Homebrew, then `brew update` |
| `tools` | git, bash, jq, fzf, coreutils, findutils, gnupg, gh, watch, tree, htop, btop, fastfetch, mole, vifm, ssh-copy-id, telnet, mpv, ollama |
| `apps` | Google Chrome, Bitwarden, Rectangle, VLC, Telegram (DaisyDisk and Slack are listed but commented out) |
| `terminals` | Ghostty, kitty, tmux, and Alacritty from its official release |
| `shell` | oh-my-zsh with zsh-autosuggestions and zsh-syntax-highlighting, the Pure prompt, `~/.zshrc` and `~/.zshrc.d` ([Shell](shell.md)) |
| `neovim` | Neovim, ripgrep, fd, lazygit, tree-sitter-cli; LazyVim as the config if `~/.config/nvim` doesn't exist yet |
| `languages` | tfenv, pyenv, goenv, node, nvm; Terraform 1.9.5 and Python 3.12.5 |
| `cloud` | gcloud-cli, kubectx, krew, k9s, helm, kind, podman |
| `vscode` | VS Code, the extensions Claude Code, Terraform and Python (which brings Pylance, debugpy and Python Environments), and its settings |
| `configs` | everything in `.config/` into `~/.config`, tmux plugin manager, the tmux link opener, vifm color schemes |
| `hotkeys` | Hammerspoon, for Cmd+Ctrl+T (terminal) and Cmd+Ctrl+B (browser), and terminal-switcher ([Hotkeys](hotkeys.md)) |
| `fonts` | the Nerd Fonts, font-switcher, and Liga SFMono at 14pt on first run ([Fonts](fonts.md)) |
| `themes` | theme-switcher, the theme engine, tokyo-night on first run, btop/Neovim/VS Code wiring ([Themes](themes.md)) |

The order matters in places: `tools` brings the real `git` the later steps clone with, and `fonts` and `themes` run after `configs` because the terminal configs include files they generate.

The package lists live in the steps themselves: to add or drop a package, edit the list in its step. A Homebrew package is installed only when `brew list` doesn't show it; **nothing is ever upgraded**, so run `brew upgrade` yourself. Write a formula under the name `brew list` shows (`gnupg`, not its alias `gpg`), or it is reinstalled with a warning on every run.

Versions that are pinned on purpose sit in `scripts/common`: Terraform, Python and Go, Alacritty (version and the checksum of its download), and the theme engine's commit.

## Re-running

Re-run the installer to apply changes from the repo. It overwrites:
- everything it copies into `~/.config`,
- `~/.zshrc`, and its own files in `~/.zshrc.d` (your own files there are kept),
- VS Code's `settings.json` (then selects the current theme again).

It never replaces an existing Neovim config, an existing font or theme choice, or your other btop settings.

## Options

| Variable | Effect |
|---|---|
| `DOTFILES_DIR` | where the one-liner downloads the repo (default `~/.dotfiles`) |
| `DOTFILES_REPO` | install from a fork, or a local `file://` copy |

## Adding a step

Create `scripts/steps/NN-name.sh` with a one-line summary on line 2 (that is what `--list` prints), source `scripts/common`, and skip work that is already done. `install.sh` picks it up by its number.

## Why Alacritty is downloaded directly

Alacritty has no Homebrew package any more (its cask was disabled for failing Gatekeeper). The installer downloads the official release, checks it against the pinned SHA-256, and only then copies it into `/Applications`. To update, bump `ALACRITTY_VERSION` and `ALACRITTY_DMG_SHA256` together.
