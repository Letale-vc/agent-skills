import unittest

from ratelimit.limiter import Limiter


class LimiterTests(unittest.TestCase):
    def test_blocks_after_limit(self):
        limiter = Limiter(limit=2, window_seconds=60)
        self.assertTrue(limiter.allow("ann"))
        self.assertTrue(limiter.allow("ann"))
        self.assertFalse(limiter.allow("ann"))


if __name__ == "__main__":
    unittest.main()
