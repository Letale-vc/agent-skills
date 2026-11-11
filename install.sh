#!/usr/bin/env bash
# Installs Practical Agent Skills for Codex, Antigravity and other agents that read .agents/skills.
# Claude Code uses the pas plugin instead; --claude prints the plugin commands and copies nothing.
#
# Skills link to ${CLAUDE_PLUGIN_ROOT}/shared/... and ${CLAUDE_PLUGIN_ROOT}/agents/...; the installer
# copies shared/ and agents/ to <skills-dir>/../pas/ and rewrites the placeholder in copied files:
# .agents/pas (relative to the project root) for a project, the absolute path for a global install.
# The manifest (.practical-agent-skills.manifest) and its hashes are shared with install.ps1.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$REPO_ROOT/skills"
if [ ! -d "$SOURCE_DIR" ]; then
  SOURCE_DIR="$REPO_ROOT/.agents/skills"
fi
MANIFEST_NAME=".practical-agent-skills.manifest"
PLACEHOLDER_RE='\${CLAUDE_PLUGIN_ROOT}'
SUPPORT_DIRS=(shared agents)
SUPPORT_FOLDER="pas"
PROJECT_PLUGIN_ROOT=".agents/$SUPPORT_FOLDER"
# Skills removed in 2.0 (merged into flow, shape, audit and git). Without a manifest entry they are only reported.
RETIRED_SKILLS=(using-agent-skills idea interview architect cleanup)

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
  echo "  Single skill:      ./install.sh --target /path/to/project --skill flow --skill implement"
  echo "  Claude Code:       ./install.sh --claude [--global | --target /path/to/project] [--prune]  (prints the plugin commands)"
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

sha256_stdin() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    openssl dgst -sha256 | awk '{print $NF}'
  fi
}

# Rewrites the placeholder on stdin to $1; an empty root passes the text through.
rewrite_root() {
  local root="$1"
  if [ -z "$root" ]; then
    cat
    return
  fi
  local escaped
  escaped="$(printf '%s' "$root" | sed 's/[&|\\]/\\&/g')"
  sed "s|$PLACEHOLDER_RE|$escaped|g"
}

