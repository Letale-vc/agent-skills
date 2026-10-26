#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$REPO_ROOT/skills"
if [ ! -d "$SOURCE_DIR" ]; then
  SOURCE_DIR="$REPO_ROOT/.agents/skills"
fi
MANIFEST_NAME=".practical-agent-skills.manifest"

GLOBAL=false
SYNC_REPO=false
ALL=false
FORCE=false
PRUNE=false
CLAUDE=false
TARGET=""
SKILLS=()

usage() {
  echo "Usage:"
  echo "  Update everywhere: ./install.sh --all [--force] [--prune]"
  echo "  Global install:    ./install.sh --global [--force] [--prune]"
  echo "  Project install:   ./install.sh --target /path/to/project [--force] [--prune]"
  echo "  Single skill:      ./install.sh --target /path/to/project --skill interview"
  echo "  Claude Code:       ./install.sh --global --claude  |  ./install.sh --target /path/to/project --claude"
  echo "  Sync repo:         ./install.sh --sync-repo"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--all)
      ALL=true
      shift
      ;;
    -g|--global)
      GLOBAL=true
      shift
      ;;
    --sync-repo)
      SYNC_REPO=true
      shift
      ;;
    -c|--claude)
      CLAUDE=true
      shift
      ;;
    -f|--force)
      FORCE=true
      shift
      ;;
    -p|--prune)
      PRUNE=true
      shift
      ;;
    -t|--target)
      if [[ $# -lt 2 || "$2" == -* ]]; then
        echo "Error: $1 requires a directory path argument." >&2
        usage >&2
        exit 1
      fi
      TARGET="$2"
      shift 2
      ;;
    -s|--skill)
      if [[ $# -lt 2 || "$2" == -* ]]; then
        echo "Error: $1 requires a skill name argument." >&2
        usage >&2
        exit 1
      fi
      SKILLS+=("$2")
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: Unknown option '$1'" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [ -z "$TARGET" ]; then
        TARGET="$1"
        shift
      else
        echo "Error: Unexpected positional argument '$1' (target already set to '$TARGET')." >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

sync_repo_link() {
  echo "Linking .agents/skills -> skills/ via symlink..."
  mkdir -p "$REPO_ROOT/.agents"
  rm -rf "$REPO_ROOT/.agents/skills"
  ln -s "$REPO_ROOT/skills" "$REPO_ROOT/.agents/skills"
  echo "  [+] .agents/skills -> skills/ (canonical source of truth)"
  if [ -d "$REPO_ROOT/.githooks" ]; then
    git config core.hooksPath .githooks
    echo "  [+] Git hooks configured: core.hooksPath -> .githooks"
  fi
}

if [ "$SYNC_REPO" = true ]; then
  sync_repo_link
  exit 0
fi

sha256_str() {
  if command -v sha256sum >/dev/null 2>&1; then
    printf "%s" "$1" | sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    printf "%s" "$1" | shasum -a 256 | awk '{print $1}'
  else
    openssl dgst -sha256 | awk '{print $NF}'
  fi
}

get_skill_hash() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    echo ""
    return
  fi
  local base
  base="$(cd "$dir" && pwd)"
  local lines=()
  while IFS= read -r -d '' file; do
    local rel="${file#"$base"/}"
    local content_hash
    if command -v sha256sum >/dev/null 2>&1; then
      content_hash="$(tr -d '\r' < "$file" | sha256sum | awk '{print $1}')"
    elif command -v shasum >/dev/null 2>&1; then
      content_hash="$(tr -d '\r' < "$file" | shasum -a 256 | awk '{print $1}')"
    else
      content_hash="$(tr -d '\r' < "$file" | openssl dgst -sha256 | awk '{print $NF}')"
    fi
    lines+=("${rel}=${content_hash}")
  # evals/ holds skill tests; it is never installed, so it never counts toward the hash.
  done < <(find "$base" -path "$base/evals" -prune -o -type f -print0)

  if [ ${#lines[@]} -eq 0 ]; then
    echo ""
    return
  fi
  local sorted
  sorted="$(printf "%s\n" "${lines[@]}" | LC_ALL=C sort)"
  sha256_str "$sorted"
}

install_to_dir() {
  local dest="$1"
  mkdir -p "$dest"
  local manifest_path="$dest/$MANIFEST_NAME"
  declare -A manifest=()
  if [ -f "$manifest_path" ]; then
    while IFS=' ' read -r k v || [ -n "${k:-}" ]; do
      [[ -z "${k:-}" || "$k" == \#* ]] && continue
      manifest["$k"]="$v"
    done < "$manifest_path"
  fi

  local all_source_names=()
  for folder in "$SOURCE_DIR"/*/; do
    [ -d "$folder" ] || continue
    all_source_names+=("$(basename "$folder")")
  done

  local target_names=()
  if [ ${#SKILLS[@]} -eq 0 ]; then
    target_names=("${all_source_names[@]}")
  else
    target_names=("${SKILLS[@]}")
  fi

  for name in "${target_names[@]}"; do
    local src_folder="$SOURCE_DIR/$name"
    if [ ! -d "$src_folder" ]; then
      echo "  [!] Skill '$name' not found in $SOURCE_DIR" >&2
      continue
    fi
    local dest_folder="$dest/$name"
    local src_hash
    src_hash="$(get_skill_hash "$src_folder")"
    local dest_hash
    dest_hash="$(get_skill_hash "$dest_folder")"
    local recorded_hash="${manifest[$name]:-}"

    if [ -n "$dest_hash" ] && [ "$dest_hash" = "$src_hash" ]; then
      manifest["$name"]="$src_hash"
      echo "  [=] /$name already up to date"
      continue
    fi
    if [ -n "$dest_hash" ] && [ -n "$recorded_hash" ] && [ "$dest_hash" != "$recorded_hash" ] && [ "$FORCE" = false ]; then
      echo "  [!] SKIPPED /$name: locally modified in $dest_folder (use --force to overwrite)"
      continue
    fi

    rm -rf "$dest_folder"
    mkdir -p "$dest_folder"
    find "$src_folder" -mindepth 1 -maxdepth 1 ! -name evals -exec cp -R {} "$dest_folder/" \;
    manifest["$name"]="$src_hash"
    echo "  [+] Installed /$name -> $dest_folder"
  done

  for recorded_name in "${!manifest[@]}"; do
    local found=false
    for sname in "${all_source_names[@]}"; do
      if [ "$sname" = "$recorded_name" ]; then
        found=true
        break
      fi
    done
    if [ "$found" = false ]; then
      if [ "$PRUNE" = true ]; then
        rm -rf "$dest/$recorded_name"
        unset 'manifest[$recorded_name]'
        echo "  [-] Pruned stale skill /$recorded_name"
      else
        echo "  [!] Stale skill /$recorded_name no longer exists in this repo (use --prune to delete)"
      fi
    fi
  done

  {
    echo "# Managed by Practical Agent Skills installer. Do not edit."
    for k in $(printf "%s\n" "${!manifest[@]}" | LC_ALL=C sort); do
      echo "$k ${manifest[$k]}"
    done
  } > "$manifest_path"
}

install_global() {
  if [ "$CLAUDE" = true ]; then
    echo "Installing Practical Agent Skills GLOBALLY for Claude Code..."
    install_to_dir "$HOME/.claude/skills"
    return
  fi
  echo "Installing Practical Agent Skills GLOBALLY..."
  install_to_dir "$HOME/.gemini/config/skills"
  install_to_dir "$HOME/.agents/skills"
}

if [ "$ALL" = true ]; then
  sync_repo_link
  install_global
  # Claude Code: update the global dir only if it already exists (--claude forces it, handled above).
  if [ "$CLAUDE" = false ] && [ -d "$HOME/.claude/skills" ]; then
    echo ""
    echo "Updating Claude Code global skills..."
    install_to_dir "$HOME/.claude/skills"
  fi
  PARENT_DIR="$(dirname "$REPO_ROOT")"
  if [ -n "$PARENT_DIR" ] && [ -d "$PARENT_DIR" ]; then
    for proj in "$PARENT_DIR"/*/; do
      [ -d "$proj" ] || continue
      proj_clean="$(cd "$proj" && pwd)"
      [ "$proj_clean" != "$REPO_ROOT" ] || continue
      for rel in .agents/skills .claude/skills; do
        if [ -d "$proj_clean/$rel" ]; then
          echo ""
          echo "Updating project: $proj_clean/$rel..."
          install_to_dir "$proj_clean/$rel"
        fi
      done
    done
  fi
  echo ""
  echo "All global and project skills updated!"
  exit 0
fi

if [ "$GLOBAL" = true ]; then
  install_global
  echo "Global installation complete!"
  exit 0
fi

if [ -z "$TARGET" ]; then
  usage
  exit 1
fi

mkdir -p "$TARGET"
TARGET_ROOT="$(cd "$TARGET" && pwd)"
echo "Installing Practical Agent Skills into project: $TARGET_ROOT"
if [ "$CLAUDE" = true ]; then
  install_to_dir "$TARGET_ROOT/.claude/skills"
else
  install_to_dir "$TARGET_ROOT/.agents/skills"
fi

GITIGNORE="$TARGET_ROOT/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! tr -d '\r' < "$GITIGNORE" | grep -qxE '[[:space:]]*/?\.temp/?[[:space:]]*'; then
    printf "\n.temp/\n" >> "$GITIGNORE"
    echo "  [+] Added .temp/ to $GITIGNORE"
  fi
else
  printf ".temp/\n" > "$GITIGNORE"
  echo "  [+] Created $GITIGNORE with .temp/"
fi

echo "Project installation complete!"
