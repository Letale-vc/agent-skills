# Practical Agent Skills

Плагін Claude Code **`pas`** з інженерним ланцюжком для AI-агентів: агент сам обирає маршрут за розміром задачі, код пишуть субагенти за TDD, чернетки живуть лише в `.temp/<topic>/`, нормативні специфікації — у `docs/specifications/`. Безпечні кроки агент робить сам (з одним рядком «→ Next: …»), а питає лише на воротах: коміт чи видалення, рішення дизайну, знахідки рев'ю, ручні перевірки, збій, який не вдалося виправити.

Для Codex, Antigravity та інших агентів той самий вміст ставлять скрипти `install.ps1` / `install.sh`.

---

## Встановлення в Claude Code

```bash
# 1. Додати marketplace letale-skills (з GitHub або з локального клону)
claude plugin marketplace add Letale-vc/agent-skills
claude plugin marketplace add D:/practik/agent-skills

# 2. Встановити плагін (для себе; --scope project записує його в .claude/settings.json проєкту)
claude plugin install pas@letale-skills
claude plugin install pas@letale-skills --scope project

# Оновлення
claude plugin marketplace update letale-skills
claude plugin update pas@letale-skills
```

Щоб плагін вмикався для всіх, хто відкриває проєкт, закомітьте в `.claude/settings.json` проєкту:

```json
{
  "extraKnownMarketplaces": {
    "letale-skills": {
      "source": { "source": "github", "repo": "Letale-vc/agent-skills" }
    }
  },
  "enabledPlugins": {
    "pas@letale-skills": true
  }
}
```

* Для локального клону замість `github` — `"source": { "source": "directory", "path": "D:/practik/agent-skills" }`.
* `extraKnownMarketplaces` з проєктного файлу діє лише після того, як користувач довірить папку (workspace trust); `enabledPlugins` вмикає плагін, але кожен користувач один раз встановлює його сам.
* Проєктні `.claude/agents/` з тими самими іменами (`implementer`, `reviewer`, …) затіняють агентів плагіна, а старі копії скілів у `.claude/skills/` дублюють його: видаліть їх (`.\install.ps1 -Target <проєкт> -Claude -Prune` прибирає те, що туди колись скопіював інсталятор).
* Розробка самого плагіна: `claude --plugin-dir D:/practik/agent-skills` вантажить його на одну сесію; `claude plugin validate . --strict` перевіряє маніфести.

Скіли викликаються як `/pas:<name>`, агенти мають імена `pas:<name>`.

---

## Маршрути за розміром

Один вхід — **`/pas:flow <ціль>`**: він оголошує маршрут одним рядком і веде роботу до воріт. Без аргументу `/pas:flow` показує, де зупинилась робота, і називає наступний крок; `/pas:flow <topic>` продовжує прогін із `.temp/<topic>/flow.md` у новій сесії.

| Розмір | Коли | Маршрут |
| --- | --- | --- |
| **Малий** | одна-дві задачі, баг | задача в промпті → `pas:implementer` (або `/pas:debug`) → повна перевірка → `/pas:git`; без `.temp/` і без рев'ю |
| **Середній** | до ~5 задач у наявних модулях, без нового публічного контракту, проєкту чи шару | головна сесія пише `.temp/<topic>/tasks.md` → батч `pas:implementer` → повна перевірка (full check) → один `pas:reviewer` → `/pas:spec` (якщо змінилась специфікована поведінка) → `/pas:git` |
| **Великий** | новий контракт, проєкт чи шар, робота між шарами, понад ~5 задач | `/pas:shape` (якщо ціль неясна) → `/pas:proposal` (2–3 `pas:architect` паралельно, вибір варіанту) → `pas:decomposer` → батчі `pas:implementer` → повна перевірка (full check) → два `pas:reviewer` паралельно → `pas:spec-writer` → `/pas:git` |

Модель і effort `implementer` задає оцінка складності задачі (D/V/S, [`shared/complexity.md`](shared/complexity.md)); проєкт може перевизначити відображення у своєму `CLAUDE.md`. Команди збірки, тестів і повної перевірки (full check) агенти беруть з `CLAUDE.md` / `AGENTS.md` проєкту.

