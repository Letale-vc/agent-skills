import unittest

from shop.pricing import apply_discount


class ApplyDiscountTests(unittest.TestCase):
    def test_save10_takes_ten_percent(self):
        self.assertEqual(apply_discount(100, "SAVE10"), 90.0)

    def test_unknown_coupon_keeps_total(self):
        self.assertEqual(apply_discount(100, "NOPE"), 100)


if __name__ == "__main__":
    unittest.main()
