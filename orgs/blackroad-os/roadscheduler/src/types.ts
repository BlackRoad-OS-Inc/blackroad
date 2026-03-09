export interface SchedulerConfig {
  endpoint: string;
  timeout: number;
}
export interface SchedulerResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