---

## Скіли

| Скіл | Режим | Призначення |
| --- | --- | --- |
| [`/pas:flow`](skills/flow/SKILL.md) | conductor | Статус і наступний крок; вибір маршруту; веде етапи через агентів, стан у `.temp/<topic>/flow.md`, продовження з нової сесії. |
| [`/pas:shape`](skills/shape/SKILL.md) | read-only | Сира ідея чи нечіткий запит → 2–3 напрямки з рекомендацією, до 5 питань по одному з гіпотезою, блок наміру (мета, критерії успіху, межі). |
| [`/pas:proposal`](skills/proposal/SKILL.md) | writes `.temp/` | Дизайн великої задачі в `proposal.md`: мета й критерії, конфлікти з кодом і специфікаціями, де живе новий код, 2–3 варіанти від `pas:architect`, таблиця порівняння, вибір користувача. |
| [`/pas:decompose`](skills/decompose/SKILL.md) | writes `.temp/` | Proposal, знахідки рев'ю чи аудиту, задача на розбиття → новий файл задач з оцінкою складності; ніколи не перезаписує наявні. |
| [`/pas:implement`](skills/implement/SKILL.md) | writes code | Батч задач без пауз: один `pas:implementer` на задачу, TDD (Red → Green → Verify), чекбокси, повна перевірка (full check) раз на батч, ручні перевірки одним чеклістом наприкінці. |
| [`/pas:review`](skills/review/SKILL.md) | writes `.temp/` | Свіжі `pas:reviewer` (один або два паралельно), лише знахідки з упевненістю ≥ 80, вердикт і наступний крок; також рев'ю proposal і файлів задач. |
| [`/pas:debug`](skills/debug/SKILL.md) | writes code | Reproduce → Localize → Root cause → Fix & guard з регресійним тестом. |
| [`/pas:spec`](skills/spec/SKILL.md) | writes docs | Оновлює `docs/specifications/` через `pas:spec-writer`, лише якщо в проєкті вони є. |
| [`/pas:git`](skills/git/SKILL.md) | git operator | План атомарних Conventional Commits, одне підтвердження, захист `.temp/`; наприкінці пропонує видалити завершену `.temp/<topic>/`. |
| [`/pas:audit`](skills/audit/SKILL.md) | read-only | `code`: баги, безпека, навантаження, код без тестів, дублювання й зайве; `structure`: модулі, напрямок залежностей, що виносити, цільова структура й дорожня карта. Далі — `/pas:decompose` для обраних знахідок. |

## Агенти

| Агент | Модель | Роль |
| --- | --- | --- |
| [`pas:scout`](agents/scout.md) | haiku | Read-only пошук по коду на одне вузьке питання: висновки й 5–10 ключових файлів `path:line`. |
| [`pas:architect`](agents/architect.md) | opus, high | Read-only: один варіант дизайну під заданий кут (minimal / clean / pragmatic). |
| [`pas:decomposer`](agents/decomposer.md) | opus, high | Пише один новий файл задач за [шаблоном](shared/task-template.md); не питає, повертає `blocked:`. |
| [`pas:implementer`](agents/implementer.md) | з оцінки задачі | Одна задача за TDD з перевіркою проєкту, без комітів, 3 спроби, режим debug, звіт із доказами. |
| [`pas:reviewer`](agents/reviewer.md) | opus, high | Zero-write рев'ю з фокусом (correctness або simplicity+conventions), упевненість 0–100, звіт ≥ 80. |
| [`pas:spec-writer`](agents/spec-writer.md) | sonnet, high | Нормативні специфікації поточного стану. |

Спільні правила — один раз у [`shared/`](shared/): [`rules.md`](shared/rules.md) (режими, `.temp/`, теми, worktree, ворота, перевикористання, гігієна контексту, мова), [`complexity.md`](shared/complexity.md) (маршрути, оцінка, бюджет контексту), [`task-template.md`](shared/task-template.md). Хуки плагіна: на старті сесії — список незавершених тем `.temp/`; перед Bash/PowerShell — блокування force push, `reset --hard`, `git clean` і `--no-verify`.

