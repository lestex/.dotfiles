## mac-setup
### a simple script that installs a software on your mac
[![Build Status](https://travis-ci.org/lestex/mac-setup.svg?branch=master)](https://travis-ci.org/lestex/mac-setup)

The script installs the following software:

Prerequisites
- [brew](https://brew.sh/)
- [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
- vim
- coreutils
- findutils

List of apps:
- iterm2
- skype
- telegram
- virtualbox
- google-chrome
- slack
- vlc
- visual-studio-code
- moom
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

Vscode extensions:
- ms-python.python
- lukehoban.go
- mauve.terraform
- bierner.markdown-preview-github-styles
- bbenoist.vagrant
- haaaad.ansible
- PeterJausovec.vscode-docker
- ms-vscode.cpptools
- misogi.ruby-rubocop
- ms-python.python
- rebornix.ruby
- redhat.java
- robertohuertasm.vscode-icons
- timonwong.ansible-autocomplete

Additional software:
- [rvm](https://rvm.io)

Run:

    ➜ chmod +x mac-setup
    ➜ ./mac-setup

or

    ➜ yes | bash <(curl -s https://raw.githubusercontent.com/lestex/mac-setup/master/mac-setup)

To install coreutils and findutils to the PATH run:

    ➜ printf 'export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"' >> ~/.zshrc
