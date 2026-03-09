import { SessionService } from '../src/client';
describe('SessionService', () => {
  test('should initialize', async () => {
    const svc = new SessionService();
    await svc.init({ endpoint: 'http://localhost', timeout: 5000 });
    expect(await svc.health()).toBe(true);
  });
});
