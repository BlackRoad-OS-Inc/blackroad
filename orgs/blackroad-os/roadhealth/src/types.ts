export interface HealthConfig {
  endpoint: string;
  timeout: number;
}
export interface HealthResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
