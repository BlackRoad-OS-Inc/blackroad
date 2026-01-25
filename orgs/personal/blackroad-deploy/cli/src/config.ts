import fs from 'fs-extra';
import path from 'path';
import os from 'os';

const CONFIG_DIR = path.join(os.homedir(), '.blackroad');
const CONFIG_FILE = path.join(CONFIG_DIR, 'config.json');

export interface Config {
  apiUrl: string;
  apiKey?: string;
  email?: string;
}

export async function loadConfig(): Promise<Config> {
  try {
    await fs.ensureDir(CONFIG_DIR);

    if (await fs.pathExists(CONFIG_FILE)) {
      return await fs.readJson(CONFIG_FILE);
    }

    // Default config
    const defaultConfig: Config = {
      apiUrl: process.env.BLACKROAD_API_URL || 'https://deploy-api.blackroad.systems',
    };

    await fs.writeJson(CONFIG_FILE, defaultConfig, { spaces: 2 });
    return defaultConfig;
  } catch (err) {
    throw new Error(`Failed to load config: ${err}`);
  }
}

export async function saveConfig(config: Config): Promise<void> {
  try {
    await fs.ensureDir(CONFIG_DIR);
    await fs.writeJson(CONFIG_FILE, config, { spaces: 2 });
  } catch (err) {
    throw new Error(`Failed to save config: ${err}`);
  }
}

export async function getApiKey(): Promise<string> {
  const config = await loadConfig();

  if (!config.apiKey) {
    throw new Error('Not logged in. Run: blackroad login');
  }

  return config.apiKey;
}
