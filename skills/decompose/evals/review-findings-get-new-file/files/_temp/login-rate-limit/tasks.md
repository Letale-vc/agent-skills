## Context & Intent

- **Goal**: Block a login key after too many attempts.
- **Strategy**: In-Place
- **Constraints**: No new dependencies.

- [x] **Task 1: Add Limiter with a per-key counter**
  - **Model**: standard
  - **Target files**: `ratelimit/limiter.py`, `tests/test_limiter.py`
  - **Verification**: `tests/test_limiter.py` green.

- [x] **Task 2: Call Limiter from the login handler**
  - **Model**: standard
  - **Target files**: `ratelimit/limiter.py`
  - **Verification**: build + existing tests.
