import { SchedulerService } from '../src/client';

describe('SchedulerService', () => {
  let service: SchedulerService;

  beforeEach(() => {
    service = new SchedulerService();
  });

  test('should initialize with config', async () => {
    await service.init({ endpoint: 'http://localhost', timeout: 5000 });
    expect(await service.health()).toBe(true);
  });

  test('should return false when not initialized', async () => {
    expect(await service.health()).toBe(false);
  });
});
