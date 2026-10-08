# Hotkeys

| Keys | Opens |
|---|---|
| Cmd+Ctrl+T | the terminal (Ghostty, or the one you choose) |
| Cmd+Ctrl+B | the browser (Google Chrome) |

Each one opens the app, or brings it to the front if it's already running. They work in every app, alongside Rectangle's window shortcuts. They use Cmd+Ctrl because Cmd+T (new tab) and Cmd+B (bold) belong to the apps.

[Hammerspoon](https://www.hammerspoon.org) runs them, from `~/.config/hammerspoon/init.lua` (the repo's `.config/hammerspoon`). It starts at login, and its icon sits in the menu bar. Its Preferences and Console windows follow macOS's Dark/Light mode, and so the theme. It doesn't need the Accessibility permission its Preferences window asks for.

## Choosing the terminal

```sh
terminal-switcher kitty      # or ghostty, alacritty
terminal-switcher            # pick one in fzf
```

It applies on the next Cmd+Ctrl+T, with nothing to reload. Your choice is kept in `~/.local/state/terminal-switcher/current`.

## Other apps

Put your choice in `~/.config/hammerspoon/local.lua`. The installer never touches that file, and Hammerspoon reloads as soon as you save it:

```lua
return { browser = "Safari" }
```

Use the app's name as it appears in `/Applications`, without `.app`. A name that doesn't open shows a short message on screen. It's a file rather than an environment variable because apps started by macOS don't see your shell's environment.

## Adding a hotkey

Add a line to `.config/hammerspoon/init.lua` in the repo, then run `./install.sh configs`:

```lua
hs.hotkey.bind({ "cmd", "ctrl" }, "e", function() hs.application.launchOrFocus("Visual Studio Code") end)
```

Avoid Cmd+Ctrl+Q (lock screen), Cmd+Ctrl+F (full screen) and Cmd+Ctrl+Space (emoji picker), which macOS uses.
