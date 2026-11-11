def apply_discount(total, coupon):
    if coupon == "SAVE10":
        return round(total * 0.9, 2)
    return total
