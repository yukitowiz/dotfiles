#!/bin/sh

set -eu

if command -v chezmoi >/dev/null 2>&1; then
  echo "chezmoi is already installed: $(chezmoi --version)"
  exit 0
fi

OS="$(uname -s)"

case "$OS" in
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      brew install chezmoi
    else
      sh -c "$(curl -fsLS get.chezmoi.io)"
    fi
    ;;
  Linux)
    sh -c "$(curl -fsLS get.chezmoi.io)"
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac
