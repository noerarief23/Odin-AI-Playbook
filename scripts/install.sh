#!/usr/bin/env bash
# install.sh — copy playbook files from a package into the current working directory.
#
# Usage (run from your target repo root):
#   bash /path/to/odin-ai-playbook/scripts/install.sh --package all [--force]
#
# Options:
#   --package <name>   Package profile to install (e.g. all). Required.
#   --force            Overwrite existing files without prompting.
#
# Skills (from .ai/skills/) are always installed regardless of the chosen package.
# They are sourced from the top-level .ai/skills/ folder in the playbook repo,
# which is the single source of truth — no copy is kept inside packages/.

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
# Helper: copy all files from a source directory into TARGET_DIR,
# preserving relative paths.  Honours the FORCE flag.
# ---------------------------------------------------------------------------
copy_dir() {
  local src_root="$1"
  local label="$2"
  echo "$label"
  while IFS= read -r -d '' src_file; do
    local rel_path="${src_file#$src_root/}"
    local dest_file="$TARGET_DIR/$rel_path"
    local dest_dir
    dest_dir="$(dirname "$dest_file")"

    if [[ -e "$dest_file" ]] && [[ "$FORCE" != "true" ]]; then
      echo "  SKIP (exists, use --force to overwrite): $rel_path"
      continue
    fi

    mkdir -p -- "$dest_dir"
    cp -- "$src_file" "$dest_file"
    echo "  WRITE: $rel_path"
  done < <(find "$src_root" -type f -print0)
}

# ---------------------------------------------------------------------------
# 1. Copy package-specific files (.github/, .kiro/, etc.)
# ---------------------------------------------------------------------------
copy_dir "$PACKAGE_DIR" "Installing package '$PACKAGE' into $TARGET_DIR ..."

# ---------------------------------------------------------------------------
# 2. Copy skills from the single source of truth: <playbook-root>/.ai/skills/
#    Strip relative to PLAYBOOK_ROOT so that skills land at .ai/skills/ in
#    the target, not at the root.  This avoids a redundant copy inside packages/.
# ---------------------------------------------------------------------------
SKILLS_DIR="$PLAYBOOK_ROOT/.ai/skills"
if [[ -d "$SKILLS_DIR" ]]; then
  echo "Installing skills from .ai/skills/ ..."
  while IFS= read -r -d '' src_file; do
    rel_path="${src_file#$PLAYBOOK_ROOT/}"   # keeps .ai/skills/... prefix
    dest_file="$TARGET_DIR/$rel_path"
    dest_dir="$(dirname "$dest_file")"

    if [[ -e "$dest_file" ]] && [[ "$FORCE" != "true" ]]; then
      echo "  SKIP (exists, use --force to overwrite): $rel_path"
      continue
    fi

    mkdir -p -- "$dest_dir"
    cp -- "$src_file" "$dest_file"
    echo "  WRITE: $rel_path"
  done < <(find "$SKILLS_DIR" -type f -print0)
fi

echo "Done."
