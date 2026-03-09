import { SchedulerConfig, SchedulerResponse } from './types';

export class SchedulerService {
  private config: SchedulerConfig | null = null;
  
  async init(config: SchedulerConfig): Promise<void> {
    this.config = config;
  }
  
  async health(): Promise<boolean> {
    return this.config !== null;
  }
}

export default new SchedulerService();
