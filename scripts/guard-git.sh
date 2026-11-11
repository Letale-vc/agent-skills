#!/usr/bin/env bash
# PreToolUse hook (Bash|PowerShell): blocks git commands an agent must not run on its own
# (force push, hard reset, git clean other than a dry run, skipped hooks). Exit 2 refuses the call and shows the reason to the model.
input=$(cat)

# The command string of the tool input, still JSON-escaped (the patterns below do not depend on quotes).
cmd=$(printf '%s' "$input" | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -n 1)
[ -z "$cmd" ] && exit 0
# Line breaks separate commands; quoted strings (commit messages, echo text) are not commands.
cmd=$(printf '%s' "$cmd" | sed -E 's/\\n/;/g; s/\\"([^"\\]|\\[^"])*\\"//g'"; s/'[^']*'//g")

# One git invocation: "git" at the start of a command, its arguments up to the next command separator.
git='(:[[:space:]]*"|[;&|(][[:space:]]*)git[[:space:]]'
args='[^|;&]*'
end='([[:space:]]|$|\\|")'

matches() { printf '%s' "$cmd" | grep -qE "$1"; }

reason=""
if matches "${git}${args}push${args}(--force|[[:space:]]-[a-zA-Z]*f[a-zA-Z]*${end}|[[:space:]]\+[^[:space:]])"; then
    reason="force push"
elif matches "${git}${args}reset[[:space:]]${args}--hard"; then
    reason="git reset --hard"
elif printf '%s' "$cmd" | grep -oE "${git}${args}clean${end}${args}" | grep -vqE "[[:space:]](-[a-zA-Z]*n[a-zA-Z]*|--dry-run)${end}"; then
    # A git clean without -n / --dry-run deletes files; the dry run only lists them.
    reason="git clean"
elif matches "${git}${args}--no-verify"; then
    reason="skipping git hooks (--no-verify)"
fi

if [ -n "$reason" ]; then
    echo "Blocked by the pas plugin git guard: $reason. Destructive git commands and skipped hooks need an explicit user request; ask the user to run it themselves." >&2
    exit 2
fi
exit 0
