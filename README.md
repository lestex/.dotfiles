## .dotfiles install software on your mac
[![Maintained by Leandevops.io](https://img.shields.io/badge/maintained%20by-leandevops-green.svg)](https://leandevops.io)
![macOS](https://github.com/lestex/.dotfiles/actions/workflows/mac.yaml/badge.svg)

## Installation
On a fresh Mac:
```sh
bash <(curl -fsSL https://raw.githubusercontent.com/lestex/.dotfiles/master/install.sh)
```
This downloads the repo into `~/.dotfiles` and sets the Mac up. Re-run it (or `./install.sh` from a checkout) to update; it is safe to run again.

## Software Installed
### common
- coreutils
- findutils
- jq
- htop
- btop
- tree
- vim
- neovim
- vifm
- ssh-copy-id
- telnet
- tmux

### development tools
- git
- pyenv
- tfenv
- goenv
- bitwarden-cli
- node
- helm
- gpg
- watch
- kind
- podman
- starship
- kubectx
- krew
- k9s

## Casks
# common
- authy
- alacritty
- bitwarden
- daisydisk
- google-chrome
- vlc
- rectangle
- mpv
- utm

### development tools
- google-cloud-sdk
- visual-studio-code

### messaging
- slack
- telegram
- whatsapp-beta

### VSCode extensions
- editorconfig.editorconfig
- bbenoist.vagrant
- golang.go
- 4ops.terraform
- magicstack.magicpython
- ms-azuretools.vscode-docker
- ms-python.python
- ms-python.vscode-pylance
- ms-vscode-remote.remote-containers
- pkief.material-icon-theme
- wholroyd.jinja
- redhat.ansible
- GoogleCloudTools.cloudcode
- GitHub.github-vscode-theme
- tamasfe.even-better-toml
