"use strict";
const crypto = require("node:crypto");
const ADDRESS_PATTERNS = {
  btc: /^(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,60}$/,
  eth: /^0x[a-fA-F0-9]{40}$/,
  ltc: /^(ltc1|[LM3])[a-zA-HJ-NP-Z0-9]{25,60}$/,
  sol: /^[1-9A-HJ-NP-Za-km-z]{32,44}$/,
  cosmos: /^cosmos1[0-9a-z]{38}$/,
  near: /^(?:[a-z0-9._-]{2,64}\.)?near$/,
  ton: /^(?:EQ|UQ)[A-Za-z0-9_-]{46}$/,
  ada: /^addr1[0-9a-z]{58,}$/,
  dot: /^1[0-9A-HJ-NP-Za-km-z]{47,48}$/
};
function isProbablyAddress(chain, value) {
  const normalized = value.trim();
  const pattern = ADDRESS_PATTERNS[chain];
  return pattern.test(normalized);
}
function mask(value) {
  if (!value) {
    return "****";
  }
  const suffix = value.slice(-6);
  return `****${suffix}`;
}
function digestHex(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}
function runCli() {
  const [, , chainArg, rawValue] = process.argv;
  if (!chainArg || !rawValue) {
    console.error("Usage: node tools/addresses.js <CHAIN> \"<ADDRESS>\"");
    process.exit(1);
  }
  const chain = chainArg.toLowerCase();
  if (!Object.prototype.hasOwnProperty.call(ADDRESS_PATTERNS, chain)) {
    console.error(`Unsupported chain: ${chainArg}`);
    process.exit(1);
  }
  const digest = digestHex(rawValue);
  const result = {
    chain,
    isValidFormat: isProbablyAddress(chain, rawValue),
    masked: mask(rawValue),
    digest8: digest.slice(0, 8),
    length: rawValue.length
  };
  console.log(JSON.stringify(result));
}
if (require.main === module) {
  runCli();
}
module.exports = {
  ADDRESS_PATTERNS,
  digestHex,
  isProbablyAddress,
  mask
};
