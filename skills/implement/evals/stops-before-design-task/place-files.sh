#!/usr/bin/env bash
set -eu
cp -R "$(dirname "$0")/files/." .
# Fixtures keep .temp/ and .gitignore under other names so the repo's own .gitignore does not hide them.
if [ -d _temp ]; then mv _temp .temp; fi
if [ -f _gitignore ]; then mv _gitignore .gitignore; fi
