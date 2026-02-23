/**
 * D1 Adapter - PostgreSQL-backed replacement for Cloudflare D1
 *
 * Drop-in replacement for D1Database interface used by Workers.
 * Each D1 database maps to a PostgreSQL database on Cecilia.
 */

import pg from 'pg';
const { Pool } = pg;

const pools: Map<string, pg.Pool> = new Map();

function getPool(dbName: string): pg.Pool {
  if (!pools.has(dbName)) {
    pools.set(dbName, new Pool({
      host: process.env.PG_HOST || '10.10.0.2',
      port: parseInt(process.env.PG_PORT || '5432'),
      database: dbName,
      user: process.env.PG_USER || 'blackroad',
      password: process.env.PG_PASSWORD,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    }));
  }
  return pools.get(dbName)!;
}

export interface D1Result<T = Record<string, unknown>> {
  results: T[];
  success: boolean;
  meta?: {
    duration?: number;
    rows_read?: number;
    rows_written?: number;
  };
}

class D1PreparedStatement {
  private params: unknown[] = [];
  private convertedSql: string;

  constructor(private pool: pg.Pool, private sql: string) {
    this.convertedSql = sql;
  }

  bind(...values: unknown[]): D1PreparedStatement {
    this.params = values;

    // Convert D1/SQLite ? placeholders to PostgreSQL $1, $2, ...
    let idx = 0;
    this.convertedSql = this.sql.replace(/\?/g, () => `$${++idx}`);

    return this;
  }

  async first<T = Record<string, unknown>>(column?: string): Promise<T | null> {
    const start = Date.now();
    try {
      const result = await this.pool.query(this.convertedSql, this.params);
      if (result.rows.length === 0) return null;
      if (column) return result.rows[0][column] as T;
      return result.rows[0] as T;
    } catch (err) {
      console.error(`D1 query error: ${this.convertedSql}`, err);
      return null;
    }
  }

  async all<T = Record<string, unknown>>(): Promise<D1Result<T>> {
    const start = Date.now();
    try {
      const result = await this.pool.query(this.convertedSql, this.params);
      return {
        results: result.rows as T[],
        success: true,
        meta: {
          duration: Date.now() - start,
          rows_read: result.rowCount || 0,
        },
      };
    } catch (err) {
      console.error(`D1 query error: ${this.convertedSql}`, err);
      return { results: [], success: false };
    }
  }

  async run(): Promise<D1Result> {
    const start = Date.now();
    try {
      const result = await this.pool.query(this.convertedSql, this.params);
      return {
        results: [],
        success: true,
        meta: {
          duration: Date.now() - start,
          rows_written: result.rowCount || 0,
        },
      };
    } catch (err) {
      console.error(`D1 query error: ${this.convertedSql}`, err);
      return { results: [], success: false };
    }
  }

  async raw<T = unknown[]>(): Promise<T[]> {
    try {
      const result = await this.pool.query({
        text: this.convertedSql,
        values: this.params,
        rowMode: 'array',
      });
      return result.rows as T[];
    } catch (err) {
      console.error(`D1 raw query error: ${this.convertedSql}`, err);
      return [];
    }
  }
}

export class D1Database {
  private pool: pg.Pool;

  constructor(dbName: string) {
    this.pool = getPool(dbName);
  }

  prepare(sql: string): D1PreparedStatement {
    return new D1PreparedStatement(this.pool, sql);
  }

  async exec(sql: string): Promise<D1Result> {
    try {
      await this.pool.query(sql);
      return { results: [], success: true };
    } catch (err) {
      console.error(`D1 exec error:`, err);
      return { results: [], success: false };
    }
  }

  async batch(statements: D1PreparedStatement[]): Promise<D1Result[]> {
    const results: D1Result[] = [];
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');
      for (const stmt of statements) {
        results.push(await stmt.run());
      }
      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('D1 batch error:', err);
    } finally {
      client.release();
    }
    return results;
  }
}

/** Create D1 databases matching Cloudflare Worker bindings */
export function createD1Databases() {
  return {
    DB: new D1Database('blackroad_os_main'),              // api-gateway, subdomain-router
    REVENUE_D1: new D1Database('blackroad_revenue'),      // payment-gateway
    CONTINUITY: new D1Database('blackroad_continuity'),    // tools-api, agents-api, command-center
    SAAS: new D1Database('blackroad_saas'),                // blackroad-os
    AGENTS_DB: new D1Database('apollo_agent_registry'),    // prism-console
  };
}

export async function closePools(): Promise<void> {
  for (const [name, pool] of pools) {
    await pool.end();
  }
  pools.clear();
}
