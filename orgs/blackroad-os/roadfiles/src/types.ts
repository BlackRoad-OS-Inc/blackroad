export interface FilesConfig { endpoint: string; timeout: number; }
export interface FilesResponse<T> { success: boolean; data?: T; error?: string; }
