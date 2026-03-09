export interface EventConfig {
  endpoint: string;
  timeout: number;
}
export interface EventResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
