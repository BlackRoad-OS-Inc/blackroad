import { TemplateService } from '../src/client';
describe('TemplateService', () => {
  test('should initialize', async () => {
    const svc = new TemplateService();
    await svc.init({ endpoint: 'http://localhost', timeout: 5000 });
    expect(await svc.health()).toBe(true);
  });
});
