import { EventConfig, EventResponse } from './types';

export class EventService {
  private config: EventConfig | null = null;
  
  async init(config: EventConfig): Promise<void> {
    this.config = config;
  }
  
  async health(): Promise<boolean> {
    return this.config !== null;
  }
}

export default new EventService();
