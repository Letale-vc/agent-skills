---
type: llm
focus: trace
weight: 1
---

The report finds the discount rules duplicated in shop/ui/cart_view.py and shop/api/orders.py and states at least one concrete difference between them (rounding versus truncation, or > 100 versus >= 100).
