#!/usr/bin/env node
/**
 * 🌐 BlackRoad Domain Registry API
 * Self-hosted domain management and DNS control
 */

const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const axios = require('axios');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8080;

// Database connection (PostgreSQL on lucidia)
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'road_registry',
  user: process.env.DB_USER || 'roaduser',
  password: process.env.DB_PASSWORD || 'blackroad2026',
});

// PowerDNS API configuration
const PDNS_API_URL = process.env.PDNS_API_URL || 'http://localhost:8081/api/v1';
const PDNS_API_KEY = process.env.PDNS_API_KEY || 'blackroad-pdns-api-key-2026';

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'road-registry-api',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// ========================================
// DOMAIN MANAGEMENT ENDPOINTS
// ========================================

// List all domains
app.get('/api/domains', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM domains ORDER BY created_at DESC');
    res.json({
      success: true,
      count: result.rows.length,
      domains: result.rows
    });
  } catch (error) {
    console.error('Error fetching domains:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get single domain
app.get('/api/domains/:domain', async (req, res) => {
  try {
    const { domain } = req.params;
    const result = await pool.query('SELECT * FROM domains WHERE domain = $1', [domain]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Domain not found' });
    }

    // Also fetch DNS records
    const recordsResult = await pool.query(
      'SELECT * FROM dns_records WHERE domain_id = $1 ORDER BY record_type, name',
      [result.rows[0].id]
    );

    res.json({
      success: true,
      domain: {
        ...result.rows[0],
        records: recordsResult.rows
      }
    });
  } catch (error) {
    console.error('Error fetching domain:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create new domain
app.post('/api/domains', async (req, res) => {
  try {
    const { domain, registrar, nameservers, records } = req.body;

    if (!domain) {
      return res.status(400).json({ success: false, error: 'Domain name required' });
    }

    // Insert domain
    const domainId = uuidv4();
    const domainResult = await pool.query(
      `INSERT INTO domains (id, domain, registrar, nameservers, status, owner_email)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        domainId,
        domain,
        registrar || 'self-managed',
        nameservers || ['ns1.blackroad.io', 'ns2.blackroad.io'],
        'active',
        'admin@blackroad.io'
      ]
    );

    // Insert DNS records if provided
    if (records && Array.isArray(records)) {
      for (const record of records) {
        await pool.query(
          `INSERT INTO dns_records (id, domain_id, record_type, name, value, ttl, priority)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            uuidv4(),
            domainId,
            record.type,
            record.name,
            record.value,
            record.ttl || 3600,
            record.priority || null
          ]
        );
      }
    }

    // Create zone in PowerDNS
    try {
      await createPowerDNSZone(domain, nameservers);
    } catch (pdnsError) {
      console.error('PowerDNS zone creation failed:', pdnsError.message);
      // Continue anyway - zone can be created manually
    }

    res.status(201).json({
      success: true,
      message: 'Domain created successfully',
      domain: domainResult.rows[0]
    });
  } catch (error) {
    console.error('Error creating domain:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// DNS RECORD MANAGEMENT
// ========================================

// Get DNS records for domain
app.get('/api/domains/:domain/records', async (req, res) => {
  try {
    const { domain } = req.params;

    // Get domain ID
    const domainResult = await pool.query('SELECT id FROM domains WHERE domain = $1', [domain]);
    if (domainResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Domain not found' });
    }

    const records = await pool.query(
      'SELECT * FROM dns_records WHERE domain_id = $1 ORDER BY record_type, name',
      [domainResult.rows[0].id]
    );

    res.json({
      success: true,
      domain,
      count: records.rows.length,
      records: records.rows
    });
  } catch (error) {
    console.error('Error fetching DNS records:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Add DNS record
app.post('/api/domains/:domain/records', async (req, res) => {
  try {
    const { domain } = req.params;
    const { type, name, value, ttl, priority } = req.body;

    if (!type || !name || !value) {
      return res.status(400).json({
        success: false,
        error: 'type, name, and value are required'
      });
    }

    // Get domain ID
    const domainResult = await pool.query('SELECT id FROM domains WHERE domain = $1', [domain]);
    if (domainResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Domain not found' });
    }

    const recordId = uuidv4();
    const result = await pool.query(
      `INSERT INTO dns_records (id, domain_id, record_type, name, value, ttl, priority)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [recordId, domainResult.rows[0].id, type, name, value, ttl || 3600, priority || null]
    );

    // Sync to PowerDNS
    try {
      await addPowerDNSRecord(domain, type, name, value, ttl);
    } catch (pdnsError) {
      console.error('PowerDNS record sync failed:', pdnsError.message);
    }

    res.status(201).json({
      success: true,
      message: 'DNS record created',
      record: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating DNS record:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Delete DNS record
app.delete('/api/domains/:domain/records/:recordId', async (req, res) => {
  try {
    const { domain, recordId } = req.params;

    const result = await pool.query(
      'DELETE FROM dns_records WHERE id = $1 RETURNING *',
      [recordId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Record not found' });
    }

    res.json({
      success: true,
      message: 'DNS record deleted',
      record: result.rows[0]
    });
  } catch (error) {
    console.error('Error deleting DNS record:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// POWERDNS INTEGRATION
// ========================================

async function createPowerDNSZone(domain, nameservers) {
  const response = await axios.post(
    `${PDNS_API_URL}/servers/localhost/zones`,
    {
      name: `${domain}.`,
      kind: 'Native',
      nameservers: nameservers.map(ns => `${ns}.`)
    },
    {
      headers: { 'X-API-Key': PDNS_API_KEY }
    }
  );
  return response.data;
}

async function addPowerDNSRecord(domain, type, name, value, ttl = 3600) {
  const zoneName = `${domain}.`;
  const recordName = name === '@' ? zoneName : `${name}.${zoneName}`;

  const response = await axios.patch(
    `${PDNS_API_URL}/servers/localhost/zones/${zoneName}`,
    {
      rrsets: [
        {
          name: recordName,
          type: type,
          ttl: ttl,
          changetype: 'REPLACE',
          records: [
            {
              content: value,
              disabled: false
            }
          ]
        }
      ]
    },
    {
      headers: { 'X-API-Key': PDNS_API_KEY }
    }
  );
  return response.data;
}

// Sync PowerDNS zones
app.post('/api/sync/powerdns', async (req, res) => {
  try {
    // Get all zones from PowerDNS
    const response = await axios.get(
      `${PDNS_API_URL}/servers/localhost/zones`,
      { headers: { 'X-API-Key': PDNS_API_KEY } }
    );

    res.json({
      success: true,
      message: 'PowerDNS sync successful',
      zones: response.data
    });
  } catch (error) {
    console.error('PowerDNS sync error:', error.message);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// DEPLOYMENT MANAGEMENT
// ========================================

// List deployments
app.get('/api/deployments', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT d.*, dom.domain
      FROM deployments d
      JOIN domains dom ON d.domain_id = dom.id
      ORDER BY d.deployed_at DESC
      LIMIT 50
    `);

    res.json({
      success: true,
      count: result.rows.length,
      deployments: result.rows
    });
  } catch (error) {
    console.error('Error fetching deployments:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Create deployment
app.post('/api/deployments', async (req, res) => {
  try {
    const { domain, repo_url, branch, build_command, deploy_path } = req.body;

    // Get domain ID
    const domainResult = await pool.query('SELECT id FROM domains WHERE domain = $1', [domain]);
    if (domainResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Domain not found' });
    }

    const deploymentId = uuidv4();
    const result = await pool.query(
      `INSERT INTO deployments (id, domain_id, repo_url, branch, build_command, deploy_path, status, deployed_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
       RETURNING *`,
      [
        deploymentId,
        domainResult.rows[0].id,
        repo_url,
        branch || 'main',
        build_command,
        deploy_path,
        'pending'
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Deployment created',
      deployment: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating deployment:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// ========================================
// START SERVER
// ========================================

app.listen(PORT, () => {
  console.log('🌐 BlackRoad Domain Registry API');
  console.log('================================');
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📡 PowerDNS API: ${PDNS_API_URL}`);
  console.log(`🗄️  Database: ${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 5432}`);
  console.log('');
  console.log('Endpoints:');
  console.log(`  GET  /health`);
  console.log(`  GET  /api/domains`);
  console.log(`  POST /api/domains`);
  console.log(`  GET  /api/domains/:domain`);
  console.log(`  GET  /api/domains/:domain/records`);
  console.log(`  POST /api/domains/:domain/records`);
  console.log(`  GET  /api/deployments`);
  console.log(`  POST /api/deployments`);
  console.log('');
  console.log('🖤🛣️ BlackRoad Domain Registry');
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, closing server...');
  await pool.end();
  process.exit(0);
});
