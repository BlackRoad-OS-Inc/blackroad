import { Pool, QueryResult } from 'pg';

class Database {
  private pool: Pool | null = null;

  async initialize() {
    this.pool = new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432'),
      database: process.env.DB_NAME || 'blackroad_deploy',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD,
    });

    // Test connection
    await this.pool.query('SELECT NOW()');
    console.log('✅ Database connected');

    // Run migrations
    await this.runMigrations();
  }

  async runMigrations() {
    if (!this.pool) throw new Error('Database not initialized');

    // Create deployments table
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS deployments (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) UNIQUE NOT NULL,
        image VARCHAR(512) NOT NULL,
        container_id VARCHAR(255),
        status VARCHAR(50) DEFAULT 'pending',
        port INTEGER,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);

    // Create environment_variables table
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS environment_variables (
        id SERIAL PRIMARY KEY,
        deployment_id INTEGER REFERENCES deployments(id) ON DELETE CASCADE,
        key VARCHAR(255) NOT NULL,
        value TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(deployment_id, key)
      )
    `);

    // Create deployment_logs table
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS deployment_logs (
        id SERIAL PRIMARY KEY,
        deployment_id INTEGER REFERENCES deployments(id) ON DELETE CASCADE,
        timestamp TIMESTAMP DEFAULT NOW(),
        level VARCHAR(20) DEFAULT 'info',
        message TEXT NOT NULL
      )
    `);

    // Create domains table
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS domains (
        id SERIAL PRIMARY KEY,
        deployment_id INTEGER REFERENCES deployments(id) ON DELETE CASCADE,
        domain VARCHAR(255) UNIQUE NOT NULL,
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      )
    `);

    // Create users table
    await this.pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        api_key VARCHAR(255) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);

    console.log('✅ Database migrations completed');
  }

  async query(text: string, params?: any[]): Promise<QueryResult> {
    if (!this.pool) throw new Error('Database not initialized');
    return this.pool.query(text, params);
  }

  async close() {
    if (this.pool) {
      await this.pool.end();
      console.log('Database connection closed');
    }
  }
}

export const db = new Database();
