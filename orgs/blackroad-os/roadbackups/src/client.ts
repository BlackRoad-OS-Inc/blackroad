import { BackupConfig, BackupResponse } from './types';

export class BackupService {
  private config: BackupConfig | null = null;
  
  async init(config: BackupConfig): Promise<void> {
    this.config = config;
  }
  
  async health(): Promise<boolean> {
    return this.config !== null;
  }
}

export default new BackupService();
