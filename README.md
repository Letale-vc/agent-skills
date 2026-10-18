# Practical Agent Skills

Модульна система з **12 інженерних скілів** для AI-агентів (Antigravity, Claude Code, Cursor, Gemini CLI, Codex, OpenCode), яка повністю ізолює чернетки розробки в `.temp/<topic>/`, відокремлює нормативні специфікації в `docs/specifications/` та веде розробника через м'які інтерактивні розвилки з рекомендаціями агента.

---

## Quick Start (Швидке встановлення)

### 1. Через універсальний `npx skills` CLI (підтримує 70+ агентів)

```bash
# Встановити всі 12 скілів локально у поточний проєкт (з GitHub або локального шляху)
npx skills add Letale-vc/agent-skills
# або з локального клону:
npx skills add D:\practik\agent-skills

# Встановити ГЛОБАЛЬНО на комп'ютер (для всіх проєктів)
npx skills add Letale-vc/agent-skills --global

# Переглянути список доступних скілів перед встановленням
npx skills add D:\practik\agent-skills --list

# Встановити лише окремий скіл
npx skills add D:\practik\agent-skills --skill interview
```

### 2. Через вбудований скрипт `install.ps1` (Windows) або `install.sh` (Linux/macOS/Git Bash)

Працює миттєво без Node.js та автоматично додає `.temp/` у `.gitignore` цільового проєкту:

```powershell
# Оновити ВСЮДИ однією командою (Junction у репо + глобально + у всіх сусідніх проєктах, де вже є .agents/skills)
.\install.ps1 -All

# Примусово перезаписати локально змінені скіли та видалити застарілі/перейменовані скіли
.\install.ps1 -All -Force -Prune

# Встановити ГЛОБАЛЬНО на ПК (~/.gemini/config/skills та ~/.agents/skills)
.\install.ps1 -Global

# Встановити ЛОКАЛЬНО у конкретний проєкт
.\install.ps1 -Target "D:\practik\MyProject"

# Встановити лише обрані скіли у проєкт
.\install.ps1 -Target "D:\practik\MyProject" -Skill idea,interview,proposal,decompose

# Зв'язати .agents/skills -> skills/ через Directory Junction у цьому репозиторії
.\install.ps1 -SyncRepo
```

Для Bash (Linux / macOS / Git Bash):

```bash
./install.sh --all [--force] [--prune]
./install.sh --global [--force] [--prune]
./install.sh --target /path/to/my-project
./install.sh --target /path/to/my-project --skill interview --skill proposal
./install.sh --sync-repo
```

### 3. Як нативний плагін Antigravity (`agy`)

```bash
# Із локального клону
agy plugin install D:\practik\agent-skills

# Або напряму з Git-репозиторію
agy plugin install https://github.com/Letale-vc/agent-skills.git
```

---

## Усі 12 скілів системи

### Основний ланцюжок розробки (The 9-Stage Lifecycle Chain)

| # | Скіл | Режим&nbsp;доступу | Призначення |
| :---: | :--- | :--- | :--- |
| **0** | [`/idea`](skills/idea/SKILL.md) | `Read-Only` | Допомагає розвинути і сформулювати сиру/нечітку думку через генерацію напрямків, рекомендацій та навідних питань. Видає блок `Crystallized Idea`. |
| **1** | [`/interview`](skills/interview/SKILL.md) | `Read-Only` | Виявляє приховані вимоги та межі (1 питання за раз із гіпотезою `GUESS`, оцінкою `CONFIDENCE` та жорстким лімітом **макс. 3–5 питань**, решта йде в `Assumptions`). |
| **2** | [`/intent`](skills/intent/SKILL.md) | `Writer` (`.temp/<topic>/intent.md`) | Фіксує лаконічний Statement of Intent у `.temp/<topic>/intent.md`. |
| **3** | [`/proposal`](skills/proposal/SKILL.md) | `Writer` (`.temp/<topic>/proposal.md`) | Створює технічний RFC, перевіряє версії залежностей і пропонує стратегію інтеграції: **Expand-Contract** (паралельна реалізація з deprecation/видаленням) або **In-Place**. |
| **4** | [`/decompose`](skills/decompose/SKILL.md) | `Append-Writer` (`.temp/<topic>/*tasks.md`) | Розбиває план, чат-дискусію або зауваження рев'ю на неруйнівні задачі з шапкою `Context & Intent`, вказівником `Parent:` для підзадач та прикладами коду. **Ніколи не перезаписує старі файли задач**. |
| **5** | [`/implement`](skills/implement/SKILL.md) | `Writer` (`src/`, тести, `[x]`/`[-]`) | Виконує задачі за суворим TDD (`Red → Green → Verify`), ігноруючи закриті `100% [x]/[-]` файли для економії контексту, та відмічає прогрес `[ ]` → `[x]` або скасування `[-]`. |
| **6** | [`/review`](skills/review/SKILL.md) | `Zero-Write Auditor` | Не модифікує жодних вихідних чи відстежуваних файлів, але **запускає read-only перевірки** (`git diff`, тести в `--ci`, тайпчекер, лінтер). При зауваженнях рекомендує `/decompose`, при успіху — `/spec` або `/cleanup`. |
| **7** | [`/spec`](skills/spec/SKILL.md) | `Writer` (`docs/specifications/`) | Створює або оновлює декларативні нормативні специфікації системи у `docs/specifications/` (як система працює зараз, без історії міграцій). |
| **8** | [`/cleanup`](skills/cleanup/SKILL.md) | `Cleaner` (`.temp/`) | Показує стан тем у `.temp/` і запитує підтвердження (через `ask_question` або текстовий fallback), які завершені папки видалити, а які залишити. |

