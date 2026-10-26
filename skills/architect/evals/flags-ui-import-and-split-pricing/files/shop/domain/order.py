from shop.ui.formatting import money


class Order:
    def __init__(self, items):
        self.items = items  # list of (name, price, qty)

    def subtotal(self):
        return sum(price * qty for _, price, qty in self.items)

    def describe(self):
        return f"{len(self.items)} items, {money(self.subtotal())}"
