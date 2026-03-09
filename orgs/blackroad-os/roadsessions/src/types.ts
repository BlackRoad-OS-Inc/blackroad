export interface SessionConfig {
  endpoint: string;
  timeout: number;
}
export interface SessionResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