---

## Інші агенти: `install.ps1` / `install.sh`

Скрипти копіюють `skills/<name>/` (без `evals/`) у `.agents/skills`, а `shared/` і `agents/`, на які посилаються скіли, — поруч у `.agents/pas/`. Посилання `${CLAUDE_PLUGIN_ROOT}/…` у скопійованих файлах переписуються: `.agents/pas/…` від кореня проєкту для проєктного встановлення, абсолютний шлях — для глобального. Скрипт також додає `.temp/` у `.gitignore` проєкту.

```powershell
.\install.ps1 -Target "D:\path\to\project"                  # <проєкт>/.agents/skills + .agents/pas
.\install.ps1 -Target "D:\path\to\project" -Skill flow,implement
.\install.ps1 -Global                                       # ~/.agents/skills і ~/.gemini/config/skills
.\install.ps1 -All -Force -Prune                            # усюди: junction у репо, глобально, сусідні проєкти з .agents/skills
.\install.ps1 -Target "D:\path\to\project" -Claude -Prune   # Claude Code: друкує команди плагіна, прибирає старі копії з .claude/skills
.\install.ps1 -SyncRepo                                     # .agents/skills -> skills/ у цьому репозиторії
```

```bash
./install.sh --target /path/to/project [--skill flow --skill implement]
./install.sh --global
./install.sh --all [--force] [--prune]
./install.sh --target /path/to/project --claude [--prune]
./install.sh --sync-repo
```

* Маніфест `.practical-agent-skills.manifest` зберігає хеш кожного встановленого скіла: локально змінений скіл пропускається без `-Force`; `-Prune` видаляє скіли, яких більше немає в репозиторії (у 2.0 — `using-agent-skills`, `idea`, `interview`, `architect`, `cleanup`); скіли проєкту поза маніфестом не чіпаються.
* `.agents/pas/` належить інсталятору й перезаписується щоразу.
* На хості без префікса плагіна `/pas:<name>` у тексті скілів означає скіл `<name>`, а `pas:<agent>` — визначення `.agents/pas/agents/<agent>.md`, за яким головна сесія працює сама, якщо субагентів немає.
* `npx skills add` копіює лише папки `skills/`, тож посилання на `shared/` і `agents/` там не працюють; для не-Claude агентів використовуйте скрипти. Кореневий [`plugin.json`](plugin.json) — маніфест для Antigravity (`agy plugin install`).

---

## Робочий простір у проєкті

```text
<project-root>/
├── .gitignore                 # містить .temp/
├── .temp/<topic>/             # чернетки, не потрапляють у git
│   ├── flow.md                # стан прогону /pas:flow (маршрут, етап, рішення, журнал)
│   ├── proposal.md            # дизайн великої задачі (/pas:proposal)
│   ├── tasks.md               # файл задач із шапкою Context & Intent
│   ├── review-1.md            # вердикт і нумеровані знахідки рев'ю
│   ├── review-1-tasks.md      # задачі зі знахідок рев'ю
│   └── subtasks-3.md          # розбиття задачі 3
└── docs/specifications/       # нормативні специфікації поточного стану (/pas:spec)
```

У git worktree `.temp/` немає: джерело правди — `.temp/<topic>/` основного checkout'у; субагенти у worktree отримують текст задачі в промпті.

---

## Структура репозиторію

* `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` — плагін `pas` і marketplace `letale-skills`.
* `skills/`, `agents/`, `shared/`, `hooks/` + `scripts/` — вміст плагіна.
* `skills/<name>/evals/` — тестові випадки у форматі `claude plugin eval`; інсталятори їх не копіюють.
* `docs/specifications/skill-chain-architecture.md` — контракти між частинами плагіна.
* `install.ps1` / `install.sh` — встановлення для Codex та інших агентів.
