# Completion for zsh. The cask was renamed google-cloud-sdk -> gcloud-cli; the
# old Caskroom path only still resolves on machines that were migrated, not on
# fresh installs. $HOMEBREW_PREFIX also covers arm64 vs Intel without branching.
GCLOUD_SDK="${HOMEBREW_PREFIX:-$(brew --prefix)}/Caskroom/gcloud-cli/latest/google-cloud-sdk"
[[ -f "$GCLOUD_SDK/path.zsh.inc" ]] && source "$GCLOUD_SDK/path.zsh.inc"
[[ -f "$GCLOUD_SDK/completion.zsh.inc" ]] && source "$GCLOUD_SDK/completion.zsh.inc"

# kubectl plugins
export PATH="${PATH}:${HOME}/.krew/bin"

# set k9s config dir for mac
if command -v k9s &>/dev/null; then
  export K9SCONFIG=~/.config/k9s/
fi

alias kcb="kind create cluster --name basic --config $HOME/.config/kind/cluster-basic.yaml"

# add alias for podman
# alias docker=podman
