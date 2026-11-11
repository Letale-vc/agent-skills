#!/usr/bin/env bash
# SessionStart hook (startup, clear, compact): lists unfinished work in .temp/<topic>/ so an empty
# context knows where to resume. Prints nothing when every topic is done. Read-only; always exits 0.

# UTF-8 so that truncating a non-ASCII "Next" line cuts whole characters, not bytes.
export LC_ALL=C.UTF-8 2>/dev/null

root="${CLAUDE_PROJECT_DIR:-$PWD}"
temp="$root/.temp"
[ -d "$temp" ] || exit 0

# Value of a "- **Key**: value" line in a flow.md, without CR and trailing spaces.
field() {
    grep -m 1 -E "^- \*\*$1\*\*:" "$2" 2>/dev/null |
        sed -E "s/^- \*\*$1\*\*:[[:space:]]*//; s/\r\$//; s/[[:space:]]+\$//"
}

lines=()
# Topic folders, newest first.
while IFS= read -r dir; do
    dir="${dir%/}"
    [ -d "$dir" ] || continue

    stage=""
    next=""
    if [ -f "$dir/flow.md" ]; then
        stage=$(field Stage "$dir/flow.md")
        next=$(field Next "$dir/flow.md")
        [ "${#next}" -gt 200 ] && next="${next:0:200}..."
    fi

    open=""
    for file in "$dir"/*.md; do
        [ -f "$file" ] || continue
        count=$(grep -cE '^[[:space:]]*- \[ \]' "$file" 2>/dev/null)
        [ "${count:-0}" -gt 0 ] && open="${open:+$open, }$(basename "$file"): $count open"
    done

    flow_open=""
    stage_lower=$(printf '%s' "$stage" | tr '[:upper:]' '[:lower:]')
    [ -n "$stage" ] && [ "$stage_lower" != "done" ] && flow_open=1
    [ -z "$flow_open" ] && [ -z "$open" ] && continue

    parts=""
    [ -n "$stage" ] && parts="flow stage: $stage"
    [ -n "$open" ] && parts="${parts:+$parts; }$open"
    line="- .temp/$(basename "$dir")/ — $parts"
    [ -n "$flow_open" ] && [ -n "$next" ] && line="$line
  next: $next"
    lines+=("$line")
done < <(ls -1td "$temp"/*/ 2>/dev/null)

[ "${#lines[@]}" -eq 0 ] && exit 0

echo "Unfinished work in .temp/ (newest first). Resume a flow with /pas:flow <topic>, a task file with /pas:implement <topic>; ask the user before picking one up:"
shown=0
for line in "${lines[@]}"; do
    [ "$shown" -ge 5 ] && break
    printf '%s\n' "$line"
    shown=$((shown + 1))
done
[ "${#lines[@]}" -gt "$shown" ] && echo "- ... and $((${#lines[@]} - shown)) more"
exit 0
