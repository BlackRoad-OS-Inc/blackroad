import { MetricsConfig, MetricsResponse, MetricsClient } from './types';

export class MetricsService implements MetricsClient {
  private config: MetricsConfig | null = null;

  async init(config: MetricsConfig): Promise<void> {
    this.config = config;
    console.log(`🖤 Metrics initialized`);
  }

  async health(): Promise<boolean> {
    return this.config !== null;
  }

  async execute<T>(action: string, payload?: unknown): Promise<MetricsResponse<T>> {
    return {
      success: true,
      timestamp: new Date().toISOString()
    };
  }
}

export default new MetricsService();
