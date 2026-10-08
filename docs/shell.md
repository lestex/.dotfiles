# Shell

zsh with oh-my-zsh, set up from `.config/zsh/` in the repo.

## Layout

`~/.zshrc` only loads oh-my-zsh with its plugins (git, brew, terraform, kubectl, zsh-autosuggestions, zsh-syntax-highlighting), then sources every `~/.zshrc.d/*.zsh` in name order:

| File | |
|---|---|
| `10-path.zsh` | `/usr/local/bin` and `/usr/local/sbin`, `PLATFORM` |
| `20-languages.zsh` | mise, and cargo if Rust is installed |
| `30-cloud.zsh` | gcloud path and completion, krew, k9s, the `kcb` alias (a kind cluster) |
| `90-prompt.zsh` | the Pure prompt, last |

**Your own settings** go in a file of your own in `~/.zshrc.d`, e.g. `60-local.zsh`. The installer only replaces its own files there. It also removes a file it installed earlier that the repo has since dropped or renamed, so it isn't sourced twice. It knows which files are its own from `~/.local/state/dotfiles/zshrc.d`.

**Changing the repo's shell config**: edit `.config/zsh/`, run `./install.sh shell`, then `exec zsh` in each open terminal. A shell that is already running keeps its old config until then.

## Languages and tools

[mise](https://mise.jdx.dev) manages Python, Go, Terraform, Node and the AWS CLI, in place of pyenv, goenv, tfenv and nvm. The global versions are in `~/.config/mise/config.toml`, from the repo's `.config/mise/config.toml`:

```toml
[tools]
python = "3.14"     # the newest 3.14.x when installed
go = "1.26"
terraform = "1.15"
node = "lts"
aws-cli = "latest"
```

```sh
mise ls                      # what's installed and in use here
mise use python@3.13         # pin a version for this project (writes mise.toml)
mise upgrade                 # move to the newest version each pin allows
```

A project can also pin a version with the files it already has: `.python-version`, `.go-version`, `.terraform-version` or `.nvmrc`. mise switches as you `cd` into it. To change the global versions, edit the repo's config and run `./install.sh languages configs`. Like other configs, `~/.config/mise/config.toml` is overwritten by the installer, so `mise use -g` changes there don't last.

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
