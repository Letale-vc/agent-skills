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
# Встановити ГЛОБАЛЬНО на ПК (~/.gemini/config/skills та ~/.agents/skills)
.\install.ps1 -Global

# Встановити ЛОКАЛЬНО у конкретний проєкт
.\install.ps1 -Target "D:\practik\MyProject"

# Встановити лише обрані скіли у проєкт
.\install.ps1 -Target "D:\practik\MyProject" -Skill idea,interview,proposal,decompose

# Синхронізувати .agents/skills/ -> skills/ після редагування скілів у цьому репозиторії
.\install.ps1 -SyncRepo
```

Для Bash (Linux / macOS / Git Bash):

```bash
./install.sh --global
./install.sh --target /path/to/my-project
./install.sh --target /path/to/my-project --skill interview --skill proposal
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

| Етап | Команда | Режим доступу | Призначення |
| :--- | :--- | :--- | :--- |
| **0. Idea** | [`/idea`](skills/idea/SKILL.md) | **100% Read-Only** | Допомагає розвинути і сформулювати сиру/нечітку думку через генерацію напрямків, рекомендацій та навідних питань. Видає блок `Crystallized Idea`. |
| **1. Interview** | [`/interview`](skills/interview/SKILL.md) | **100% Read-Only** | Виявляє приховані вимоги та межі (1 питання за раз із гіпотезою `GUESS` та оцінкою `CONFIDENCE` до ~95%). |
| **2. Intent** | [`/intent`](skills/intent/SKILL.md) | **Writer** (`.temp/<topic>/intent.md`) | Фіксує лаконічний Statement of Intent у `.temp/<topic>/intent.md`. |
| **3. Proposal** | [`/proposal`](skills/proposal/SKILL.md) | **Writer** (`.temp/<topic>/proposal.md`) | Створює технічний RFC, перевіряє версії залежностей і пропонує стратегію інтеграції: **Expand-Contract (паралельна реалізація з deprecation/видаленням)** або **In-Place**. |
| **4. Decompose** | [`/decompose`](skills/decompose/SKILL.md) | **Append-Writer** (`.temp/<topic>/*tasks.md`) | Розбиває план, чат-дискусію або зауваження рев'ю на неруйнівні задачі з прикладами коду. **Ніколи не перезаписує старі файли задач** (`tasks.md`, `review-1-tasks.md`, `subtasks-1.md`). |
| **5. Implement** | [`/implement`](skills/implement/SKILL.md) | **Writer** (`src/`, тести, `[x]`) | Виконує задачі за TDD (по одній або всі залпом), зберігаючи проєкт у 100% робочому стані, та відмічає прогрес `[ ]` → `[x]`. |
| **6. Review** | [`/review`](skills/review/SKILL.md) | **100% Read-Only** | Чистий рецензент (код, задачі або пропоузал). Нічого не редагує і не запускає тести. При зауваженнях рекомендує `/decompose`, при успіху — `/spec` або `/cleanup`. |
| **7. Spec** | [`/spec`](skills/spec/SKILL.md) | **Writer** (`docs/specifications/`) | Створює або оновлює декларативні нормативні специфікації системи у `docs/specifications/` (як система працює зараз, без історії міграцій). |
| **8. Cleanup** | [`/cleanup`](skills/cleanup/SKILL.md) | **Cleaner** (`.temp/`) | Показує стан тем у `.temp/` і через інтерактивний `ask_question` запитує, які завершені папки видалити, а які залишити. |

### Мета-роутер та утиліти (Meta & Utility Skills)

| Команда | Режим доступу | Призначення |
| :--- | :--- | :--- |
| [`/using-agent-skills`](skills/using-agent-skills/SKILL.md) | **100% Read-Only** | Карта вибору скілів під задачу + 6 базових правил інженерної дисципліни агента. |
| [`/debug`](skills/debug/SKILL.md) | **Diagnostic & Fix** | Пошук першопричини багів за правилом `Stop-the-Line`: `Reproduce` → `Localize` → `Root Cause Hypothesis` → інтерактивний вибір способу виправлення. |
| [`/git`](skills/git/SKILL.md) | **Git Operator (Confirmed)** | Групування змін у чисті атомарні коміти з фокусом на *why*, захист від потрапляння `.temp/` у коміт та обов'язкове підтвердження перед `git commit`. |

---

## Організація робочого простору у ваших проєктах

```text
<project-root>/
├── .gitignore                   # Автоматично містить: .temp/
├── .temp/                       # Ізольований локальний scratchpad (не світиться в git status)
│   └── <feature-topic>/
│       ├── intent.md            # Результат фіксації наміру (/intent)
│       ├── proposal.md          # Опис змін і стратегія Expand-Contract vs In-Place (/proposal)
│       ├── tasks.md             # Первинна декомпозиція (/decompose)
│       ├── review-1-tasks.md    # Задачі за результатами рев'ю (/decompose після /review)
│       └── subtasks-1.md        # Опціональне дроблення окремої задачі (/decompose)
├── docs/
│   └── specifications/          # СПРАВЖНІ нормативні специфікації системи (/spec)
└── src/                         # Вихідний код та тести (/implement)
```

---

## Структура самого репозиторію `agent-skills`

* `skills/<name>/SKILL.md` — канонічна директорія скілів для `npx skills`, `agy plugin install`, `gemini skills install` та скриптів `install.ps1` / `install.sh`.
* `.agents/skills/<name>/SKILL.md` — локальна копія для роботи всередині самого репозиторію (синхронізується через `.\install.ps1 -SyncRepo`).
* `plugin.json` — кореневий маніфест плагіна для Antigravity.
* `install.ps1` / `install.sh` — скрипти швидкого локального та глобального встановлення.
