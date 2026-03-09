import { PermissionsConfig, PermissionsResponse } from './types';
export class PermissionsService {
  private config: PermissionsConfig | null = null;
  async init(config: PermissionsConfig): Promise<void> { this.config = config; }
  async health(): Promise<boolean> { return this.config !== null; }
}
export default new PermissionsService();
