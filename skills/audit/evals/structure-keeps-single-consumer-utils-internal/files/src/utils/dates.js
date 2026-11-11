function isoDate(date) {
  return date.toISOString().slice(0, 10);
}

module.exports = { isoDate };
