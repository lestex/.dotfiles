## mac-setup
### a simple script that installs a software on your mac
[![Build Status](https://travis-ci.org/lestex/mac-setup.svg?branch=master)](https://travis-ci.org/lestex/mac-setup)

The script installs the following software:

Prerequisites
- [brew](https://brew.sh/)
- [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
- [vim](https://www.vim.org/)
- [coreutils](https://www.gnu.org/software/coreutils/)
- [findutils](https://www.gnu.org/software/findutils/)

List of apps:
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
- PeterJausovec.vscode-docker
- bbenoist.vagrant
- bierner.markdown-preview-github-styles
- castwide.solargraph
- haaaad.ansible  
- mauve.terraform
- misogi.ruby-rubocop
- ms-python.python
- ms-vscode.cpptools
- ms-vscode.Go
- rebornix.Ruby
- redhat.java
- robertohuertasm.vscode-icons
- secanis.jenkinsfile-support
- timonwong.ansible-autocomplete
- vscjava.vscode-java-debug
- vscjava.vscode-java-pack
- vscjava.vscode-java-test
- vscjava.vscode-maven

Additional software:
- [rvm](https://rvm.io)

Run:

    ➜ chmod +x mac-setup
    ➜ ./mac-setup

or

    ➜ yes | bash <(curl -s https://raw.githubusercontent.com/lestex/mac-setup/master/mac-setup)

To install coreutils and findutils to the PATH run:

    ➜ printf 'export PATH="$(brew --prefix coreutils)/libexec/gnubin:$PATH"' >> ~/.zshrc
