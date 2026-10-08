# Installer

`install.sh` is the only entry point. It runs the steps in `scripts/steps/` in order, each one independent and safe to re-run.

```sh
./install.sh                  # every step
./install.sh --list           # the steps, with a one-line summary each
./install.sh fonts themes     # only these, in this order
scripts/steps/80-fonts.sh     # one step directly, from any directory
```

If a step fails, the run stops and tells you how to resume it, e.g. `./install.sh fonts`.

## Base and packages

The steps are of two kinds, and `./install.sh --list` says which each one is:

- **Base** is the framework itself: Homebrew, the terminals and tmux, the shell, the configs, the hotkeys, the default font, the switchers and the themes. It also covers the few tools they run on: git, bash, jq, fzf and mise. Leave these in.
- **Packages** is the software on top, chosen per person. Each list has one package per line under a `# Comment out what you don't want.` note. To skip a package, comment out its line; to add one, add a line.

| Step | Kind | Installs and sets up |
|---|---|---|
| `homebrew` | base | Homebrew, then `brew update` |
| `tools` | packages | coreutils, findutils, gnupg, gh, watch, tree, htop, btop, fastfetch, mole, vifm, ssh-copy-id, telnet, mpv, ollama; plus git, bash, jq, fzf (base) |
| `apps` | packages | Google Chrome, Bitwarden, Rectangle, VLC, Telegram (DaisyDisk and Slack are commented out) |
| `terminals` | base | Ghostty, kitty, tmux, and Alacritty from its official release |
| `shell` | base | oh-my-zsh with zsh-autosuggestions and zsh-syntax-highlighting, the Pure prompt, `~/.zshrc` and `~/.zshrc.d` ([Shell](shell.md)) |
| `neovim` | packages | Neovim, ripgrep, fd, lazygit, tree-sitter-cli; LazyVim as the config if Neovim is in and `~/.config/nvim` doesn't exist yet |
| `languages` | base + packages | [mise](https://mise.jdx.dev) (base), and the tools in `.config/mise/config.toml`: Python 3.14, Go 1.26, Terraform 1.15, Node LTS, the AWS CLI |
| `cloud` | packages | gcloud-cli, kubectx, krew, k9s, helm, kind, podman |
| `vscode` | packages | VS Code, the extensions Claude Code, Terraform and Python (which brings Pylance, debugpy and Python Environments), and its settings |
| `configs` | base | everything in `.config/` into `~/.config`, tmux plugin manager, the tmux link opener, vifm color schemes |
| `hotkeys` | base | Hammerspoon, for Cmd+Ctrl+T (terminal) and Cmd+Ctrl+B (browser), and terminal-switcher ([Hotkeys](hotkeys.md)) |
| `fonts` | base + packages | Liga SFMono at 14pt and font-switcher (base); JetBrainsMono, Caskaydia, Meslo, FiraCode, VictorMono, Bitstream Vera, Iosevka ([Fonts](fonts.md)) |
| `themes` | base | theme-switcher, the theme engine, tokyo-night on first run, btop/Neovim/VS Code/torrnado wiring ([Themes](themes.md)) |

Commenting out a package only stops the installer from installing it. It doesn't uninstall anything already on the Mac; `brew uninstall` does that. Apps that follow the theme are wired up only when they're installed, so dropping Neovim, VS Code or btop is safe.

The order matters in places: `tools` brings the real `git` the later steps clone with, and `fonts` and `themes` run after `configs` because the terminal configs include files they generate.

A Homebrew package is installed only when `brew list` doesn't show it; **nothing is ever upgraded**, so run `brew upgrade` yourself. Write a formula under the name `brew list` shows (`gnupg`, not its alias `gpg`), or it is reinstalled with a warning on every run.

Language and tool versions are in `.config/mise/config.toml` (see [Shell](shell.md#languages-and-tools)). Other pinned versions sit in `scripts/common`: Alacritty (version and the checksum of its download) and the theme engine's commit.

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
