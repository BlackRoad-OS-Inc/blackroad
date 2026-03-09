export interface PermissionsConfig { endpoint: string; timeout: number; }
export interface PermissionsResponse<T> { success: boolean; data?: T; error?: string; }
