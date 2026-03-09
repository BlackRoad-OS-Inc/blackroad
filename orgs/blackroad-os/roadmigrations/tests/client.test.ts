import { MigrationService } from '../src/client';
describe('MigrationService', () => {
  test('should initialize', async () => {
    const svc = new MigrationService();
    await svc.init({ endpoint: 'http://localhost', timeout: 5000 });
    expect(await svc.health()).toBe(true);
  });
});
