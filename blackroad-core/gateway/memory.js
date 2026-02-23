'use strict'

/**
 * BlackRoad Gateway Memory System
 * PS-SHA∞ hash-chain journal for gateway interactions
 */

const crypto = require('crypto')
const fs = require('fs/promises')
const path = require('path')

const MEMORY_DIR = path.join(process.env.HOME || '/tmp', '.blackroad', 'gateway-memory')
const JOURNAL_PATH = path.join(MEMORY_DIR, 'journal.jsonl')
const CONTEXT_PATH = path.join(MEMORY_DIR, 'context.json')

class GatewayMemory {
  constructor() {
    this.lastHash = 'GENESIS'
    this.context = {}
    this.sessionCounts = new Map()
    this._initialized = false
  }

  async init() {
    if (this._initialized) return
    try {
      await fs.mkdir(MEMORY_DIR, { recursive: true })
      // Load last hash from journal tail
      try {
        const journal = await fs.readFile(JOURNAL_PATH, 'utf8')
        const lines = journal.trim().split('\n').filter(Boolean)
        if (lines.length > 0) {
          const last = JSON.parse(lines[lines.length - 1])
          this.lastHash = last.hash
        }
      } catch { /* first run */ }
      // Load context
      try {
        const ctx = await fs.readFile(CONTEXT_PATH, 'utf8')
        this.context = JSON.parse(ctx)
      } catch { /* first run */ }
      this._initialized = true
    } catch (err) {
      console.error('[memory] init error:', err.message)
    }
  }

  _hash(data) {
    return crypto
      .createHash('sha256')
      .update(this.lastHash + JSON.stringify(data))
      .digest('hex')
      .slice(0, 16)
  }

  async record(entry) {
    await this.init()
    const record = {
      ts: new Date().toISOString(),
      prev: this.lastHash,
      ...entry
    }
    record.hash = this._hash(record)
    this.lastHash = record.hash

    // Track session counts
    if (entry.agent) {
      const count = (this.sessionCounts.get(entry.agent) || 0) + 1
      this.sessionCounts.set(entry.agent, count)
    }

    try {
      await fs.appendFile(JOURNAL_PATH, JSON.stringify(record) + '\n')
    } catch { /* non-fatal */ }
    return record.hash
  }

  async updateContext(key, value) {
    await this.init()
    this.context[key] = { value, updated: new Date().toISOString() }
    try {
      await fs.writeFile(CONTEXT_PATH, JSON.stringify(this.context, null, 2))
    } catch { /* non-fatal */ }
  }

  async getContext(key) {
    await this.init()
    return this.context[key]?.value ?? null
  }

  async stats() {
    await this.init()
    let lineCount = 0
    try {
      const journal = await fs.readFile(JOURNAL_PATH, 'utf8')
      lineCount = journal.trim().split('\n').filter(Boolean).length
    } catch { /* empty */ }
    return {
      journal_entries: lineCount,
      last_hash: this.lastHash,
      context_keys: Object.keys(this.context).length,
      session_calls: Object.fromEntries(this.sessionCounts),
      total_session_calls: [...this.sessionCounts.values()].reduce((a, b) => a + b, 0)
    }
  }

  async recent(limit = 10) {
    await this.init()
    try {
      const journal = await fs.readFile(JOURNAL_PATH, 'utf8')
      const lines = journal.trim().split('\n').filter(Boolean)
      return lines.slice(-limit).map(l => JSON.parse(l)).reverse()
    } catch { return [] }
  }
}

module.exports = new GatewayMemory()
