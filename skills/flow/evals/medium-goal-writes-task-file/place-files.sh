#!/usr/bin/env bash
set -eu
cp -R "$(dirname "$0")/files/." .
# Fixtures keep .gitignore under another name so the repo's own .gitignore does not hide it.
if [ -f _gitignore ]; then mv _gitignore .gitignore; fi
# A committed baseline, so the run's own changes show up as the diff.
git init -q
git -c core.autocrlf=false add -A
git -c core.autocrlf=false -c user.name=eval -c user.email=eval@example.invalid commit -q -m baseline
