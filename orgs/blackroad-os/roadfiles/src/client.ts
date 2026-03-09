import { FilesConfig, FilesResponse } from './types';
export class FilesService {
  private config: FilesConfig | null = null;
  async init(config: FilesConfig): Promise<void> { this.config = config; }
  async health(): Promise<boolean> { return this.config !== null; }
}
export default new FilesService();
