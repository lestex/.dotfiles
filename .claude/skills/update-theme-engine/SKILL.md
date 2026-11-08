---
name: update-theme-engine
description: Move theme-switcher's pinned theme engine (THEME_ENGINE_REF in scripts/common) to a newer upstream release, bringing in its new and changed themes, wallpapers and templates. Use when asked to update or bump the themes or the theme engine, to check upstream for new themes or settings, or to test theme-switcher against an upstream release. Runs check.sh, fixes what it flags in local/bin/theme-switcher, moves the pin, updates the docs and opens a PR.
---

# Update the theme engine

theme-switcher (`local/bin/theme-switcher`) runs an upstream theme engine at one pinned commit. The engine's repo is `ENGINE_REPO` and its name is `ENGINE_NAME`, both in `local/bin/theme-switcher`. The pin is `THEME_ENGINE_REF` in `scripts/common`, a full commit SHA. Upstream targets Linux (Arch, Hyprland), so a new release can break theme-switcher on macOS. This skill finds out how, fixes it on our side and moves the pin.

## Rules

- **Pin a full release only.** Pin the release's commit, from `git rev-parse <tag>^{commit}`, never a tag or branch name. Skip prereleases and branch heads unless the user names one.
- **Never apply a theme against the real HOME while checking.** `theme-switcher set` repaints every open terminal and tmux pane, and changes the desktop and macOS appearance. Only `check.sh` applies themes, in a scratch HOME with `THEME_SWITCHER_NO_DESKTOP=1`, `THEME_SWITCHER_TERMINALS=""`, `THEME_SWITCHER_APPS=""` and a private `TMUX_TMPDIR`. If you must try something by hand, use the same variables.
- **Fix on our side.** Fixes go in `local/bin/theme-switcher` and the tests, never in the engine. Write engine commands as `$ENGINE_NAME-...`. The engine's literal name appears only in `ENGINE_NAME`; keep it out of every other file, this skill included.
- **Don't port copied settings on your own.** `check.sh` reports changes to settings this repo copied from the engine project (tmux.conf, the Ghostty, Alacritty and kitty configs, the shell aliases, the tmux functions). Show the diff and ask before changing `.config/`.
- **Work on a branch** from an up-to-date `master`, never on `master` itself.

## Steps

### 1. Start a branch

```sh
git checkout master && git pull
git checkout -b theme-engine-<version>      # e.g. theme-engine-4.6.0
```

The working tree must be clean.

### 2. Run the check

```sh
.claude/skills/update-theme-engine/check.sh            # the latest release
.claude/skills/update-theme-engine/check.sh v4.6.0     # a given tag
```

Options: `--from <ref>` compares from another ref instead of the pin. `--all-themes` applies every theme, not only those at risk. `--keep` keeps the scratch dir for inspection; its path is printed at the end.

It takes a few minutes and changes nothing outside a temp dir. It needs `gh`, network access, Homebrew bash and gawk. It reports, in order:

| Section | What it shows |
|---|---|
| Versions | the pin, the target, prerelease or not, commit count |
| Themes | added, removed (with the upstream commit), changed text files; whether the themes the installer and tests use still exist; whether this Mac's current theme is gone |
| Wallpapers | file types; any type `IMAGE_PATTERN` misses; subfolders, which are skipped |
| Templates | added or changed `default/themed/*.tpl`; new `{{ function ... }}` syntax |
| Engine scripts | each script theme-switcher runs or stands in for: changed, unchanged or gone; engine commands those scripts call that theme-switcher doesn't provide |
| GNU-only features | uses of GNU-only tool features in those scripts, at the pin and at the target |
| Copied settings | the settings this repo copied, with diffs |
| Tests | every `tests/*-test.sh` that runs theme-switcher, against the target |
| Applying themes | `set` for each added, text-changed or repo-used theme, the current one, and three with wallpaper subfolders; each must render a multi-line `ghostty.conf` with a background color and no `{{ }}` |

Exit 0 means nothing blocks the move. Exit 1 means lines starting with `!!` need action. If the pin is already the latest release, tell the user it's up to date and stop.

### 3. Fix each `!!`

Re-run `check.sh` after each fix until it exits 0.

