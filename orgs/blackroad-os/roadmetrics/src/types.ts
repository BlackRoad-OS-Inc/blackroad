export interface MetricsConfig {
  endpoint: string;
  timeout: number;
  retries: number;
}

export interface MetricsResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: string;
}

export interface MetricsClient {
  init(config: MetricsConfig): Promise<void>;
  health(): Promise<boolean>;
}
