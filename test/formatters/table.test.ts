// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { describe, it, expect } from 'vitest'
import { formatTable } from '../../src/formatters/table.js'

describe('formatTable', () => {
  it('should format headers and rows', () => {
    const result = formatTable(['Name', 'Role'], [['alice', 'ops'], ['octavia', 'arch']])
    expect(result).toContain('Name')
    expect(result).toContain('alice')
    expect(result).toContain('octavia')
    expect(result).toContain('─')
  })

  it('should handle empty rows', () => {
    const result = formatTable(['A', 'B'], [])
    expect(result).toContain('A')
    expect(result).toContain('B')
  })

  it('should pad columns to max width', () => {
    const result = formatTable(['X'], [['short'], ['a much longer value']])
    const lines = result.split('\n')
    expect(lines[2].length).toBe(lines[3].length)
  })
})