| Flag | Fix |
|---|---|
| `<engine>-X is called ... but has no shim` | Read it: `git show <tag>:bin/<engine>-X` in the check's clone (use `--keep`). If it only serves Linux (Hyprland, GTK, the engine's own toggles), add a no-op stand-in in `engine()` as for `ENGINE_GLASS`: an `ENGINE_<NAME>="$ENGINE_NAME-X"` variable with a one-line comment, plus a `printf '#!/bin/sh\nexit 0\n'` shim. If it writes into the theme being rendered, run it for real instead: add its variable to the `for name in` list. |
| `theme-switcher runs <engine>-X, which <tag> no longer has` | Find what replaced it: `git log --format='%h %s' <pin>..<tag> -- bin/<engine>-X`, and grep the renderer. Update the `ENGINE_*` variable and its callers. |
| `<feature> is new in <tag> ... macOS lacks it` | Shim the GNU tool the way gawk is shimmed (e.g. `gsed` from `gnu-sed` as `sed`). Link it in `engine()`, add the check to `require_engine`, add the formula to the base tools in `scripts/steps/20-tools.sh`, and update the docs (step 6). awk features are already covered by the gawk shim. |
| `<test> fails against <tag>` | Read the `not ok` lines. Fix theme-switcher when it really broke. Change a test only when the engine's data changed under it (in 4.5 the first wallpaper became `.webp`), and keep what the test checks. |
| `theme 'X' is used by the installer or tests but has no colors.toml` | Replace it: the default in `scripts/steps/90-themes.sh` (`set tokyo-night`), the tests, and any docs naming it. |
| `wallpaper ... does not match IMAGE_PATTERN` | Add the extension to `IMAGE_PATTERN`. If the desktop can't show that type, also add it to the `sips -s format png` conversion in the desktop code. |
| `X: set failed` or `ghostty.conf has N lines`, `no background color`, `placeholder survived` | The renderer's output is wrong on macOS. Re-run with `--keep` and read `<scratch>/sethome/.local/state/theme-switcher/current/theme/` and the renderer at the tag. 4.5's one-line files came from gawk's `RT`. |
| `<tag> is a prerelease` | Ask the user. |

### 4. Move the pin

In `scripts/common`, set `THEME_ENGINE_REF` to the full SHA printed after `to:`. Change the comment above it to `Currently the <tag> release.`

Then:

```sh
bash -n local/bin/theme-switcher
.claude/skills/update-theme-engine/check.sh <tag>      # pinned == target: tests and themes only
```

### 5. Copied settings

If any copied setting changed, show the user the diff and ask whether to port it. Port only what they choose, into the matching `.config/` file.

### 6. Docs

Update in the same commit:
- `docs/themes.md`: the sentence naming the pinned release.
- `CLAUDE.md`, the theme-switcher paragraph: new stand-ins, shims, base tools or wallpaper handling.
- `docs/installer.md`: when the base tools change, in the base sentence and the `tools` row.
- `docs/themes.md`: new user-visible behavior.

### 7. Commit and open a PR

Commit message:

```
Move the theme engine to <tag>

<One paragraph: new and removed themes. One bullet per fix: what broke on
macOS, why, and the fix.>
```

PR: title as the commit. The body lists added and removed themes, each fix with its cause, any test change and why, and what you ran (`check.sh` result, themes applied). CI (`.github/workflows/mac.yaml`) runs the installer with the new pin, then every test with `THEME_SWITCHER_TEST_REQUIRE_ENGINE=1`.

### 8. Report to the user

- Added and removed themes. If their current theme was removed, say which theme replaces it.
- Each fix, in a line.
- Copied-settings changes and what was ported.
- The PR link.
- How to install it locally, from the branch or from `master` after the merge:

  ```sh
  ./install.sh tools themes
  theme-switcher set "$(theme-switcher current)"   # re-render the current theme with the new engine
  ```

## Past moves

- **4.0.4 → 4.5.0:**
  - The renderer started writing lines with gawk's `RT`, which macOS awk lacks, so every file came out on one line. Fix: gawk as a base tool, run as the engine's `awk`.
  - The renderer started calling `$ENGINE_NAME-theme-set-glass`, for Hyprland only. Fix: a no-op stand-in.
  - 16 themes gained `backgrounds/intros/` video folders. Fix: only files count as wallpapers.
  - Wallpapers moved to `.webp`. Fix: a test change only; theme-switcher already converted them.
