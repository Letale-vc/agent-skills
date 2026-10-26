def apply_discount(total, coupon):
    if coupon == "SAVE10":
        total = round(total * 0.9, 2)
    if total > 100:
        total = round(total - 5, 2)
    return total
