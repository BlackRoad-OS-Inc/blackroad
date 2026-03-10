// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { describe, it, expect, vi, afterEach } from 'vitest'

const mockGet = vi.fn()

vi.mock('../../../src/core/client.js', () => ({
  GatewayClient: class {
    get = mockGet
  },
}))

vi.mock('../../../src/core/logger.js', () => ({
  logger: {
    info: vi.fn(),
    success: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
    debug: vi.fn(),
  },
}))

import { statusCommand } from '../../../src/cli/commands/status.js'
import { logger } from '../../../src/core/logger.js'

describe('status command', () => {
  afterEach(() => {
    vi.clearAllMocks()
  })

  it('should be named "status"', () => {
    expect(statusCommand.name()).toBe('status')
  })

  it('should log success with health and agent count on success', async () => {
    mockGet
      .mockResolvedValueOnce({ status: 'healthy', version: '1.0.0', uptime: 123.456 })
      .mockResolvedValueOnce({ agents: [{ name: 'alice' }, { name: 'octavia' }] })

    await statusCommand.parseAsync([], { from: 'user' })

    expect(logger.success).toHaveBeenCalledWith(
      expect.stringContaining('healthy'),
    )
    expect(logger.success).toHaveBeenCalledWith(
      expect.stringContaining('v1.0.0'),
    )
    expect(logger.info).toHaveBeenCalledWith(
      expect.stringContaining('2 registered'),
    )
  })

  it('should round uptime seconds', async () => {
    mockGet
      .mockResolvedValueOnce({ status: 'healthy', version: '2.0.0', uptime: 99.7 })
      .mockResolvedValueOnce({ agents: [] })

    await statusCommand.parseAsync([], { from: 'user' })

    expect(logger.success).toHaveBeenCalledWith(
      expect.stringContaining('100s'),
    )
  })

  it('should log error when gateway is unreachable', async () => {
    mockGet.mockRejectedValue(new Error('ECONNREFUSED'))

    await statusCommand.parseAsync([], { from: 'user' })

    expect(logger.error).toHaveBeenCalledWith(
      expect.stringContaining('unreachable'),
    )
  })
})
