import { FilesService } from '../src/client';
describe('FilesService', () => {
  test('should initialize', async () => {
    const svc = new FilesService();
    await svc.init({ endpoint: 'http://localhost', timeout: 5000 });
    expect(await svc.health()).toBe(true);
  });
});
