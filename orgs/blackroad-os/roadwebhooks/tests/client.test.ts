import { WebhookService } from '../src/client';
describe('WebhookService', () => {
  test('should initialize', async () => {
    const svc = new WebhookService();
    await svc.init({ endpoint: 'http://localhost', timeout: 5000 });
    expect(await svc.health()).toBe(true);
  });
});
