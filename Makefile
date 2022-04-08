SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/is-supported bin/is-macos macos linux)
PATH := $(DOTFILES_DIR)/bin:$(PATH)
.DEFAULT_GOAL := help
export XDG_CONFIG_HOME := $(HOME)/.config

.PHONY: test

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; \
	{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: $(OS) ## check the OS

linux: ## run linux specific tasks
	@echo "on linux"

macos: ## run macos specific tasks
	@echo "on mac"
	brew bundle --file install/Brewfile
	brew bundle --file install/Caskfile
