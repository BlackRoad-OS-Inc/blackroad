export interface LocalizeConfig { endpoint: string; timeout: number; }
export interface LocalizeResponse<T> { success: boolean; data?: T; error?: string; }
