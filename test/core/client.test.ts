// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { describe, it, expect, vi } from 'vitest'
import { GatewayClient } from '../../src/core/client.js'

describe('GatewayClient', () => {
  it('should use default base URL', () => {
    const client = new GatewayClient()
    expect(client.baseUrl).toBe('http://127.0.0.1:8787')
  })

  it('should accept custom base URL', () => {
    const client = new GatewayClient('http://custom:9999')
    expect(client.baseUrl).toBe('http://custom:9999')
  })

  it('should throw on non-ok response', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 500, statusText: 'Error' }))
    const client = new GatewayClient()
    await expect(client.get('/v1/health')).rejects.toThrow('GET /v1/health failed: 500 Error')
    vi.unstubAllGlobals()
  })

  it('should return parsed JSON on success', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ status: 'healthy' }),
    }))
    const client = new GatewayClient()
    const result = await client.get<{ status: string }>('/v1/health')
    expect(result.status).toBe('healthy')
    vi.unstubAllGlobals()
  })
})
