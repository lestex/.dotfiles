# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal dotfiles + machine bootstrap for macOS and Debian/Ubuntu. Pure bash + Make — no build system, no test framework, no package manifest. The "program" is a set of idempotent-ish provisioning scripts that install software and **copy** config files into `$HOME`.

## Commands

```sh
make          # default goal: detect OS and run the full provisioning for it
make help     # list targets (parsed from `## ` comments in the Makefile)
make macos    # force the macOS path
make linux    # force the Linux path
```

There is no lint/test tooling. CI (`.github/workflows/{mac,linux}.yaml`) simply runs `make` on `macos-latest` / `ubuntu-24.04`, so **running `make` on the target OS is the test**. Both workflows are path-filtered. Mac CI fires on `scripts/mac-setup`, `scripts/common`, `install/**`, `.config/**`; linux CI only on `scripts/linux-*` or `.config/**` — so a change confined to `install/**` or `scripts/common` still does not trigger linux CI. `tests/` is an empty placeholder (`.keep`).

Scripts must be run from the repo root — they do `source scripts/common` with a relative path. Use `make`, not `./scripts/...` from elsewhere.

## Architecture

**OS dispatch.** `Makefile` computes `OS := $(shell bin/is-supported bin/is-macos macos linux)` and makes it the goal of `all`. `bin/is-supported` evals its first arg and echoes arg 2 on success, arg 3 on failure; `bin/is-macos` / `bin/is-executable` are the predicates. The Makefile also prepends `bin/` to `PATH` and exports `XDG_CONFIG_HOME`.

**`scripts/common`** is sourced by every script and is the single source of truth for the pinned toolchain versions (`TERRAFORM_VERSION`, `PYTHON_VERSION`, `GO_VERSION`) plus the color vars and `pretty_print`. Bump versions here, not in the individual scripts.

**macOS = one phase.** `scripts/mac-setup` installs oh-my-zsh + Homebrew, then `brew bundle` against `install/Brewfile` (formulae) and `install/Caskfile` (casks), then loops `install/Codefile` through `code --install-extension`, then rust/tfenv/pyenv, then copies configs, fonts, and the Alacritty icon.

**Third-party taps need explicit trust.** Homebrew 6 refuses to load formulae from non-official taps unless they are trusted (`HOMEBREW_REQUIRE_TAP_TRUST` defaults to `true`), and the trust store is `$XDG_CONFIG_HOME/homebrew/trust.json` — which the Makefile repoints at `~/.config`, so a developer's manual `brew trust` (stored in `~/.homebrew/trust.json`) does *not* apply under `make`. `mac-setup` therefore taps and trusts `jandedobbeleer/oh-my-posh` itself before `brew bundle`. Any future tapped formula needs the same treatment or both `make` and CI will fail.

**Linux = two phases**, because apt repos must be registered before their packages exist:
- `scripts/linux-pre` — apt base packages, oh-my-zsh + zsh plugins, starship via cargo, registers third-party apt repos (Brave, VS Code, google-cloud-sdk, Chrome), copies configs/fonts, clones `pyenv`/`tfenv`/`goenv`.
- `scripts/linux-install` — installs the packages from those newly added repos, VS Code extensions, and the pinned python/terraform/go versions via the `*env` tools invoked by absolute path (they are not on `PATH` yet in a non-interactive shell).

Linux has no equivalent of Brewfile/Caskfile — its package list is hardcoded in the `apt install` lines. Adding a tool for both OSes means editing `install/Brewfile` (or `Caskfile`) *and* the apt lists.

**Configs are copied, not symlinked.** `cp -R .config/* ~/.config`, `.config/zsh/.zshrc` → `~/.zshrc`, VS Code settings → the OS-specific application-support path. Consequences:
- Editing `~/.config/...` does not flow back to the repo. Edit the repo file, then re-run `make`.
- Re-running `make` overwrites local tweaks under `~/.config` and `~/.zshrc`.
- Directories cloned into `~/.config` by the scripts (alacritty themes, vifm colors, tmux tpm) are guarded by existence checks and are not tracked here.
- One file is templated rather than copied verbatim: `.config/ghostty/config` holds a `@BREW_PREFIX@` placeholder that `mac-setup` rewrites with `sed` after the copy, because Ghostty needs an absolute `command` path (GUI launches inherit no shell `PATH`) and the Homebrew prefix differs by architecture.

**Per-OS config variants.** Two files ship both variants and the script picks one:
- `.config/zsh/.zshrc` (mac) vs `.zshrc-linux` — the Linux one wires `PYENV_ROOT`/`GOENV_ROOT`/`CARGO_ROOT`/tfenv onto `PATH` explicitly and uses the distro gcloud completion path; the mac one relies on Homebrew paths and branches on `uname -m` for the gcloud Caskroom prefix. Keep both in sync when adding shell config.
- `.config/alacritty/alacritty.toml` (mac) vs `alacritty-linux.toml` — `linux-pre` copies both then `mv`s the linux one over `alacritty.toml`.

## Conventions

- Scripts use `set -e` and wrap every install in an existence check with a `pretty_print "${yellow}...already installed, skipping${neutral}"` branch. Follow that pattern so re-running `make` stays cheap and CI-safe.
- `.editorconfig`: 2-space indent, LF, final newline; tabs in `Makefile`.
- The software list in `README.md` is hand-maintained and has drifted from `install/Brewfile`/`Caskfile`; update it deliberately rather than trusting it as the manifest.
