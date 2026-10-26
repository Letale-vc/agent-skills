from shop.domain.order import Order


def order_total(order: Order, coupon: str | None) -> float:
    total = order.subtotal()
    if coupon == "SAVE10":
        total = int(total * 90) / 100
    if total >= 100:
        total -= 5
    return total
