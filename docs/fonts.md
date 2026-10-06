# Fonts

```sh
font-switcher pick                           # choose in fzf with a rendered sample; Enter uses it
font-switcher list                           # installed monospace fonts, current one marked
font-switcher set "JetBrainsMono Nerd Font"  # use it in all three terminals
font-switcher size 14                        # the size in all three terminals
font-switcher current
```

The default is **Liga SFMono Nerd Font** at 14pt. The installer also brings JetBrainsMono, CaskaydiaMono, Meslo LG, FiraCode, VictorMono, Bitstream Vera Sans Mono and Iosevka, all as Nerd Fonts from Homebrew. Any installed monospace font works.

## When a change shows

| Terminal | |
|---|---|
| Alacritty | by itself |
| kitty | reloaded for you |
| Ghostty | press Cmd+Shift+, (reload config), or open a new window |

The picker's sample is a rendered image in Ghostty and kitty. Alacritty shows text only, since a terminal can only draw text in its own font.

## How it works

Each terminal config includes a small generated file from `~/.local/state/font-switcher/current/`, so your choice survives the installer re-copying the configs. That's also why the main configs set no font. Font names may contain only letters, digits, spaces and `._+-`.
