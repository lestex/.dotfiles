SHELL = /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
OS := $(shell bin/is-supported bin/is-macos macos linux)
PATH := $(DOTFILES_DIR)/bin:$(PATH)
.DEFAULT_GOAL := all
export XDG_CONFIG_HOME := $(HOME)/.config

.PHONY: test

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; \
	{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: $(OS) ## check the OS

linux: ## run linux specific tasks
	@echo "on linux"
	scripts/linux-pre
	scripts/linux-install

macos: ## run macos specific tasks
	@echo "on mac"
	scripts/mac-setup
