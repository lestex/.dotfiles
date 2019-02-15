## mac-setup - a script that installs a software on your mac
![Maintained by Leandevops.io](https://img.shields.io/badge/maintained%20by-leandevops-green.svg)
[![Build Status](https://travis-ci.org/lestex/mac-setup.svg?branch=master)](https://travis-ci.org/lestex/mac-setup)

Run:

    ➜ chmod +x mac-setup
    ➜ ./mac-setup

or

    ➜ yes | bash <(curl -s https://raw.githubusercontent.com/lestex/mac-setup/master/mac-setup)

To install coreutils and findutils to the PATH run:

    ➜ printf 'export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"' >> ~/.zshrc

The script installs the following software:

Prerequisites
- [brew](https://brew.sh/)
- [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
- [vim](https://www.vim.org/)
- [coreutils](https://www.gnu.org/software/coreutils/)
- [findutils](https://www.gnu.org/software/findutils/)

List of applications:
- iterm2
- skype
- telegram
- virtualbox
- google-chrome
- slack
- vlc
- visual-studio-code
- vagrant
- ansible
- ansible-lint
- docker
- watch 
- htop
- awscli
- terraform
- packer
- google-cloud-sdk
- microsoft-teams

Vscode extensions:

Refer to the [code](https://github.com/leandevops/mac-setup/blob/master/mac-setup#L101-L132) for a list.

Additional software:
- [rvm](https://rvm.io)
