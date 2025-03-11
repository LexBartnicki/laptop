#!/bin/bash

# ./laptop.sh

# - installs system packages with Homebrew package manager
# - changes shell to Z shell (zsh)
# - creates symlinks for dotfiles to `$HOME`
# - installs programming language runtimes
# - installs or updates Vim plugins

# This script can be safely run multiple times.

set -eux

# Homebrew
BREW="/opt/homebrew"

if [ ! -d "$BREW" ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

export PATH="$BREW/bin:$PATH"

brew analytics off
brew update-reset
brew bundle --no-lock --file=- <<EOF
brew "asdf"
brew "awscli"
brew "bat"
brew "fd"
brew "fzf"
brew "gh"
brew "git"
brew "jq"
brew "libyaml"
brew "openssl@3"
brew "pgformatter"
brew "readline"
brew "shellcheck"
brew "the_silver_searcher"
brew "tldr"
brew "tree"
brew "uv"
brew "vim"
brew "watch"
brew "yazi"
brew "zellij"
brew "zsh"

cask "docker"
cask "ngrok"
cask "ollama"
cask "pgadmin4"
cask "warp"
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

  ln -sf "$PWD/vim/vimrc" "$HOME/.vimrc"

  mkdir -p "$HOME/.vim/ftdetect"
  mkdir -p "$HOME/.vim/ftplugin"
  mkdir -p "$HOME/.vim/syntax"
  (
    cd vim
    ln -sf "$PWD/coc-settings.json" "$HOME/.vim/coc-settings.json"
    for f in {ftdetect,ftplugin,syntax}/*; do
      ln -sf "$PWD/$f" "$HOME/.vim/$f"
    done
  )

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
)

# ASDF
export PATH="$BREW/opt/asdf/bin:$BREW/opt/asdf/shims:$PATH"

# Ruby
if ! asdf plugin-list | grep -Fq "ruby"; then
  asdf plugin-add "ruby" "https://github.com/asdf-vm/asdf-ruby"
fi
asdf plugin-update "ruby"
asdf install ruby 3.3.1

# Node
if ! asdf plugin-list | grep -Fq "nodejs"; then
  asdf plugin-add "nodejs" "https://github.com/asdf-vm/asdf-nodejs"
fi
asdf plugin-update "nodejs"
asdf install nodejs 16.13.2

# Erlang
if ! asdf plugin-list | grep -Fq "erlang"; then
  asdf plugin-add "erlang" "https://github.com/asdf-vm/asdf-erlang"
fi
asdf plugin-update "erlang"
asdf install erlang 25.2

# Elixir
if ! asdf plugin-list | grep -Fq "elixir"; then
  asdf plugin-add "elixir" "https://github.com/asdf-vm/asdf-elixir"
fi
asdf plugin-update "elixir"
asdf install elixir 1.14.3

# Python
uv python install 3.12.2

# Vim
if [ -e "$HOME/.vim/autoload/plug.vim" ]; then
  vim -u "$HOME/.vimrc" +PlugUpgrade +qa
else
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
vim -u "$HOME/.vimrc" +PlugUpdate +PlugClean! +qa

# Rust
if ! command -v rustup &> /dev/null; then
  curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
  source "$HOME"/.cargo/env
fi

if ! command -v rustfmt &> /dev/null; then
  rustup component add rustfmt
fi
