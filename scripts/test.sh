#!/bin/sh

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/tests/chezmoi-ci.toml"
DEST="$(mktemp -d)"

echo "== chezmoi doctor =="
chezmoi doctor || true

echo "== chezmoi dry-run =="
chezmoi \
  --source="$ROOT" \
  --destination="$DEST" \
  --config="$CONFIG" \
  apply --dry-run --verbose

echo "== shellcheck =="
if command -v shellcheck >/dev/null 2>&1; then
  find "$ROOT" -type f \( -name "*.sh" -o -name "*.sh.tmpl" \) | while read -r file; do
    case "$file" in
      *.tmpl)
        echo "Rendering and checking $file"
        chezmoi \
          --source="$ROOT" \
          --destination="$DEST" \
          --config="$CONFIG" \
          execute-template < "$file" | shellcheck -
        ;;
      *)
        echo "Checking $file"
        shellcheck "$file"
        ;;
    esac
  done
else
  echo "shellcheck not found. Skipping shellcheck."
fi

echo "All tests passed."
