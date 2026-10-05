# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal dotfiles + machine bootstrap for macOS only. Pure bash + Make — no build system, no test framework, no package manifest. The "program" is a set of idempotent-ish provisioning scripts that install software and **copy** config files into `$HOME`.

## Commands

```sh
make          # default goal: run the full macOS provisioning
make help     # list targets (parsed from `## ` comments in the Makefile)
make macos    # same as make; fails fast on anything but macOS
```

There is no lint/test tooling beyond one test. CI (`.github/workflows/mac.yaml`) runs `make` on `macos-latest`, so **running `make` on macOS is the test**. It runs on pull requests touching `scripts/mac-setup`, `scripts/common`, `install/**`, `local/**`, `tests/**`, `.config/**`, `Makefile`, `bin/**` or its own workflow file. The one test, `tests/theme-switcher-test.sh`, runs in mac CI after `make` (with `THEME_SWITCHER_TEST_REQUIRE_ENGINE=1`, so a missing engine fails rather than skips) and can be run by hand on macOS; it uses a throwaway `HOME`, a fake terminal and a stub `osascript`, so it never touches the real desktop.

Scripts must be run from the repo root — they do `source scripts/common` with a relative path. Use `make`, not `./scripts/...` from elsewhere.

## Architecture

**Entry point.** `make` (goal `all` → `macos`) checks `bin/is-macos` and exits with an error on any other OS, then runs `scripts/mac-setup`. The Makefile also exports `XDG_CONFIG_HOME`.

**`scripts/common`** is sourced by every script and is the single source of truth for the pinned toolchain versions (`TERRAFORM_VERSION`, `PYTHON_VERSION`, `GO_VERSION`) plus the color vars and `pretty_print`. Bump versions here, not in the individual scripts.

**Setup.** `scripts/mac-setup` installs oh-my-zsh + Homebrew, then `brew bundle` against `install/Brewfile` (formulae) and `install/Caskfile` (casks), then installs Alacritty from its official release DMG (no formula, and Homebrew disabled the unsigned cask) pinned by `ALACRITTY_VERSION` / `ALACRITTY_DMG_SHA256` in `scripts/common` — bumping Alacritty means updating both, the checksum being the asset `digest` GitHub publishes for the release, then loops `install/Codefile` through `code --install-extension`, then rust/tfenv/pyenv, then copies configs and fonts. After a fresh Homebrew install it `eval`s `brew shellenv` itself, because the installer does not put `brew` on the running script's `PATH` (and `/opt/homebrew/bin` is not on it by default on Apple Silicon); CI runners ship with brew, so CI never exercises that branch.

**Third-party taps need explicit trust.** Homebrew 6 refuses to load formulae from non-official taps unless they are trusted (`HOMEBREW_REQUIRE_TAP_TRUST` defaults to `true`), and the trust store is `$XDG_CONFIG_HOME/homebrew/trust.json` — which the Makefile repoints at `~/.config`, so a developer's manual `brew trust` (stored in `~/.homebrew/trust.json`) does *not* apply under `make`. `mac-setup` therefore taps and trusts `jandedobbeleer/oh-my-posh` itself before `brew bundle`. Any future tapped formula needs the same treatment or both `make` and CI will fail.

**Configs are copied, not symlinked.** `cp -R .config/* ~/.config`, `.config/zsh/.zshrc` → `~/.zshrc`, VS Code settings → the OS-specific application-support path. Consequences:
- Editing `~/.config/...` does not flow back to the repo. Edit the repo file, then re-run `make`.
- Re-running `make` overwrites local tweaks under `~/.config` and `~/.zshrc`.
- Directories cloned into `~/.config` by the scripts (vifm colors, tmux tpm) are guarded by existence checks and are not tracked here.
- Two files are templated rather than copied verbatim: `.config/ghostty/config` and `.config/alacritty/alacritty.toml` hold a `@BREW_PREFIX@` placeholder (the tmux path each terminal launches; kitty runs the login shell and uses its own tabs) that `mac-setup` rewrites with `sed` after the copy, because a terminal needs an absolute command path (GUI launches inherit no shell `PATH`) and the Homebrew prefix differs by architecture.

**Theme switching (macOS) runs an external theme engine in place.** `local/bin/theme-switcher` (installed to `~/.local/bin` by `mac-setup`) reads palettes (`themes/*/colors.toml`), templates (`default/themed/*.tpl`) and the engine's color-resolver, OSC and template-renderer scripts from a managed engine checkout — nothing from it is copied into this repo. `mac-setup` runs `theme-switcher engine install "$THEME_ENGINE_REF"`: a shallow, partial (`--filter=blob:none`), sparse fetch of `bin/`, `default/themed/` and `themes/` minus `themes/*/backgrounds/` (~26 MB) into `~/.local/share/theme-switcher/.engine`, at the full commit SHA pinned in `scripts/common` (a no-op when already there). Wallpapers are read from git on demand when a theme is first used, so only themes in use are downloaded. Bump `THEME_ENGINE_REF` deliberately: CI tests theme-switcher against the pin, which is what catches upstream renaming the engine's internals. `THEME_SWITCHER_ENGINE` points theme-switcher at a different checkout (e.g. a full clone for development); its wallpapers are then read from disk. The engine's own name (its script prefix, the `<NAME>_PATH` variable it reads, the dirs its renderer writes, and the default checkout path) is set once, as `ENGINE_NAME` in `local/bin/theme-switcher`; keep it out of every other file. `mac-setup` and the test detect the engine with `theme-switcher list` rather than repeating its path. Those scripts are `#!/bin/bash` (3.2 on macOS) and call each other by name, so the wrapper re-execs itself under Homebrew's bash 5 and runs them through PATH shims. The renderer hardcodes its staging and user-template dirs under `$HOME`, so it runs with a scratch `HOME` whose two dirs symlink to theme-switcher's own; all state stays under `theme-switcher` paths. The wrapper adds only the macOS parts: staging into `~/.local/state/theme-switcher/current/theme/`, refusing a theme if any `{{ ... }}` survives rendering, repainting running terminals by writing OSC sequences to each terminal child's TTY (`pgrep -P` + `ps -o tty=`, no `/proc`), and the desktop picture via `osascript`. Ghostty (`config-file`), Alacritty (`import`, reloaded automatically) and kitty (`include ${HOME}/...`, sent `SIGUSR1`) include the generated files; Ghostty is never signalled, since it has no external reload on macOS. The chosen background is a plain-text path in `current/background` (empty = a solid PNG in the palette background color); wallpapers are imported into `~/.local/share/theme-switcher/<theme>/backgrounds/`, never committed here.

