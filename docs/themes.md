# Themes

```sh
theme-switcher pick                  # choose in fzf with a live preview; Enter applies
theme-switcher list                  # themes, current one marked
theme-switcher set tokyo-night       # apply a theme
theme-switcher bg next               # next wallpaper of the current theme
theme-switcher bg set ~/Pictures/x.jpg
theme-switcher bg none               # solid background in the theme's color
theme-switcher appearance            # re-apply the macOS part only
theme-switcher vscode                # re-apply the VS Code part only
```

The picker shows each theme's palette, and in Ghostty and kitty also its screenshot. Alacritty can't show images, so it gets the palette only.

## What follows the theme

| | How | Open windows |
|---|---|---|
| Ghostty, kitty, Alacritty | each includes a generated color file | repainted right away |
| tmux | status bar and borders use the terminal's color names; panes are repainted | right away |
| btop | `~/.config/btop/themes/current.theme` points at the theme | right away |
| Neovim (LazyVim) | `~/.config/nvim/lua/plugins/theme.lua` points at the theme | right away; a missing colorscheme plugin is installed in the background first |
| VS Code | the theme's Marketplace extension, or the theme's colors on VS Code's Light/Dark Modern | right away; an extension being installed applies when it's ready |
| torrnado | `~/.config/torrnado/themes/current.toml` points at the theme | right away with torrnado's live reload ([#128](https://github.com/lestex/torrnado/pull/128)); otherwise on its next start |
| Pure prompt | uses the terminal's color names | right away |
| macOS | Dark/Light mode, accent and highlight color, desktop picture | right away |

What each one changes, so you know what to expect:
- **btop**: the installer only sets `color_theme = "current"` in your `btop.conf`; your own btop themes stay selectable. btop rewrites `btop.conf` when it quits, so quit it before re-running `./install.sh themes`.
- **torrnado**: only once it has a `~/.config/torrnado` folder. The installer changes only the value of the `theme` line in its `config.toml` to `"current"`, keeping your comment. The ten colors come from a template this repo ships in `.config/theme-switcher/themed/torrnado.toml.tpl`; success, warning and error are the theme's green, yellow and red.
- **Neovim**: the link is kept out of your Neovim config's git repo with `.gitignore`. A hand-written `theme.lua` is never replaced.
- **VS Code**: a theme that names a Marketplace extension gets it, and only `workbench.colorTheme` in `settings.json` changes. Any other theme selects VS Code's own Light Modern or Dark Modern, matching its mode, and its colors are written over it as three settings: `workbench.colorCustomizations`, `editor.tokenColorCustomizations` and `editor.semanticTokenColorCustomizations`, each kept on one line and scoped to that base theme. They're removed again when a Marketplace theme is used. That's because VS Code changes settings live, but keeps a theme's colors until the window reloads. If you write one of those three settings yourself, over several lines, it's left alone and you're told. Themes installed from git repos never install a VS Code extension (an extension is code), so they always get the colors this way.
- **macOS accent**: the closest of macOS's accent colors when the theme's accent is vivid; Graphite when it's muted or between colors (e.g. rose-pine's teal). The highlight (selected text) is a light tint of the accent, readable on light pages too. The menu bar can't be colored; it follows Dark/Light and the wallpaper.
- **Desktop picture**: the first time, macOS asks to let your terminal control System Events. Allow it, or the wallpaper won't change.

To undo the macOS part:
```sh
defaults delete -g AppleAccentColor; defaults delete -g AppleHighlightColor; defaults delete -g AppleAquaColorVariant
```

## What doesn't follow

- **Chrome and Brave.** The theme engine colors Chromium browsers with a `BrowserThemeColor` policy, which on Linux is mandatory. On a Mac without device management, Chrome only treats a policy set with `defaults` as *recommended*, and tested on Chrome it then ignores the color, even with the default theme selected. Making it mandatory takes a configuration profile approved by hand in System Settings each time, which can't follow a theme switch. Brave and other Chromium browsers read policies the same way. Set a color by hand instead: Customize Chrome, then the pipette swatch.
- **Already-open shells**: the prompt follows the theme, but a change to the prompt *config* needs `exec zsh`.

## Community themes

```sh
theme-switcher pick --catalog        # browse the gallery with previews; Enter installs
theme-switcher catalog               # the gallery, installed ones marked *
theme-switcher catalog gruv          # search it
theme-switcher install ayaka         # by name, or a git URL; then applies it
theme-switcher update                # pull every installed theme
theme-switcher remove ayaka
```

An installed theme is someone else's git repo, so only its colors and images are used. Lua files, terminal configs (they name the program a terminal runs), `vscode.json` and symlinks are dropped and listed on screen, and the terminal configs are generated from its colors instead. A theme that only ships an `alacritty.toml` gets its colors from that.

## Your own themes

- A theme: `~/.config/theme-switcher/themes/<name>/colors.toml` (copy one from the engine to start). Your own themes are trusted in full.
- A template: `~/.config/theme-switcher/themed/<file>.tpl`, overriding the engine's.

## Where things live

| Path | What |
|---|---|
| `~/.local/share/theme-switcher/.engine` | the theme engine, at the commit pinned in `scripts/common` |
| `~/.local/state/theme-switcher/current/theme/` | the generated files for the current theme |
| `~/.local/share/theme-switcher/<theme>/backgrounds/` | wallpapers, downloaded the first time a theme is used |
| `~/.config/theme-switcher/themes/` | your own and installed themes |

The engine is pinned so an upstream change can't break theme switching unnoticed: CI tests against the pin. Bump `THEME_ENGINE_REF` deliberately.
