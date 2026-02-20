// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { describe, it, expect } from 'vitest'
import { brand } from '../../src/formatters/brand.js'

describe('brand', () => {
  it('should have color functions', () => {
    expect(typeof brand.hotPink).toBe('function')
    expect(typeof brand.amber).toBe('function')
    expect(typeof brand.violet).toBe('function')
    expect(typeof brand.electricBlue).toBe('function')
  })

  it('should produce a logo string', () => {
    const logo = brand.logo()
    expect(logo).toBeTruthy()
    expect(typeof logo).toBe('string')
  })

  it('should produce a header string', () => {
    const header = brand.header('Test')
    expect(header).toContain('Test')
  })
})
