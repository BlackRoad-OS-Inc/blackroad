import { WebhookConfig, WebhookResponse } from './types';

export class WebhookService {
  private config: WebhookConfig | null = null;
  
  async init(config: WebhookConfig): Promise<void> {
    this.config = config;
  }
  
  async health(): Promise<boolean> {
    return this.config !== null;
  }
}

export default new WebhookService();
