## Context & Intent

- **Goal**: Callers get coupon discounts through `shop.pricing`.
- **Strategy**: In-Place
- **Constraints**: `shop/pricing` → nothing.

- [x] **Task 1: Export apply_discount from shop.pricing**
  - **Model**: standard (D0 V0 S0)
  - **Target files**: `shop/pricing/__init__.py`, `tests/test_pricing.py`
  - **Context**: `shop/pricing/discounts.py:1` defines `apply_discount`.
  - **Reuse**: re-export `apply_discount` from `shop/pricing/discounts.py`.
  - **Verification**: `tests/test_pricing.py` passes with `python -m unittest`.