# Hash of a skill as installed: CR stripped (must match install.ps1), placeholder rewritten to $2.
# An installed copy has no placeholder left, so the same call hashes source and destination alike.
get_skill_hash() {
  local dir="$1" root="${2:-}"
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
    content_hash="$(tr -d '\r' < "$file" | rewrite_root "$root" | sha256_stdin)"
    lines+=("${rel}=${content_hash}")
  # evals/ holds skill tests; it is never installed, so it never counts toward the hash.
  done < <(find "$base" -path "$base/evals" -prune -o -type f -print0)

  if [ ${#lines[@]} -eq 0 ]; then
    echo ""
    return
  fi
  printf "%s" "$(printf "%s\n" "${lines[@]}" | LC_ALL=C sort)" | sha256_stdin
}

# Copies a folder (without evals/) and rewrites the placeholder in every file that contains it.
copy_with_root() {
  local src="$1" dest="$2" root="$3"
  rm -rf "$dest"
  mkdir -p "$dest"
  find "$src" -mindepth 1 -maxdepth 1 ! -name evals -exec cp -R {} "$dest/" \;
  while IFS= read -r -d '' file; do
    if grep -q "$PLACEHOLDER_RE" "$file"; then
      rewrite_root "$root" < "$file" > "$file.pas-tmp"
      mv "$file.pas-tmp" "$file"
    fi
  done < <(find "$dest" -type f -print0)
}

read_manifest() {
  local path="$1"
  if [ -f "$path" ]; then
    while IFS=' ' read -r k v || [ -n "${k:-}" ]; do
      [[ -z "${k:-}" || "$k" == \#* ]] && continue
      manifest["$k"]="$v"
    done < "$path"
  fi
}

write_manifest() {
  local path="$1"
  {
    echo "# Managed by Practical Agent Skills installer. Do not edit."
    for k in $(printf "%s\n" "${!manifest[@]}" | LC_ALL=C sort); do
      echo "$k ${manifest[$k]}"
    done
  } > "$path"
}

install_to_dir() {
  local dest="$1" root="$2"
  mkdir -p "$dest"
  local manifest_path="$dest/$MANIFEST_NAME"
  declare -A manifest=()
  read_manifest "$manifest_path"

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
    local src_hash dest_hash
    src_hash="$(get_skill_hash "$src_folder" "$root")"
    dest_hash="$(get_skill_hash "$dest_folder" "$root")"
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

    copy_with_root "$src_folder" "$dest_folder" "$root"
    manifest["$name"]="$src_hash"
    echo "  [+] Installed /$name -> $dest_folder"
  done

  # Shared rules and agent definitions the skills link to.
  local support_root
  support_root="$(dirname "$dest")/$SUPPORT_FOLDER"
  for sdir in "${SUPPORT_DIRS[@]}"; do
    copy_with_root "$REPO_ROOT/$sdir" "$support_root/$sdir" "$root"
  done
  echo "  [+] Installed shared/, agents/ -> $support_root (links rewritten to $root)"

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
        rm -rf "${dest:?}/$recorded_name"
        unset 'manifest[$recorded_name]'
        echo "  [-] Pruned stale skill /$recorded_name"
      else
        echo "  [!] Stale skill /$recorded_name no longer exists in this repo (use --prune to delete)"
      fi
    fi
  done
  for retired in "${RETIRED_SKILLS[@]}"; do
    if [ -z "${manifest[$retired]:-}" ] && [ -d "$dest/$retired" ]; then
      echo "  [!] /$retired was retired in 2.0 but was not installed by this script; delete it by hand if it is an old copy"
    fi
  done

  write_manifest "$manifest_path"
}

show_claude_plugin_hint() {
  echo "Claude Code uses the pas plugin; nothing is copied into .claude/skills. Run once:"
  echo "  claude plugin marketplace add Letale-vc/agent-skills    # or a local clone: claude plugin marketplace add \"$REPO_ROOT\""
  echo "  claude plugin install pas@letale-skills                 # add --scope project to enable it in .claude/settings.json"
}

# Skills an older installer copied into a Claude Code skills folder: the plugin replaces them.
remove_old_claude_copies() {
  local dir="$1"
  local manifest_path="$dir/$MANIFEST_NAME"
  [ -f "$manifest_path" ] || return 0
  declare -A manifest=()
  read_manifest "$manifest_path"
  [ ${#manifest[@]} -gt 0 ] || return 0
  if [ "$PRUNE" = false ]; then
    echo "  [!] $dir holds ${#manifest[@]} skills copied by an older installer; the plugin replaces them (use --prune to delete)"
    return 0
  fi
  for name in "${!manifest[@]}"; do
    local hash
    hash="$(get_skill_hash "$dir/$name")"
    if [ -n "$hash" ] && [ "$hash" != "${manifest[$name]}" ] && [ "$FORCE" = false ]; then
      echo "  [!] SKIPPED /$name: locally modified in $dir/$name (use --force to delete)"
      continue
    fi
    rm -rf "${dir:?}/$name"
    unset 'manifest[$name]'
    echo "  [-] Removed old copy /$name from $dir"
  done
  if [ ${#manifest[@]} -eq 0 ]; then
    rm -f "$manifest_path"
  else
    write_manifest "$manifest_path"
  fi
}

# Absolute path of <skills-dir>/../pas; a Windows path with forward slashes under Git Bash.
absolute_plugin_root() {
  local root
  root="$(dirname "$1")/$SUPPORT_FOLDER"
  if command -v cygpath >/dev/null 2>&1; then
    root="$(cygpath -m "$root")"
  fi
  printf '%s' "$root"
}

install_global() {
  echo "Installing Practical Agent Skills GLOBALLY..."
  local dir
  for dir in "$HOME/.gemini/config/skills" "$HOME/.agents/skills"; do
    install_to_dir "$dir" "$(absolute_plugin_root "$dir")"
  done
}

if [ "$ALL" = true ]; then
  sync_repo_link
  install_global
  remove_old_claude_copies "$HOME/.claude/skills"
  PARENT_DIR="$(dirname "$REPO_ROOT")"
  if [ -n "$PARENT_DIR" ] && [ -d "$PARENT_DIR" ]; then
    for proj in "$PARENT_DIR"/*/; do
      [ -d "$proj" ] || continue
      proj_clean="$(cd "$proj" && pwd)"
      [ "$proj_clean" != "$REPO_ROOT" ] || continue
      if [ -d "$proj_clean/.agents/skills" ]; then
        echo ""
        echo "Updating project: $proj_clean/.agents/skills..."
        install_to_dir "$proj_clean/.agents/skills" "$PROJECT_PLUGIN_ROOT"
      fi
      if [ -d "$proj_clean/.claude/skills" ]; then
        remove_old_claude_copies "$proj_clean/.claude/skills"
      fi
    done
  fi
  echo ""
  show_claude_plugin_hint
  echo ""
  echo "All global and project skills updated!"
  exit 0
fi

if [ "$CLAUDE" = true ]; then
  if [ "$GLOBAL" = true ]; then
    remove_old_claude_copies "$HOME/.claude/skills"
  elif [ -n "$TARGET" ] && [ -d "$TARGET" ]; then
    remove_old_claude_copies "$(cd "$TARGET" && pwd)/.claude/skills"
  fi
  show_claude_plugin_hint
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
install_to_dir "$TARGET_ROOT/.agents/skills" "$PROJECT_PLUGIN_ROOT"

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
