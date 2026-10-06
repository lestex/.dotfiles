# oh-my-zsh, then everything else from ~/.zshrc.d/*.zsh, in name order.
# Installed from the dotfiles repo (.config/zsh); edit it there and re-run
# ./install.sh shell. A file of your own in ~/.zshrc.d is kept by the installer.

export ZSH="$HOME/.oh-my-zsh"

# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  brew
  terraform
  kubectl
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

for file in "$HOME"/.zshrc.d/*.zsh(N); do
  source "$file"
done
unset file
