// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { describe, it, expect } from 'vitest'
import { loadConfig } from '../../src/core/config.js'

describe('loadConfig', () => {
  it('should return a config with defaults', () => {
    const config = loadConfig()
    expect(config.get('gatewayUrl')).toBe('http://127.0.0.1:8787')
    expect(config.get('defaultAgent')).toBe('octavia')
    expect(config.get('logLevel')).toBe('info')
  })
})
