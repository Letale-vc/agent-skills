import unittest

import shop


class SmokeTests(unittest.TestCase):
    def test_package_imports(self):
        self.assertIsNotNone(shop)


if __name__ == "__main__":
    unittest.main()
