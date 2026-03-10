// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { describe, it, expect } from 'vitest'
import { formatTable } from '../../src/formatters/table.js'

describe('formatTable', () => {
  it('should format headers and rows with separators', () => {
    const result = formatTable(['Name', 'Role'], [['alice', 'ops'], ['octavia', 'arch']])
    expect(result).toContain('Name')
    expect(result).toContain('Role')
    expect(result).toContain('alice')
    expect(result).toContain('octavia')
    expect(result).toContain('─')
    expect(result).toContain('┼')
  })

  it('should handle empty rows', () => {
    const result = formatTable(['A', 'B'], [])
    const lines = result.split('\n')
    // header + separator, no data rows
    expect(lines).toHaveLength(2)
    expect(result).toContain('A')
    expect(result).toContain('B')
  })

  it('should pad columns to max width', () => {
    const result = formatTable(['X'], [['short'], ['a much longer value']])
    const lines = result.split('\n')
    // All data lines should be the same length
    expect(lines[2].length).toBe(lines[3].length)
  })

  it('should handle single column single row', () => {
    const result = formatTable(['Status'], [['OK']])
    const lines = result.split('\n')
    expect(lines).toHaveLength(3) // header, separator, data
    expect(result).toContain('Status')
    expect(result).toContain('OK')
  })

  it('should handle multiple columns correctly aligned', () => {
    const result = formatTable(
      ['Name', 'Title', 'Role'],
      [
        ['alice', 'The Operator', 'devops'],
        ['octavia', 'The Architect', 'systems'],
      ],
    )
    const lines = result.split('\n')
    // header + sep + 2 data rows
    expect(lines).toHaveLength(4)
    // All rows (except separator) should use | as column separator
    expect(lines[0]).toContain('│')
    expect(lines[2]).toContain('│')
  })

  it('should handle missing cells gracefully', () => {
    // Row with fewer cells than headers
    const result = formatTable(['A', 'B', 'C'], [['x']])
    expect(result).toContain('x')
    // Should not throw
    expect(result).toContain('A')
  })

  it('should produce consistent separator width', () => {
    const result = formatTable(['Col1', 'Col2'], [['a', 'b']])
    const lines = result.split('\n')
    const headerLen = lines[0].length
    const sepLen = lines[1].length
    const rowLen = lines[2].length
    // Header and data rows should be the same width
    expect(headerLen).toBe(rowLen)
    // Separator uses different chars but should span the same columns
    expect(sepLen).toBeGreaterThan(0)
  })
})
