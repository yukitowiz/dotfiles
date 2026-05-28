#!/bin/sh

set -eu

candidates='
~/.gitconfig
~/.gitignore_global
~/.editorconfig
~/.zshrc
~/.zprofile
~/.bashrc
~/.bash_profile
~/.config/git/ignore
~/.config/nvim
~/.config/ghostty
~/.config/alacritty
~/.config/wezterm
~/.config/karabiner
~/.config/Code/User/settings.json
~/.ssh/config
~/.local/bin
'

echo "Existing dotfile candidates:"
echo

for path in $candidates; do
  expanded=$(eval echo "$path")

  if [ -e "$expanded" ]; then
    if [ -d "$expanded" ]; then
      count=$(find "$expanded" -type f | wc -l | tr -d ' ')
      echo "[dir ] $path  files=$count"
    else
      size=$(wc -c < "$expanded" | tr -d ' ')
      echo "[file] $path  size=${size}B"
    fi
  else
    echo "[none] $path"
  fi
done
