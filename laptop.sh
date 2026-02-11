#!/bin/bash

# ./laptop.sh

# - installs system packages with Homebrew package manager
# - changes shell to Z shell (zsh)
# - creates symlinks for dotfiles to `$HOME`
# - installs programming language runtimes
# - installs or updates Vim plugins

# This script can be safely run multiple times.

set -eux

# Create local configs
touch "$LAPTOP"/shell/zshrc.local

# Homebrew
BREW="/opt/homebrew"

if [ ! -d "$BREW" ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

export PATH="$BREW/bin:$PATH"

brew analytics off
brew update-reset
brew bundle --file=- <<EOF
brew "asdf"
brew "awscli"
brew "bat"
brew "fd"
brew "fzf"
brew "gh"
brew "git"
brew "gmp"
brew "go"
brew "helm"
brew "jq"
brew "libyaml"
brew "lua-language-server"
brew "neovim"
brew "openssl@3"
brew "pgformatter"
brew "postgresql"
brew "readline"
brew "ripgrep"
brew "ruby-build"
brew "rust"
brew "shellcheck"
brew "snyk-cli"
brew "stylua"
brew "the_silver_searcher"
brew "tldr"
brew "tree"
brew "uv"
brew "vim"
brew "watch"
brew "yarn"
brew "yazi"
brew "yq"
brew "zellij"
brew "zsh"

cask "1password-cli"
cask "ngrok"
cask "pgadmin4"
cask "warp"
cask "visual-studio-code"
EOF

brew upgrade
brew autoremove
brew cleanup

# zsh
update_shell() {
  sudo chown -R "$(whoami)" "$BREW/share/zsh" "$BREW/share/zsh/site-functions"
  chmod u+w "$BREW/share/zsh" "$BREW/share/zsh/site-functions"
  shellpath="$(command -v zsh)"

  if ! grep "$shellpath" /etc/shells > /dev/null 2>&1 ; then
    sudo sh -c "echo $shellpath >> /etc/shells"
  fi

  chsh -s "$shellpath"
}

case "$SHELL" in
  */zsh)
    if [ "$(command -v zsh)" != "$BREW/bin/zsh" ] ; then
      update_shell
    fi
    ;;
  *)
    update_shell
    ;;
esac

# Symlinks
(
  ln -sf "$PWD/asdf/asdfrc" "$HOME/.asdfrc"
  ln -sf "$PWD/asdf/tool-versions" "$HOME/.tool-versions"

  # ln -sf "$PWD/vim/vimrc" "$HOME/.vimrc"

  # mkdir -p "$HOME/.vim/ftdetect"
  # mkdir -p "$HOME/.vim/ftplugin"
  # mkdir -p "$HOME/.vim/syntax"
  # (
  #   cd vim
  #   ln -sf "$PWD/coc-settings.json" "$HOME/.vim/coc-settings.json"
  #   for f in {ftdetect,ftplugin,syntax}/*; do
  #     ln -sf "$PWD/$f" "$HOME/.vim/$f"
  #   done
  # )

  ln -sf "$PWD/git/gitconfig" "$HOME/.gitconfig"
  ln -sf "$PWD/git/gitignore" "$HOME/.gitignore"
  ln -sf "$PWD/git/gitmessage" "$HOME/.gitmessage"

  mkdir -p "$HOME/.bundle"
  ln -sf "$PWD/ruby/bundle/config" "$HOME/.bundle/config"
  ln -sf "$PWD/ruby/gemrc" "$HOME/.gemrc"
  ln -sf "$PWD/ruby/irbrc" "$HOME/.irbrc"
  ln -sf "$PWD/ruby/rspec" "$HOME/.rspec"

  mkdir -p "$HOME/.ssh"
  ln -sf "$PWD/shell/ssh" "$HOME/.ssh/config"

  mkdir -p "$HOME/.config/bat"
  ln -sf "$PWD/shell/bat" "$HOME/.config/bat/config"

  ln -sf "$PWD/shell/curlrc" "$HOME/.curlrc"
  ln -sf "$PWD/shell/hushlogin" "$HOME/.hushlogin"
  ln -sf "$PWD/shell/zshrc" "$HOME/.zshrc"

  ln -sf "$PWD/sql/psqlrc" "$HOME/.psqlrc"

  mkdir -p "$HOME/.config/zellij"
  ln -sf "$PWD/shell/zellij.kdl" "$HOME/.config/zellij/zellij.kdl"

  # Vim
  mkdir -p "$HOME/.config/nvim"
  ln -sf "$PWD/vim/init.lua" "$HOME/.config/nvim/init.lua"

  # Claude
  mkdir -p "$HOME/.claude"
  cp "$PWD/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
)

# ASDF
export PATH="$BREW/opt/asdf/bin:$BREW/opt/asdf/shims:$PATH"

# kfilt
if ! asdf plugin list | grep -Fq "kfilt"; then
  asdf plugin add "kfilt" "https://github.com/feniix/asdf-kfilt.git"
fi
asdf plugin update "kfilt"
asdf install kfilt 1.0.0

# Ruby
if ! asdf plugin list | grep -Fq "ruby"; then
  asdf plugin add "ruby" "https://github.com/asdf-vm/asdf-ruby"
fi
asdf plugin update "ruby"
asdf install ruby 3.3.9

# Node
if ! asdf plugin list | grep -Fq "nodejs"; then
  asdf plugin add "nodejs" "https://github.com/asdf-vm/asdf-nodejs"
fi
asdf plugin update "nodejs"
asdf install nodejs 24.7.0
# Erlang
if ! asdf plugin list | grep -Fq "erlang"; then
  asdf plugin add "erlang" "https://github.com/asdf-vm/asdf-erlang"
fi
asdf plugin update "erlang"
#asdf install erlang 25.2

# Elixir
if ! asdf plugin list | grep -Fq "elixir"; then
  asdf plugin add "elixir" "https://github.com/asdf-vm/asdf-elixir"
fi
asdf plugin update "elixir"
#asdf install elixir 1.14.3

# Python
if ! asdf plugin list | grep -Fq "python"; then
  asdf plugin add "python" # "https://github.com/asdf-community/asdf-python"
fi
asdf plugin update "python"
asdf install python 3.13.7

# Vim
# if [ -e "$HOME/.vim/autoload/plug.vim" ]; then
#   vim -u "$HOME/.vimrc" +PlugUpgrade +qa
# else
#   curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
#     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# fi
# vim -u "$HOME/.vimrc" +PlugUpdate +PlugClean! +qa

# Bash
npm install -g bash-language-server

# Claude code
npm install -g @anthropic-ai/claude-code

# Neovim
LAZY_DIR="$HOME/.local/share/nvim/lazy/lazy.nvim"
if [ ! -d "$LAZY_DIR" ]; then
  git clone --filter=blob:none https://github.com/folke/lazy.nvim.git "$LAZY_DIR"
fi

nvim --headless "+Lazy! sync" +qa

# Go
go install golang.org/x/tools/cmd/godoc@latest
go install golang.org/x/tools/cmd/goimports@latest
go install golang.org/x/tools/gopls@latest

# AI via CLI
go install github.com/charmbracelet/mods@latest
