import { HealthService } from '../src/client';
describe('HealthService', () => {
  test('should initialize', async () => {
    const svc = new HealthService();
    await svc.init({ endpoint: 'http://localhost', timeout: 5000 });
    expect(await svc.health()).toBe(true);
  });
});
