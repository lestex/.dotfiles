SHELL = /bin/bash
.DEFAULT_GOAL := all
export XDG_CONFIG_HOME := $(HOME)/.config

.PHONY: help all macos

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; \
	{printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: macos ## set up this Mac

macos: ## run the macOS setup
	@bin/is-macos || { echo "These dotfiles support macOS only." >&2; exit 1; }
	scripts/mac-setup
