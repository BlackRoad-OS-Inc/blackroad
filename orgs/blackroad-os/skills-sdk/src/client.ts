import { SDKConfig } from './types';

export class BlackRoadClient {
  private config: SDKConfig;

  constructor(config: SDKConfig) {
    this.config = {
      timeout: 30000,
      ...config
    };
  }

  async fetch(path: string, options: RequestInit = {}): Promise<any> {
    const url = `${this.config.baseUrl}${path}`;
    const response = await fetch(url, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        'X-Agent-ID': this.config.agentId,
        ...options.headers
      }
    });

    if (!response.ok) {
      throw new Error(`API Error: ${response.status} ${response.statusText}`);
    }

    return response.json();
  }

  get agentId(): string {
    return this.config.agentId;
  }
}
