---
tags: [decompose]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Звіт /architect (скорочено):

Знахідки:
1. Domain імпортує UI: `shop/domain/order.py` → `shop/ui/formatting.py`.
2. Правила знижок дублюються в `shop/ui/cart_view.py` і `shop/api/orders.py` і вже розходяться (round проти truncation, поріг > 100 проти >= 100).

Цільова структура: `shop/pricing/` (правила цін, без UI і HTTP). Правила залежностей: `shop/domain` → нічого; `shop/pricing` → нічого; `shop/ui` → domain, pricing; `shop/api` → domain, pricing.

Дорожня карта:
1. Перенести правила знижок у `shop/pricing/discounts.py` і викликати їх з `cart_view` та `orders` (закриває 2; S; маршрут `tasks`; правильна поведінка — round до 2 знаків і поріг > 100).
2. Прибрати імпорт UI з domain: `Order.describe` переїжджає в `shop/ui` (закриває 1; S; маршрут `tasks`).
3. Винести `shop/pricing` в окремий пакет для мобільного клієнта (L; маршрут `/proposal` — відкрите рішення: workspace-пакет чи опублікована бібліотека).

Беремо кроки 1–3. /decompose

Input files: README.md, shop/domain/order.py, shop/ui/cart_view.py, shop/ui/formatting.py, shop/api/orders.py
