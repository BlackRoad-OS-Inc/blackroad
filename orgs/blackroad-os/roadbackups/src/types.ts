export interface BackupConfig {
  endpoint: string;
  timeout: number;
}
export interface BackupResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
