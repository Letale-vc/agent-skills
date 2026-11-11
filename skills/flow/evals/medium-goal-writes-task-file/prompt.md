---
tags: [flow]
max_turns: 80
timeout_seconds: 2400
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash, Agent]
---

/pas:flow купони в shop/pricing, тема coupons:

1. Винеси таблицю купонів у `shop/pricing/coupons.py`: код → (відсоток, дата закінчення). SAVE10 діє до 2099-12-31.
2. Додай купон SAVE20 (20%, до 2099-12-31) і прострочений OLD5 (5%, закінчився 2020-01-01).
3. `apply_discount(total, coupon, today=None)` кидає `ValueError` на прострочений купон (`today` за замовчуванням — `date.today()`); невідомий код, як і раніше, лишає суму без змін.

Input files: README.md, shop/pricing/__init__.py, shop/pricing/discounts.py, tests/test_pricing.py
