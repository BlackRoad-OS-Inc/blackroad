import chalk from 'chalk';
import { spawn } from 'child_process';
import ora from 'ora';
import Table from 'cli-table3';
import inquirer from 'inquirer';
import fs from 'fs/promises';
import path from 'path';
import axios from 'axios';

const WALLET_FILE = path.join(process.env.HOME, '.blackroad', 'wallets.json');

const SUPPORTED_CHAINS = {
  ethereum: {
    name: 'Ethereum',
    symbol: 'ETH',
    color: '#627EEA',
    explorer: 'https://etherscan.io',
    rpc: 'https://eth.llamarpc.com'
  },
  bitcoin: {
    name: 'Bitcoin',
    symbol: 'BTC',
    color: '#F7931A',
    explorer: 'https://blockchain.com',
    rpc: null
  },
  solana: {
    name: 'Solana',
    symbol: 'SOL',
    color: '#14F195',
    explorer: 'https://solscan.io',
    rpc: 'https://api.mainnet-beta.solana.com'
  },
  polygon: {
    name: 'Polygon',
    symbol: 'MATIC',
    color: '#8247E5',
    explorer: 'https://polygonscan.com',
    rpc: 'https://polygon-rpc.com'
  }
};

class CryptoWallet {
  constructor() {
    this.wallets = {};
  }

  async ensureWalletFile() {
    const dir = path.dirname(WALLET_FILE);
    try {
      await fs.mkdir(dir, { recursive: true });
    } catch (e) {
      // Directory exists
    }

    try {
      const data = await fs.readFile(WALLET_FILE, 'utf-8');
      this.wallets = JSON.parse(data);
    } catch (e) {
      this.wallets = {};
      await this.saveWallets();
    }
  }

  async saveWallets() {
    await fs.writeFile(WALLET_FILE, JSON.stringify(this.wallets, null, 2), 'utf-8');
  }

  async addWallet(name, chain, address) {
    this.wallets[name] = {
      chain,
      address,
      addedAt: new Date().toISOString()
    };
    await this.saveWallets();
  }

  async removeWallet(name) {
    delete this.wallets[name];
    await this.saveWallets();
  }

  async getBalance(chain, address) {
    const config = SUPPORTED_CHAINS[chain];

    if (chain === 'ethereum' || chain === 'polygon') {
      try {
        const response = await axios.post(config.rpc, {
          jsonrpc: '2.0',
          method: 'eth_getBalance',
          params: [address, 'latest'],
          id: 1
        }, {
          headers: { 'Content-Type': 'application/json' }
        });

        if (response.data.result) {
          const balanceWei = parseInt(response.data.result, 16);
          const balanceEth = balanceWei / 1e18;
          return balanceEth.toFixed(6);
        }
      } catch (e) {
        return 'Error';
      }
    }

    if (chain === 'solana') {
      try {
        const response = await axios.post(config.rpc, {
          jsonrpc: '2.0',
          id: 1,
          method: 'getBalance',
          params: [address]
        }, {
          headers: { 'Content-Type': 'application/json' }
        });

        if (response.data.result && response.data.result.value !== undefined) {
          const balanceLamports = response.data.result.value;
          const balanceSol = balanceLamports / 1e9;
          return balanceSol.toFixed(6);
        }
      } catch (e) {
        return 'Error';
      }
    }

    if (chain === 'bitcoin') {
      try {
        const response = await axios.get(`https://blockchain.info/q/addressbalance/${address}`);
        const balanceSatoshi = parseInt(response.data);
        const balanceBtc = balanceSatoshi / 1e8;
        return balanceBtc.toFixed(8);
      } catch (e) {
        return 'Error';
      }
    }

    return 'N/A';
  }

