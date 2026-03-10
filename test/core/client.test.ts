// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { describe, it, expect, vi, afterEach } from 'vitest'
import { GatewayClient } from '../../src/core/client.js'

describe('GatewayClient', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  describe('constructor', () => {
    it('should use default base URL', () => {
      const client = new GatewayClient()
      expect(client.baseUrl).toBe('http://127.0.0.1:8787')
    })

    it('should accept custom base URL', () => {
      const client = new GatewayClient('http://custom:9999')
      expect(client.baseUrl).toBe('http://custom:9999')
    })

    it('should read BLACKROAD_GATEWAY_URL from env when no arg given', () => {
      const original = process.env['BLACKROAD_GATEWAY_URL']
      process.env['BLACKROAD_GATEWAY_URL'] = 'http://env-gateway:5000'
      const client = new GatewayClient()
      expect(client.baseUrl).toBe('http://env-gateway:5000')
      if (original !== undefined) {
        process.env['BLACKROAD_GATEWAY_URL'] = original
      } else {
        delete process.env['BLACKROAD_GATEWAY_URL']
      }
    })

    it('should prefer explicit arg over env var', () => {
      const original = process.env['BLACKROAD_GATEWAY_URL']
      process.env['BLACKROAD_GATEWAY_URL'] = 'http://env-gateway:5000'
      const client = new GatewayClient('http://explicit:3000')
      expect(client.baseUrl).toBe('http://explicit:3000')
      if (original !== undefined) {
        process.env['BLACKROAD_GATEWAY_URL'] = original
      } else {
        delete process.env['BLACKROAD_GATEWAY_URL']
      }
    })
  })

  describe('get()', () => {
    it('should return parsed JSON on success', async () => {
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ status: 'healthy' }),
      }))
      const client = new GatewayClient()
      const result = await client.get<{ status: string }>('/v1/health')
      expect(result.status).toBe('healthy')
    })

    it('should call fetch with the correct full URL', async () => {
      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({}),
      })
      vi.stubGlobal('fetch', mockFetch)
      const client = new GatewayClient('http://test:8787')
      await client.get('/v1/agents')
      expect(mockFetch).toHaveBeenCalledWith('http://test:8787/v1/agents')
    })

    it('should throw on non-ok response with status info', async () => {
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
        ok: false,
        status: 404,
        statusText: 'Not Found',
      }))
      const client = new GatewayClient()
      await expect(client.get('/v1/missing')).rejects.toThrow('GET /v1/missing failed: 404 Not Found')
    })

    it('should throw on 500 server error', async () => {
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error',
      }))
      const client = new GatewayClient()
      await expect(client.get('/v1/health')).rejects.toThrow('500 Internal Server Error')
    })

    it('should propagate network errors from fetch', async () => {
      vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('ECONNREFUSED')))
      const client = new GatewayClient()
      await expect(client.get('/v1/health')).rejects.toThrow('ECONNREFUSED')
    })
  })

  describe('post()', () => {
    it('should send POST with JSON body and correct headers', async () => {
      const mockFetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ content: 'done' }),
      })
      vi.stubGlobal('fetch', mockFetch)
      const client = new GatewayClient('http://test:8787')
      await client.post('/v1/invoke', { agent: 'octavia', task: 'deploy' })

      expect(mockFetch).toHaveBeenCalledWith('http://test:8787/v1/invoke', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ agent: 'octavia', task: 'deploy' }),
      })
    })

    it('should return parsed JSON on success', async () => {
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ content: 'Task completed' }),
      }))
      const client = new GatewayClient()
      const result = await client.post<{ content: string }>('/v1/invoke', { agent: 'alice' })
      expect(result.content).toBe('Task completed')
    })

    it('should throw on non-ok POST response', async () => {
      vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
        ok: false,
        status: 422,
        statusText: 'Unprocessable Entity',
      }))
      const client = new GatewayClient()
      await expect(client.post('/v1/invoke', {})).rejects.toThrow(
        'POST /v1/invoke failed: 422 Unprocessable Entity',
      )
    })

    it('should propagate network errors from fetch', async () => {
      vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('timeout')))
      const client = new GatewayClient()
      await expect(client.post('/v1/invoke', {})).rejects.toThrow('timeout')
    })
  })
})
