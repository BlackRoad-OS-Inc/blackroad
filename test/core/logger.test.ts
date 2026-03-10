// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { describe, it, expect, vi, afterEach } from 'vitest'
import { logger } from '../../src/core/logger.js'

describe('logger', () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('info() logs to console.log', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {})
    logger.info('test message')
    expect(spy).toHaveBeenCalledOnce()
    const output = spy.mock.calls[0].join(' ')
    expect(output).toContain('test message')
  })

  it('success() logs to console.log', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {})
    logger.success('deployed')
    expect(spy).toHaveBeenCalledOnce()
    const output = spy.mock.calls[0].join(' ')
    expect(output).toContain('deployed')
  })

  it('warn() logs to console.log', () => {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {})
    logger.warn('careful')
    expect(spy).toHaveBeenCalledOnce()
    const output = spy.mock.calls[0].join(' ')
    expect(output).toContain('careful')
  })

  it('error() logs to console.error', () => {
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {})
    logger.error('something broke')
    expect(spy).toHaveBeenCalledOnce()
    const output = spy.mock.calls[0].join(' ')
    expect(output).toContain('something broke')
  })

  describe('debug()', () => {
    it('does not log when DEBUG env is not set', () => {
      const original = process.env['DEBUG']
      delete process.env['DEBUG']
      const spy = vi.spyOn(console, 'log').mockImplementation(() => {})
      logger.debug('hidden')
      expect(spy).not.toHaveBeenCalled()
      if (original !== undefined) process.env['DEBUG'] = original
    })

    it('logs when DEBUG env is set', () => {
      const original = process.env['DEBUG']
      process.env['DEBUG'] = '1'
      const spy = vi.spyOn(console, 'log').mockImplementation(() => {})
      logger.debug('visible')
      expect(spy).toHaveBeenCalledOnce()
      const output = spy.mock.calls[0].join(' ')
      expect(output).toContain('visible')
      if (original !== undefined) {
        process.env['DEBUG'] = original
      } else {
        delete process.env['DEBUG']
      }
    })
  })
})
