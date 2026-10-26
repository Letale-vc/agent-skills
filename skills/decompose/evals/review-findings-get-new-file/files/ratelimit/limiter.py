import time


class Limiter:
    def __init__(self, limit, window_seconds):
        self.limit = limit
        self.window = window_seconds
        self.hits = {}

    def allow(self, key):
        now = time.monotonic()
        count, started = self.hits.get(key, (0, now))
        if count >= self.limit:
            return False
        self.hits[key] = (count + 1, started)
        return True
