---
tags: [architect]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

/architect хочу винести src/utils в окрему бібліотеку, опублікувати її в npm і зробити там систему плагінів для форматів дат, щоб було гнучко на майбутнє. Як це краще структурувати?

Input files: README.md, package.json, src/cli.js, src/utils/slug.js, src/utils/dates.js
