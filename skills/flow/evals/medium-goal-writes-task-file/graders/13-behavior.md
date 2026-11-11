---
type: llm
focus: { source: file, path: shop/pricing/discounts.py }
weight: 1
---

apply_discount reads the coupon table from shop/pricing/coupons.py: apply_discount(100, "SAVE20") returns 80.0, SAVE10 still returns 90.0, the expired OLD5 raises ValueError, and an unknown code returns the total unchanged.
