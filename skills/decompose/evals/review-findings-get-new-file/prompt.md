---
tags: [decompose]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Ось знахідки /review для теми login-rate-limit, беремо обидві:

1. **[Major]** `ratelimit/limiter.py#L12` — вікно ніколи не скидається: `started` зберігається, але не перевіряється, тож заблокований ключ лишається заблокованим назавжди.
2. **[Minor]** `ratelimit/limiter.py#L9` — `hits` росте без меж: кожен новий ключ лишається в словнику назавжди.

/decompose

Input files: README.md, ratelimit/limiter.py, tests/test_limiter.py, .temp/login-rate-limit/tasks.md
