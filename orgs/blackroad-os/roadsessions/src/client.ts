import { SessionConfig, SessionResponse } from './types';

export class SessionService {
  private config: SessionConfig | null = null;
  
  async init(config: SessionConfig): Promise<void> {
    this.config = config;
  }
  
  async health(): Promise<boolean> {
    return this.config !== null;
  }
}

export default new SessionService();
