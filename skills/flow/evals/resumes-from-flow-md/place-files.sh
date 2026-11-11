#!/usr/bin/env bash
set -eu
cp -R "$(dirname "$0")/files/." .
# Fixtures keep .temp/ and .gitignore under other names so the repo's own .gitignore does not hide them.
if [ -d _temp ]; then mv _temp .temp; fi
if [ -f _gitignore ]; then mv _gitignore .gitignore; fi
# Commit the state before Task 1, then put Task 1's changes back uncommitted, so /pas:review has a diff to judge.
mkdir .task1
mv shop/pricing/__init__.py tests/test_pricing.py .task1/
: > shop/pricing/__init__.py
git init -q
git -c core.autocrlf=false add -A -- . ':!.task1'
git -c core.autocrlf=false -c user.name=eval -c user.email=eval@example.invalid commit -q -m "baseline before Task 1"
mv .task1/__init__.py shop/pricing/__init__.py
mv .task1/test_pricing.py tests/test_pricing.py
rmdir .task1
