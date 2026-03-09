import { BackupService } from '../src/client';
describe('BackupService', () => {
  test('should initialize', async () => {
    const svc = new BackupService();
    await svc.init({ endpoint: 'http://localhost', timeout: 5000 });
    expect(await svc.health()).toBe(true);
  });
});
