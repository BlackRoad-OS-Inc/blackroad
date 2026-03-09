import { TemplateConfig, TemplateResponse } from './types';

export class TemplateService {
  private config: TemplateConfig | null = null;
  
  async init(config: TemplateConfig): Promise<void> {
    this.config = config;
  }
  
  async health(): Promise<boolean> {
    return this.config !== null;
  }
}

export default new TemplateService();
