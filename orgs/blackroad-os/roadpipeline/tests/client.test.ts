import { PipelineService } from '../src/client';
describe('PipelineService', () => {
  test('should initialize', async () => {
    const svc = new PipelineService();
    await svc.init({ endpoint: 'http://localhost', timeout: 5000 });
    expect(await svc.health()).toBe(true);
  });
});
