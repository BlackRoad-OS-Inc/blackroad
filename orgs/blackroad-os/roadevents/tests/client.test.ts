import { EventService } from '../src/client';
describe('EventService', () => {
  test('should initialize', async () => {
    const svc = new EventService();
    await svc.init({ endpoint: 'http://localhost', timeout: 5000 });
    expect(await svc.health()).toBe(true);
  });
});
