## Context & Intent

- **Goal**: Callers import pricing only through `shop.pricing`, never from its internal modules.
- **Strategy**: In-Place
- **Constraints**: `shop/pricing` → nothing.

Parent: ../arch-shop/tasks.md#Task 2

- [ ] **Task 1: Export apply_discount from shop.pricing**
  - **Model**: standard
  - **Target files**: `shop/pricing/__init__.py`, `tests/test_pricing_entry.py`
  - **Context**: `shop/pricing/discounts.py:1` defines `apply_discount`; `shop/pricing/__init__.py` is empty.
  - **Reuse**: re-export `apply_discount` from `shop/pricing/discounts.py`.
  - **Verification**: `tests/test_pricing_entry.py` checks that `from shop.pricing import apply_discount` returns 90.0 for `(100, "SAVE10")`; `python -m unittest` green.
