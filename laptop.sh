#!/bin/bash

# ./laptop.sh [--languages lang1,lang2,...] [--no-brew]
#
# - installs system packages with Homebrew package manager
# - changes shell to Z shell (zsh)
# - creates symlinks for dotfiles to `$HOME`
# - installs programming language runtimes via asdf
# - installs or updates Neovim plugins
#
# This script can be safely run multiple times.
#
# Options:
#   --languages   Comma-separated list of languages to install (overrides languages.local)
#                 Available: dotnet, elixir, erlang, kfilt, nodejs, python, ruby
#   --no-brew     Skip Homebrew install/update (for users sharing a machine where
#                 another user owns Homebrew)

set -eux

# Parse arguments
LANGUAGES_OVERRIDE=""
SKIP_BREW=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --languages)
      LANGUAGES_OVERRIDE="$2"
      shift 2
      ;;
    --no-brew)
      SKIP_BREW=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create local configs if they don't exist
touch "$LAPTOP"/shell/zshrc.local
if [ ! -f "$LAPTOP/frameworks.local" ]; then
  cat > "$LAPTOP/frameworks.local" << 'EOF'
# Frameworks to install (one per line)
# Available: monogame
EOF
fi

if [ ! -f "$LAPTOP/languages.local" ]; then
  cat > "$LAPTOP/languages.local" << 'EOF'
# Languages to install via asdf
# One per line. Versions come from asdf/tool-versions
# Available: dotnet, elixir, erlang, kfilt, nodejs, python, ruby

nodejs
python
ruby
EOF
fi

# Homebrew
BREW="/opt/homebrew"

if [ "$SKIP_BREW" = false ]; then
  if [ ! -d "$BREW" ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  brew analytics off
  brew update-reset
  brew bundle --file="$LAPTOP/Brewfile"

  brew upgrade
  brew autoremove
  brew cleanup
fi

export PATH="$BREW/bin:$PATH"

# zsh
update_shell() {
  if [ "$SKIP_BREW" = false ]; then
    sudo chown -R "$(whoami)" "$BREW/share/zsh" "$BREW/share/zsh/site-functions"
    chmod u+w "$BREW/share/zsh" "$BREW/share/zsh/site-functions"
  fi

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
  ln -sf "$PWD/ruby/default-gems" "$HOME/.default-gems"
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

  mkdir -p "$HOME/.config/ghostty"
  ln -sf "$PWD/term/ghostty" "$HOME/.config/ghostty/config"
  mkdir -p "$HOME/.config/zellij"
  ln -sf "$PWD/term/zellij.kdl" "$HOME/.config/zellij/config.kdl"

  # Vim
  # mkdir -p "$HOME/.config/nvim"
  # ln -sf "$PWD/vim/init.lua" "$HOME/.config/nvim/init.lua"

  # Claude
  mkdir -p "$HOME/.claude"
  cp "$PWD/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
)

# ASDF
export PATH="$BREW/opt/asdf/bin:$BREW/opt/asdf/shims:$PATH"

# Determine which languages to install
if [ -n "$LANGUAGES_OVERRIDE" ]; then
  # Use CLI argument (comma-separated)
  LANGUAGES=$(echo "$LANGUAGES_OVERRIDE" | tr ',' '\n')
else
  # Read from languages.local
  LANGUAGES=$(grep -v '^#' "$LAPTOP/languages.local" | grep -v '^$')
fi

# Install each language
install_language() {
  local name="$1"

  # Look up plugin info from languages.conf
  local line
  line=$(grep "^${name}|" "$LAPTOP/languages.conf" || true)

  if [ -z "$line" ]; then
    echo "Unknown language: $name (not in languages.conf)"
    return 1
  fi

  local plugin_name plugin_url
  plugin_name=$(echo "$line" | cut -d'|' -f2)
  plugin_url=$(echo "$line" | cut -d'|' -f3)

  # Get version from tool-versions
  local version
  version=$(grep "^${plugin_name} " "$LAPTOP/asdf/tool-versions" | awk '{print $2}' || true)

  if [ -z "$version" ]; then
    echo "No version found for $plugin_name in asdf/tool-versions"
    return 1
  fi

  echo "Installing $name ($plugin_name $version)..."

  # Add plugin if not present
  if ! asdf plugin list | grep -Fq "$plugin_name"; then
    if [ -n "$plugin_url" ]; then
      asdf plugin add "$plugin_name" "$plugin_url"
    else
      asdf plugin add "$plugin_name"
    fi
  fi

  asdf plugin update "$plugin_name"
  asdf install "$plugin_name" "$version"
}

for lang in $LANGUAGES; do
  install_language "$lang"
done

# Vim
if [ -e "$HOME/.vim/autoload/plug.vim" ]; then
  vim -u "$HOME/.vimrc" +PlugUpgrade +qa
else
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
vim -u "$HOME/.vimrc" +PlugUpdate +PlugClean! +qa

if [ "$SKIP_BREW" = false ]; then
  # Bash
  npm install -g bash-language-server

  # Claude code
  npm install -g @anthropic-ai/claude-code
fi

# Neovim
# LAZY_DIR="$HOME/.local/share/nvim/lazy/lazy.nvim"
# if [ ! -d "$LAZY_DIR" ]; then
#   git clone --filter=blob:none https://github.com/folke/lazy.nvim.git "$LAZY_DIR"
# fi

# nvim --headless "+Lazy! sync" +qa

# Go
go install golang.org/x/tools/cmd/godoc@latest
go install golang.org/x/tools/cmd/goimports@latest
go install golang.org/x/tools/gopls@latest

# AI via CLI
go install github.com/charmbracelet/mods@latest

# Frameworks
FRAMEWORKS=$(grep -v '^#' "$LAPTOP/frameworks.local" | grep -v '^$')
for framework in $FRAMEWORKS; do
  "$LAPTOP/frameworks/setup_$framework"
done
