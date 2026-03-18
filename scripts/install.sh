#!/usr/bin/env bash
# install.sh — copy playbook files from a package into the current working directory.
#
# Usage (run from your target repo root):
#   bash /path/to/odin-ai-playbook/scripts/install.sh --package all [--force]
#
# Options:
#   --package <name>   Package profile to install (e.g. all). Required.
#   --force            Overwrite existing files without prompting.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK_ROOT="$(dirname "$SCRIPT_DIR")"

PACKAGE=""
FORCE=false

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --package)
      if [[ $# -lt 2 || "$2" == --* ]]; then
        echo "Error: --package requires a non-empty value." >&2
        echo "Usage: $0 --package <name> [--force]" >&2
        exit 1
      fi
      PACKAGE="$2"
      shift 2
      ;;
    --force)
      FORCE=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$PACKAGE" ]]; then
  echo "Error: --package is required." >&2
  echo "Usage: $0 --package <name> [--force]" >&2
  exit 1
fi

PACKAGE_DIR="$PLAYBOOK_ROOT/packages/$PACKAGE"

if [[ ! -d "$PACKAGE_DIR" ]]; then
  echo "Error: package '$PACKAGE' not found at $PACKAGE_DIR" >&2
  exit 1
fi

TARGET_DIR="$(pwd)"

# ---------------------------------------------------------------------------
# Copy files
# ---------------------------------------------------------------------------
echo "Installing package '$PACKAGE' into $TARGET_DIR ..."

while IFS= read -r -d '' src_file; do
  rel_path="${src_file#$PACKAGE_DIR/}"
  dest_file="$TARGET_DIR/$rel_path"
  dest_dir="$(dirname "$dest_file")"

  if [[ -e "$dest_file" ]] && [[ "$FORCE" != "true" ]]; then
    echo "  SKIP (exists, use --force to overwrite): $rel_path"
    continue
  fi

  mkdir -p -- "$dest_dir"
  cp -- "$src_file" "$dest_file"
  echo "  WRITE: $rel_path"
done < <(find "$PACKAGE_DIR" -type f -print0)

echo "Done."
