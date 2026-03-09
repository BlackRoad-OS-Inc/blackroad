export interface MigrationConfig {
  endpoint: string;
  timeout: number;
}
export interface MigrationResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
