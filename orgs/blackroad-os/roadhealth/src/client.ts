import { HealthConfig, HealthResponse } from './types';

export class HealthService {
  private config: HealthConfig | null = null;
  
  async init(config: HealthConfig): Promise<void> {
    this.config = config;
  }
  
  async health(): Promise<boolean> {
    return this.config !== null;
  }
}

export default new HealthService();
