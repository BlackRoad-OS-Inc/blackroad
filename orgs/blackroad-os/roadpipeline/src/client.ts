import { PipelineConfig, PipelineResponse } from './types';
export class PipelineService {
  private config: PipelineConfig | null = null;
  async init(config: PipelineConfig): Promise<void> { this.config = config; }
  async health(): Promise<boolean> { return this.config !== null; }
}
export default new PipelineService();
