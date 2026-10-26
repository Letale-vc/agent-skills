## Context & Intent

- **Goal**: Pricing rules live in `shop/pricing/`, with no UI or HTTP imports.
- **Strategy**: In-Place
- **Constraints**: `shop/pricing` → nothing; `shop/ui` and `shop/api` → `shop/pricing`.

- [ ] **Task 1: Add apply_discount to shop/pricing**
  - **Model**: standard
  - **Target files**: `shop/pricing/discounts.py`, `tests/test_discounts.py`
  - **Context**: `apply_discount(total: float, coupon: str | None) -> float` — coupon `SAVE10` takes 10% off, then a total above 100 gets 5 off; round to 2 decimals.
  - **Reuse**: none found (searched: discount, coupon)
  - **Verification**: `tests/test_discounts.py` covers `SAVE10`, a total above 100 and exactly 100; `python -m unittest` green.

- [ ] **Task 2: Extract shop/pricing into a package for the mobile client**
  - **Model**: high
  - **Design**: /proposal first in .temp/arch-shop-pricing-pkg/
  - Roadmap step 3; open decision: workspace package or published library.

- [ ] **Task 3: Add format_discount to shop/ui/formatting**
  - **Model**: standard
  - **Target files**: `shop/ui/__init__.py`, `shop/ui/formatting.py`, `tests/test_formatting.py`
  - **Context**: `format_discount(amount: float) -> str` returns `"-$5.00"` for `5`.
  - **Reuse**: none found (searched: format, money)
  - **Verification**: `tests/test_formatting.py` checks `5` → `"-$5.00"`; `python -m unittest` green.
