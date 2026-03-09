export interface PipelineConfig { endpoint: string; timeout: number; }
export interface PipelineResponse<T> { success: boolean; data?: T; error?: string; }
