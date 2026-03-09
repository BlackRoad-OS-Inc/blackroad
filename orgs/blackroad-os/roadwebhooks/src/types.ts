export interface WebhookConfig {
  endpoint: string;
  timeout: number;
}
export interface WebhookResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
