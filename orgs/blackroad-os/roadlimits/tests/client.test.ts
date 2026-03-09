import { RateLimitService } from '../src/client';

describe('RateLimitService', () => {
  let service: RateLimitService;

  beforeEach(() => {
    service = new RateLimitService();
  });

  test('should initialize with config', async () => {
    await service.init({ endpoint: 'http://localhost', timeout: 5000 });
    expect(await service.health()).toBe(true);
  });

  test('should return false when not initialized', async () => {
    expect(await service.health()).toBe(false);
  });
});
