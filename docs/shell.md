# Shell

zsh with oh-my-zsh, set up from `.config/zsh/` in the repo.

## Layout

`~/.zshrc` only loads oh-my-zsh with its plugins (git, brew, terraform, kubectl, zsh-autosuggestions, zsh-syntax-highlighting), then sources every `~/.zshrc.d/*.zsh` in name order:

| File | |
|---|---|
| `10-path.zsh` | `/usr/local/bin` and `/usr/local/sbin`, `PLATFORM` |
| `20-languages.zsh` | pyenv, goenv, and cargo if Rust is installed |
| `30-cloud.zsh` | gcloud path and completion, krew, k9s, the `kcb` alias (a kind cluster) |
| `90-prompt.zsh` | the Pure prompt, last |

**Your own settings** go in a file of your own in `~/.zshrc.d`, e.g. `60-local.zsh`. The installer only replaces its own files there. It also removes a file it installed earlier that the repo has since dropped or renamed, so it isn't sourced twice. It knows which files are its own from `~/.local/state/dotfiles/zshrc.d`.

**Changing the repo's shell config**: edit `.config/zsh/`, run `./install.sh shell`, then `exec zsh` in each open terminal. A shell that is already running keeps its old config until then.

## Prompt

[Pure](https://github.com/sindresorhus/pure):
```
~/projects/self/.dotfiles master* ⇡ 6s
❯
```
- the folder;
- the git branch, with `*` when there are uncommitted changes and ⇣⇡ when behind or ahead of the remote (checked in the background, so the arrows can appear a moment later);
- how long the last command took, when over 5 s;
- `❯`, red after a failed command, with the exit code on the right.

The colors are the terminal's color names, so the prompt follows the theme. In themes whose red is close to their magenta, the exit code is what shows a failure. To change the colors or what's shown, edit the `zstyle` lines in `90-prompt.zsh` ([Pure's options](https://github.com/sindresorhus/pure#options)).
