import { MigrationConfig, MigrationResponse } from './types';

export class MigrationService {
  private config: MigrationConfig | null = null;
  
  async init(config: MigrationConfig): Promise<void> {
    this.config = config;
  }
  
  async health(): Promise<boolean> {
    return this.config !== null;
  }
}

export default new MigrationService();