  async getPrice(symbol) {
    try {
      const response = await axios.get(`https://api.coingecko.com/api/v3/simple/price?ids=${this.getCoinGeckoId(symbol)}&vs_currencies=usd`);
      const id = this.getCoinGeckoId(symbol);
      if (response.data[id] && response.data[id].usd) {
        return response.data[id].usd;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  getCoinGeckoId(symbol) {
    const mapping = {
      'ETH': 'ethereum',
      'BTC': 'bitcoin',
      'SOL': 'solana',
      'MATIC': 'matic-network'
    };
    return mapping[symbol] || symbol.toLowerCase();
  }

  async getTransactionCount(chain, address) {
    const config = SUPPORTED_CHAINS[chain];

    if (chain === 'ethereum' || chain === 'polygon') {
      try {
        const response = await axios.post(config.rpc, {
          jsonrpc: '2.0',
          method: 'eth_getTransactionCount',
          params: [address, 'latest'],
          id: 1
        }, {
          headers: { 'Content-Type': 'application/json' }
        });

        if (response.data.result) {
          return parseInt(response.data.result, 16);
        }
      } catch (e) {
        return 'Error';
      }
    }

    return 'N/A';
  }
}

export async function cryptoCommand(options) {
  const wallet = new CryptoWallet();
  await wallet.ensureWalletFile();

  // List supported chains
  if (options.chains) {
    console.log(chalk.hex('#FF6B00').bold('\n  ₿ Supported Blockchains\n'));

    const table = new Table({
      head: [chalk.gray('Chain'), chalk.gray('Symbol'), chalk.gray('Explorer'), chalk.gray('RPC')],
      style: { head: [], border: ['gray'] }
    });

    Object.entries(SUPPORTED_CHAINS).forEach(([key, chain]) => {
      table.push([
        chalk.hex(chain.color)(chain.name),
        chain.symbol,
        chain.explorer,
        chain.rpc ? '✅' : '❌'
      ]);
    });

    console.log(table.toString());
    console.log();
    return;
  }

  // Add wallet
  if (options.add) {
    const answers = await inquirer.prompt([
      {
        type: 'input',
        name: 'name',
        message: 'Wallet name:',
        validate: (input) => input ? true : 'Name is required'
      },
      {
        type: 'list',
        name: 'chain',
        message: 'Blockchain:',
        choices: Object.entries(SUPPORTED_CHAINS).map(([key, chain]) => ({
          name: `${chain.name} (${chain.symbol})`,
          value: key
        }))
      },
      {
        type: 'input',
        name: 'address',
        message: 'Wallet address:',
        validate: (input) => input ? true : 'Address is required'
      }
    ]);

    const spinner = ora('Adding wallet...').start();

    try {
      await wallet.addWallet(answers.name, answers.chain, answers.address);
      spinner.succeed(chalk.green(`✅ Wallet "${answers.name}" added`));
      console.log();
    } catch (e) {
      spinner.fail(chalk.red('Failed to add wallet'));
      console.log(chalk.red(`  ❌ ${e.message}\n`));
    }
    return;
  }

  // Remove wallet
  if (options.remove) {
    const walletNames = Object.keys(wallet.wallets);

    if (walletNames.length === 0) {
      console.log(chalk.yellow('\n  No wallets found.\n'));
      return;
    }

    const { selected } = await inquirer.prompt([
      {
        type: 'list',
        name: 'selected',
        message: 'Select wallet to remove:',
        choices: walletNames
      }
    ]);

    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: `Remove wallet "${selected}"?`,
        default: false
      }
    ]);

    if (!confirm) {
      console.log(chalk.yellow('\n  Cancelled.\n'));
      return;
    }

    await wallet.removeWallet(selected);
    console.log(chalk.green(`\n  ✅ Wallet "${selected}" removed\n`));
    return;
  }

  // List wallets
  if (options.list) {
    const walletNames = Object.keys(wallet.wallets);

    if (walletNames.length === 0) {
      console.log(chalk.yellow('\n  No wallets found.\n'));
      console.log(chalk.gray('  Add a wallet with: br crypto --add\n'));
      return;
    }

    console.log(chalk.hex('#FF6B00').bold('\n  💼 Your Wallets\n'));

    const table = new Table({
      head: [chalk.gray('Name'), chalk.gray('Chain'), chalk.gray('Address'), chalk.gray('Added')],
      style: { head: [], border: ['gray'] }
    });

    walletNames.forEach(name => {
      const w = wallet.wallets[name];
      const chain = SUPPORTED_CHAINS[w.chain];
      const shortAddr = w.address.length > 20
        ? `${w.address.substring(0, 10)}...${w.address.substring(w.address.length - 8)}`
        : w.address;

      table.push([
        chalk.cyan(name),
        chalk.hex(chain.color)(chain.name),
        shortAddr,
        new Date(w.addedAt).toLocaleDateString()
      ]);
    });

    console.log(table.toString());
    console.log(chalk.gray(`\n  Total: ${walletNames.length} wallet(s)\n`));
    return;
  }

