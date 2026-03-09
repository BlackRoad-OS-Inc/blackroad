export type Chain = string;

export function isProbablyAddress(chain: Chain | string, addr: string): boolean {
  if (!addr) return false;
  const c = String(chain).toLowerCase();

  // Shared EVM style (ETH, BSC, Polygon, AVAX C-Chain, ERC-20 tokens like LINK/USDT/USDC/GRT)
  const isEvm = (a: string) => /^0x[a-fA-F0-9]{40}$/.test(a);

  switch (c) {
    case 'eth':
    case 'usdt':
    case 'usdc':
    case 'bnb':
    case 'matic':
    case 'avax':
    case 'link':
    case 'grt':
    case 'vet':
      return isEvm(addr);

    case 'btc':
      return /^bc1[ac-hj-np-z0-9]{25,87}$|^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$/.test(addr);

    case 'ltc':
      return /^ltc1[ac-hj-np-z0-9]{20,90}$|^[LM3][a-km-zA-HJ-NP-Z1-9]{25,34}$/.test(addr);

    case 'doge':
      return /^D[5-9A-HJ-NP-Ua-km-z]{25,34}$/.test(addr);

    case 'bch':
      return /^(bitcoincash:)?(q|p)[a-z0-9]{41}$/i.test(addr) ||
        /^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$/.test(addr);

    case 'sol':
      return /^[1-9A-HJ-NP-Za-km-z]{32,44}$/.test(addr);

    case 'ton':
      return /^UQ[0-9A-Za-z_-]{46}$/.test(addr);

    case 'atom':
      return /^cosmos1[0-9a-z]{20,80}$/.test(addr);

    case 'dot':
      return /^[1-9A-HJ-NP-Za-km-z]{47,50}$/.test(addr);

    case 'xrp':
      return /^r[1-9A-HJ-NP-Za-km-z]{24,34}$/.test(addr);

    case 'trx':
      return /^T[1-9A-HJ-NP-Za-km-z]{33}$/.test(addr);

    case 'ada':
      return /^addr1[0-9a-z]{20,120}$/.test(addr);

    default:
      // fallback: treat it as EVM if looks like 0x40hex
      return isEvm(addr);
  }
import crypto from 'node:crypto';

export type SupportedChain =
  | 'btc'
  | 'eth'
  | 'ltc'
  | 'sol'
  | 'cosmos'
  | 'near'
  | 'ton'
  | 'ada'
  | 'dot';

const ADDRESS_PATTERNS: Record<SupportedChain, RegExp> = {
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

export function isProbablyAddress(chain: SupportedChain, value: string): boolean {
  const normalized = value.trim();
  const pattern = ADDRESS_PATTERNS[chain];
  return pattern.test(normalized);
}

export function mask(value: string): string {
  if (!value) {
    return '****';
  }
  const suffix = value.slice(-6);
  return `****${suffix}`;
}

export function digestHex(value: string): string {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function runCli(): void {
  const [, , chainArg, rawValue] = process.argv;
  if (!chainArg || !rawValue) {
    console.error('Usage: node tools/addresses.js <CHAIN> "<ADDRESS>"');
    process.exit(1);
  }

  const chain = chainArg.toLowerCase() as SupportedChain;
  if (!(chain in ADDRESS_PATTERNS)) {
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
