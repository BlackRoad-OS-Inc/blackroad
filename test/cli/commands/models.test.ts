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

import { modelsCommand } from '../../../src/cli/commands/models.js'
import { logger } from '../../../src/core/logger.js'

describe('models command', () => {
  afterEach(() => {
    vi.clearAllMocks()
  })

  it('should be named "models"', () => {
    expect(modelsCommand.name()).toBe('models')
  })

  it('should display nodes and model counts', async () => {
    mockGet.mockResolvedValue({
      nodes: [
        { node: 'cecilia', status: 'up', models: ['qwen2.5:7b', 'llama3.2:3b'] },
        { node: 'octavia', status: 'down', models: [] },
      ],
    })
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {})

    await modelsCommand.parseAsync([], { from: 'user' })

    const allOutput = spy.mock.calls.map((c) => c.join(' ')).join('\n')
    expect(allOutput).toContain('cecilia')
    expect(allOutput).toContain('octavia')
    expect(allOutput).toContain('2 models')
    expect(allOutput).toContain('0 models')
    spy.mockRestore()
  })

  it('should output JSON when --json flag is used', async () => {
    const nodesData = [
      { node: 'alice', status: 'up', models: ['mistral:7b'] },
    ]
    mockGet.mockResolvedValue({ nodes: nodesData })
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {})

    await modelsCommand.parseAsync(['--json'], { from: 'user' })

    expect(spy).toHaveBeenCalledWith(JSON.stringify(nodesData, null, 2))
    spy.mockRestore()
  })

  it('should show total model count across nodes', async () => {
    mockGet.mockResolvedValue({
      nodes: [
        { node: 'a', status: 'up', models: ['m1', 'm2'] },
        { node: 'b', status: 'up', models: ['m3'] },
      ],
    })
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {})

    await modelsCommand.parseAsync([], { from: 'user' })

    const allOutput = spy.mock.calls.map((c) => c.join(' ')).join('\n')
    // Summary line: "3 models across 2 nodes"
    expect(allOutput).toContain('3')
    expect(allOutput).toContain('2')
    spy.mockRestore()
  })

  it('should log error when gateway fails', async () => {
    mockGet.mockRejectedValue(new Error('connection refused'))

    await modelsCommand.parseAsync([], { from: 'user' })

    expect(logger.error).toHaveBeenCalledWith(
      expect.stringContaining('Failed to fetch models'),
    )
  })
})
