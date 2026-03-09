export interface TemplateConfig {
  endpoint: string;
  timeout: number;
}
export interface TemplateResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
