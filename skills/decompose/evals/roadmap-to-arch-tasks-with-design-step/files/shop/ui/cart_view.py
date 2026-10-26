from shop.domain.order import Order
from shop.ui.formatting import money


def render_cart(order: Order, coupon: str | None) -> str:
    total = order.subtotal()
    if coupon == "SAVE10":
        total = round(total * 0.9, 2)
    if total > 100:
        total = round(total - 5, 2)
    return f"Total: {money(total)}"
