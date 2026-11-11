#!/usr/bin/env node
const { slugify } = require("./utils/slug");
const { isoDate } = require("./utils/dates");

const title = process.argv.slice(2).join(" ");
console.log(`${isoDate(new Date())}-${slugify(title)}`);
