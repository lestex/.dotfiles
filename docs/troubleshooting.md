# Troubleshooting

## Shell

**`_omp_get_prompt: no such file or directory: …/oh-my-posh` after every command**
That shell started before the switch to Pure. Run `exec zsh` in it, or open a new one. The same goes for any shell config change: open shells keep the old config.

**`goenv: version '1.24.13' is not installed (set by ~/.go-version)`**
Your global Go version isn't installed. Use one you have, or install it:
```sh
goenv versions
goenv global 1.26.8      # or: goenv install 1.24.13
```

## Homebrew

**`It seems there is already a Font at '~/Library/Fonts/…'`** (or an App in `/Applications`)
A copy installed outside Homebrew is in the way. For a font, check the file is the same font, delete it, and re-run the step. For an app, `brew install --cask --adopt <name>` takes over the existing one.

**`Refusing to load … from untrusted tap`**
Homebrew 6 only loads packages from taps you trust. To uninstall something from such a tap, name its type, which may avoid loading it: `brew uninstall --formula <name>`. Or trust the tap first: `brew trust --tap <owner>/<tap>`. The installer keeps its own trust list under `~/.config/homebrew`, separate from your shell's, so trusting from your shell doesn't affect the installer.

**A package is outdated**
The installer never upgrades. Run `brew upgrade`.

**`brew uninstall` removed something else too**
Homebrew removes dependencies nothing needs any more (e.g. `go` after uninstalling oh-my-posh). Reinstall it with `brew install` if you use it directly.

## Themes

**The desktop picture doesn't change**
macOS asked to let your terminal control System Events, and it wasn't allowed. Turn it on in System Settings → Privacy & Security → Automation.

**btop is back on its old theme**
btop rewrites `btop.conf` when it quits. Quit btop, then run `./install.sh themes`.

**VS Code didn't switch**
The theme's extension is installing in the background, and VS Code switches when it's ready. To wait for it: `theme-switcher vscode`. If you customize VS Code's colors yourself, theme-switcher leaves that setting alone and says so, and the theme's colors for it don't apply.

**Neovim kept its colors**
The theme's colorscheme plugin is being installed in the background, and Neovim switches when it's done. A hand-written `~/.config/nvim/lua/plugins/theme.lua` is never replaced (you're told so).

**Chrome or Brave don't follow the theme**
Not possible on macOS: see [what doesn't follow](themes.md#what-doesnt-follow).

**After a failed command the `❯` isn't red**
Some themes' red is close to their magenta (lumon's are both blue). The exit code on the right shows the failure in every theme.

## Fonts

**Ghostty still shows the old font**
Ghostty can't be reloaded from outside: press Cmd+Shift+, or open a new window.

**A font you just installed isn't listed**
macOS registers new fonts in the background. font-switcher retries with the files in `~/Library/Fonts` when a name isn't found. If it's still missing, wait a moment and try again.