**Font switching (macOS).** `local/bin/font-switcher` (installed to `~/.local/bin` by `mac-setup`, plain bash 3.2-compatible) writes the chosen family and size (`set <family>`, `size <points>`, default 14) into `~/.local/state/font-switcher/current/{ghostty.conf,alacritty.toml,kitty.conf}`, which the three terminal configs include — so the main configs set no font family or size, and the choice survives `make` re-copying them. It lists and validates fonts through AppKit via `osascript -l JavaScript`; a family counts as monospace when `i`, `M`, `W` and `.` share one advance width, because Nerd Font "Liga" builds such as Liga SFMono leave the fixed-pitch flag unset. Names are matched case-insensitively and restricted to `[A-Za-z0-9 ._+-]`, since they are written into three config syntaxes. `install/Caskfile` carries a set of Nerd Fonts to choose from (JetBrainsMono, Caskaydia, Meslo, FiraCode, VictorMono, Bitstrom Wera, Iosevka); `mac-setup` sets Liga SFMono (from `fonts/`) on first run and only warns if it is not registered yet. Alacritty applies a change by itself, kitty gets `SIGUSR1`, Ghostty needs Cmd+Shift+, or a new window.

**Shared terminal defaults.** Ghostty, Alacritty and kitty share one set of defaults — padding 14, no decorations, block cursor without blink (shell integration told not to restyle it), no close prompt, Shift/Ctrl+Insert paste/copy, Shift+Enter and Alt+Shift+Enter sent as CSI-u (`13;2u` / `13;4u`). When changing one terminal's behaviour, keep the other two matching. Ghostty and Alacritty launch tmux; kitty keeps the login shell and its own tabs (bottom powerline bar, cmd+1..0, cmd+t/n).

## Conventions

- Scripts use `set -e` and wrap every install in an existence check with a `pretty_print "${yellow}...already installed, skipping${neutral}"` branch. Follow that pattern so re-running `make` stays cheap and CI-safe.
- `.editorconfig`: 2-space indent, LF, final newline; tabs in `Makefile`.
- The software list in `README.md` is hand-maintained and has drifted from `install/Brewfile`/`Caskfile`; update it deliberately rather than trusting it as the manifest.
