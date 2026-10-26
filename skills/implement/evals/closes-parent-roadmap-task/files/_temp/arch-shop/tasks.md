## Context & Intent

- **Goal**: Pricing rules live in `shop/pricing/`, with no UI or HTTP imports.
- **Strategy**: In-Place
- **Constraints**: `shop/pricing` → nothing; `shop/ui` and `shop/api` → `shop/pricing`.

- [x] **Task 1: Add apply_discount to shop/pricing**
  - **Model**: standard
  - **Target files**: `shop/pricing/discounts.py`
  - **Verification**: `python -m unittest` green.

- [ ] **Task 2: Give shop/pricing one public entry**
  - **Model**: high
  - **Design**: /proposal first in .temp/arch-shop-2/
  - Roadmap step 2.
