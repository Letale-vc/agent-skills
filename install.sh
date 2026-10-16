#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$REPO_ROOT/skills"
if [ ! -d "$SOURCE_DIR" ]; then
  SOURCE_DIR="$REPO_ROOT/.agents/skills"
fi

GLOBAL=false
SYNC_REPO=false
TARGET=""
SKILLS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--global)
      GLOBAL=true
      shift
      ;;
    --sync-repo)
      SYNC_REPO=true
      shift
      ;;
    -t|--target)
      TARGET="$2"
      shift 2
      ;;
    -s|--skill)
      SKILLS+=("$2")
      shift 2
      ;;
    *)
      TARGET="$1"
      shift
      ;;
  esac
done

if [ "$SYNC_REPO" = true ]; then
  mkdir -p "$REPO_ROOT/skills"
  cp -R "$REPO_ROOT/.agents/skills/"* "$REPO_ROOT/skills/"
  echo "Synced .agents/skills/ -> skills/"
  exit 0
fi

install_to_dir() {
  local dest="$1"
  mkdir -p "$dest"
  if [ ${#SKILLS[@]} -eq 0 ]; then
    for folder in "$SOURCE_DIR"/*/; do
      local name
      name="$(basename "$folder")"
      mkdir -p "$dest/$name"
      cp -R "$folder"* "$dest/$name/"
      echo "  [+] Installed /$name -> $dest/$name"
    done
  else
    for name in "${SKILLS[@]}"; do
      if [ -d "$SOURCE_DIR/$name" ]; then
        mkdir -p "$dest/$name"
        cp -R "$SOURCE_DIR/$name/"* "$dest/$name/"
        echo "  [+] Installed /$name -> $dest/$name"
      else
        echo "  [!] Skill '$name' not found in $SOURCE_DIR" >&2
      fi
    done
  fi
}

if [ "$GLOBAL" = true ]; then
  echo "Installing Practical Agent Skills GLOBALLY..."
  install_to_dir "$HOME/.gemini/config/skills"
  install_to_dir "$HOME/.agents/skills"
  echo "Global installation complete!"
  exit 0
fi

if [ -z "$TARGET" ]; then
  echo "Usage:"
  echo "  Global install:  ./install.sh --global"
  echo "  Project install: ./install.sh --target /path/to/project"
  echo "  Single skill:    ./install.sh --target /path/to/project --skill interview"
  echo "  Sync repo:       ./install.sh --sync-repo"
  exit 1
fi

mkdir -p "$TARGET"
TARGET_ROOT="$(cd "$TARGET" && pwd)"
echo "Installing Practical Agent Skills into project: $TARGET_ROOT"
install_to_dir "$TARGET_ROOT/.agents/skills"

GITIGNORE="$TARGET_ROOT/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -qxF ".temp/" "$GITIGNORE" && ! grep -qxF ".temp" "$GITIGNORE"; then
    printf "\n.temp/\n" >> "$GITIGNORE"
    echo "  [+] Added .temp/ to $GITIGNORE"
  fi
else
  printf ".temp/\n" > "$GITIGNORE"
  echo "  [+] Created $GITIGNORE with .temp/"
fi

echo "Project installation complete!"

