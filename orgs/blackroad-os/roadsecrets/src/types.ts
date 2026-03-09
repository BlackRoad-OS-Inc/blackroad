export interface SecretsConfig { endpoint: string; timeout: number; }
export interface SecretsResponse<T> { success: boolean; data?: T; error?: string; }
