import { FeatureFlagService } from '../src/client';

describe('FeatureFlagService', () => {
  let service: FeatureFlagService;

  beforeEach(() => {
    service = new FeatureFlagService();
  });

  test('should initialize with config', async () => {
    await service.init({ endpoint: 'http://localhost', timeout: 5000 });
    expect(await service.health()).toBe(true);
  });

  test('should return false when not initialized', async () => {
    expect(await service.health()).toBe(false);
  });
});