### Fast-Track маршрути та режим Autopilot (без зайвої бюрократії)

Не кожна задача потребує проходження всіх 9 етапів або ручного підтвердження на кожному кроці:
* **Micro-fix / Bugfix**: одразу `/debug` або `/implement`.
* **Small / Medium Feature (Fast-Track)**: одразу `/decompose` (створює `.temp/<topic>/tasks.md` із вбудованою шапкою `## Context & Intent`, минаючи `intent.md` та `proposal.md`) → `/implement` → `/review`.
* **Large / Architectural Feature**: `/interview` (або `/idea`) → `/proposal` → `/decompose` → `/implement` → `/review` → `/spec` → `/cleanup`.
* **Autopilot Mode**: якщо попросити агента *«роби до кінця»* (*autopilot*), скіли автоматично переходять за рекомендованим маршрутом без проміжних зупинок і стають на паузу лише при зауваженнях `/review` (`CHANGES RECOMMENDED`), блокерах або перед `git commit` / видаленням `.temp/`.

### Мета-роутер та утиліти (Meta & Utility Skills)

| Скіл | Режим&nbsp;доступу | Призначення |
| :--- | :--- | :--- |
| [`/using-agent-skills`](skills/using-agent-skills/SKILL.md) | `Read-Only` | Карта вибору скілів (Fast-Track, Autopilot), режим відновлення контексту **«Де я зупинився?»** (сканування `.temp/`) + 6 базових правил інженерної дисципліни. |
| [`/debug`](skills/debug/SKILL.md) | **Diagnostic&nbsp;&amp;&nbsp;Fix** | Пошук першопричини багів (включно з flaky/intermittent багами) за правилом `Stop-the-Line`: `Reproduce` → `Localize` → `Root Cause Hypothesis` → фікс + тест. |
| [`/git`](skills/git/SKILL.md) | **Git&nbsp;Operator** | Групування змін у чисті атомарні коміти з фокусом на *why*, захист від потрапляння `.temp/` у коміт та обов'язкове підтвердження перед `git commit`. |

---

## Організація робочого простору у ваших проєктах

```text
<project-root>/
├── .gitignore                   # Автоматично містить: .temp/
├── .temp/                       # Ізольований локальний scratchpad (не світиться в git status)
│   └── <feature-topic>/
│       ├── intent.md            # Результат фіксації наміру (/intent, опціонально)
│       ├── proposal.md          # Опис змін і стратегія Expand-Contract vs In-Place (/proposal, опціонально)
│       ├── tasks.md             # Первинна декомпозиція з шапкою Context & Intent (/decompose)
│       ├── review-1-tasks.md    # Задачі за результатами рев'ю (/decompose після /review)
│       └── subtasks-1.md        # Опціональне дроблення окремої задачі (/decompose)
├── docs/
│   └── specifications/          # СПРАВЖНІ нормативні специфікації системи (/spec)
└── src/                         # Вихідний код та тести (/implement)
```

---

## Структура самого репозиторію `agent-skills`

* `skills/<name>/SKILL.md` — **єдине канонічне джерело правди** для `npx skills`, `agy plugin install`, `gemini skills install` та скриптів `install.ps1` / `install.sh`.
* `.agents/skills` — Directory Junction (Windows) / Symlink (Linux/macOS), який прямо вказує на `skills/` (створюється через `.\install.ps1 -SyncRepo` або `./install.sh --sync-repo`), тому редагування у будь-якій папці змінює один і той самий файл без ризику розсинхрону.
* `plugin.json` — кореневий маніфест плагіна для Antigravity.
* `install.ps1` / `install.sh` — скрипти швидкого локального та глобального встановлення.