  // Show balances
  if (options.balances) {
    const walletNames = Object.keys(wallet.wallets);

    if (walletNames.length === 0) {
      console.log(chalk.yellow('\n  No wallets found.\n'));
      return;
    }

    console.log(chalk.hex('#FF6B00').bold('\n  💰 Wallet Balances\n'));

    const table = new Table({
      head: [chalk.gray('Wallet'), chalk.gray('Chain'), chalk.gray('Balance'), chalk.gray('USD Value'), chalk.gray('Tx Count')],
      style: { head: [], border: ['gray'] }
    });

    for (const name of walletNames) {
      const w = wallet.wallets[name];
      const chain = SUPPORTED_CHAINS[w.chain];

      const spinner = ora(`Fetching ${name}...`).start();

      const balance = await wallet.getBalance(w.chain, w.address);
      const price = await wallet.getPrice(chain.symbol);
      const txCount = await wallet.getTransactionCount(w.chain, w.address);

      spinner.stop();

      const usdValue = price && balance !== 'Error'
        ? `$${(parseFloat(balance) * price).toFixed(2)}`
        : 'N/A';

      table.push([
        chalk.cyan(name),
        chalk.hex(chain.color)(chain.symbol),
        `${balance} ${chain.symbol}`,
        chalk.green(usdValue),
        txCount
      ]);
    }

    console.log(table.toString());
    console.log();
    return;
  }

  // View wallet details
  if (options.view) {
    const walletNames = Object.keys(wallet.wallets);

    if (walletNames.length === 0) {
      console.log(chalk.yellow('\n  No wallets found.\n'));
      return;
    }

    const { selected } = await inquirer.prompt([
      {
        type: 'list',
        name: 'selected',
        message: 'Select wallet:',
        choices: walletNames
      }
    ]);

    const w = wallet.wallets[selected];
    const chain = SUPPORTED_CHAINS[w.chain];

    console.log(chalk.hex('#FF6B00').bold(`\n  💼 ${selected}\n`));

    const spinner = ora('Fetching wallet details...').start();

    const balance = await wallet.getBalance(w.chain, w.address);
    const price = await wallet.getPrice(chain.symbol);
    const txCount = await wallet.getTransactionCount(w.chain, w.address);

    spinner.stop();

    const table = new Table({
      head: [chalk.gray('Property'), chalk.gray('Value')],
      style: { head: [], border: ['gray'] }
    });

    const usdValue = price && balance !== 'Error'
      ? `$${(parseFloat(balance) * price).toFixed(2)}`
      : 'N/A';

    table.push(
      ['Chain', chalk.hex(chain.color)(chain.name)],
      ['Symbol', chain.symbol],
      ['Address', chalk.cyan(w.address)],
      ['Balance', `${balance} ${chain.symbol}`],
      ['USD Value', chalk.green(usdValue)],
      ['Current Price', price ? `$${price}` : 'N/A'],
      ['Transactions', txCount],
      ['Added', new Date(w.addedAt).toLocaleString()],
      ['Explorer', `${chain.explorer}/address/${w.address}`]
    );

    console.log(table.toString());
    console.log();
    return;
  }

  // Get prices
  if (options.prices) {
    console.log(chalk.hex('#FF6B00').bold('\n  📈 Cryptocurrency Prices\n'));

    const table = new Table({
      head: [chalk.gray('Cryptocurrency'), chalk.gray('Symbol'), chalk.gray('USD Price')],
      style: { head: [], border: ['gray'] }
    });

    for (const [key, chain] of Object.entries(SUPPORTED_CHAINS)) {
      const spinner = ora(`Fetching ${chain.name} price...`).start();
      const price = await wallet.getPrice(chain.symbol);
      spinner.stop();

      table.push([
        chalk.hex(chain.color)(chain.name),
        chain.symbol,
        price ? chalk.green(`$${price.toLocaleString()}`) : chalk.gray('N/A')
      ]);
    }

    console.log(table.toString());
    console.log();
    return;
  }

  // Default: show overview
  console.log(chalk.hex('#FF6B00').bold('\n  ₿ Crypto Wallet Management\n'));

  const table = new Table({
    head: [chalk.gray('Command'), chalk.gray('Description')],
    style: { head: [], border: ['gray'] }
  });

  table.push(
    ['--chains', 'List supported blockchains'],
    ['--add', 'Add a wallet'],
    ['--list', 'List all wallets'],
    ['--balances', 'Show wallet balances'],
    ['--view', 'View wallet details'],
    ['--remove', 'Remove a wallet'],
    ['--prices', 'Show current crypto prices']
  );

  console.log(table.toString());
  console.log();

  console.log(chalk.gray('  💡 Examples:'));
  console.log(chalk.gray('    br crypto --chains'));
  console.log(chalk.gray('    br crypto --add'));
  console.log(chalk.gray('    br crypto --balances'));
  console.log(chalk.gray('    br crypto --prices'));
  console.log();

  console.log(chalk.yellow('  ⚠️  Note: This tool tracks wallet addresses only.'));
  console.log(chalk.yellow('  Private keys are NEVER stored or accessed.\n'));
}
