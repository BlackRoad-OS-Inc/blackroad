export interface RateLimitConfig {
  endpoint: string;
  timeout: number;
  retries: number;
}

export interface RateLimitResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: string;
}

export interface RateLimitClient {
  init(config: RateLimitConfig): Promise<void>;
  health(): Promise<boolean>;
}
