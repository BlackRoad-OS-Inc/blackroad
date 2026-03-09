import { LocalizeConfig, LocalizeResponse } from './types';
export class LocalizeService {
  private config: LocalizeConfig | null = null;
  async init(config: LocalizeConfig): Promise<void> { this.config = config; }
  async health(): Promise<boolean> { return this.config !== null; }
}
export default new LocalizeService();
