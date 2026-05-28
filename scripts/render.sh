#!/bin/sh

set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$ROOT/tests/chezmoi-ci.toml"
DEST="$(mktemp -d)"

echo "Rendering templates with test config..."
echo "Destination: $DEST"

chezmoi \
  --source="$ROOT" \
  --destination="$DEST" \
  --config="$CONFIG" \
  apply --dry-run --verbose

echo "Render check completed."
