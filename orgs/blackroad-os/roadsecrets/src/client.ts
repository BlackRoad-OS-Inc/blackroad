import { SecretsConfig, SecretsResponse } from './types';
export class SecretsService {
  private config: SecretsConfig | null = null;
  async init(config: SecretsConfig): Promise<void> { this.config = config; }
  async health(): Promise<boolean> { return this.config !== null; }
}
export default new SecretsService();
