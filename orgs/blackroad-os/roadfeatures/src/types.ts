export interface FeatureFlagConfig {
  endpoint: string;
  timeout: number;
  retries: number;
}

export interface FeatureFlagResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: string;
}

export interface FeatureFlagClient {
  init(config: FeatureFlagConfig): Promise<void>;
  health(): Promise<boolean>;
}
