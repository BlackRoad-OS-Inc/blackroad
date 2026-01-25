import { Router, Response } from 'express';
import Docker from 'dockerode';
import { db } from '../db';
import { AuthRequest } from '../middleware/auth';

export const deploymentRouter = Router();
const docker = new Docker();

// List all deployments
deploymentRouter.get('/', async (req: AuthRequest, res: Response) => {
  try {
    const result = await db.query(
      'SELECT id, name, image, status, port, created_at, updated_at FROM deployments ORDER BY created_at DESC'
    );

    res.json({ deployments: result.rows });
  } catch (err) {
    console.error('List deployments error:', err);
    res.status(500).json({ error: 'Failed to list deployments' });
  }
});

// Get deployment by name
deploymentRouter.get('/:name', async (req: AuthRequest, res: Response) => {
  try {
    const { name } = req.params;

    const result = await db.query(
      'SELECT * FROM deployments WHERE name = $1',
      [name]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Deployment not found' });
    }

    // Get environment variables
    const envResult = await db.query(
      'SELECT key, value FROM environment_variables WHERE deployment_id = $1',
      [result.rows[0].id]
    );

    // Get domains
    const domainsResult = await db.query(
      'SELECT domain, status FROM domains WHERE deployment_id = $1',
      [result.rows[0].id]
    );

    res.json({
      deployment: result.rows[0],
      env: envResult.rows,
      domains: domainsResult.rows,
    });
  } catch (err) {
    console.error('Get deployment error:', err);
    res.status(500).json({ error: 'Failed to get deployment' });
  }
});

// Create deployment
deploymentRouter.post('/', async (req: AuthRequest, res: Response) => {
  try {
    const { name, image, env = {}, port = 3000 } = req.body;

    if (!name || !image) {
      return res.status(400).json({ error: 'Name and image required' });
    }

    // Pull image
    await new Promise((resolve, reject) => {
      docker.pull(image, (err: any, stream: any) => {
        if (err) return reject(err);
        docker.modem.followProgress(stream, (err: any) => {
          if (err) return reject(err);
          resolve(null);
        });
      });
    });

    // Create container
    const container = await docker.createContainer({
      name: `br-${name}`,
      Image: image,
      Env: Object.entries(env).map(([key, value]) => `${key}=${value}`),
      ExposedPorts: {
        [`${port}/tcp`]: {},
      },
      HostConfig: {
        PortBindings: {
          [`${port}/tcp`]: [{ HostPort: '0' }], // Random host port
        },
        RestartPolicy: {
          Name: 'unless-stopped',
        },
      },
    });

    // Start container
    await container.start();

    // Get assigned port
    const containerInfo = await container.inspect();
    const hostPort = containerInfo.NetworkSettings.Ports[`${port}/tcp`]?.[0]?.HostPort;

    // Save deployment
    const result = await db.query(
      'INSERT INTO deployments (name, image, container_id, status, port) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [name, image, container.id, 'running', hostPort]
    );

    const deploymentId = result.rows[0].id;

    // Save environment variables
    for (const [key, value] of Object.entries(env)) {
      await db.query(
        'INSERT INTO environment_variables (deployment_id, key, value) VALUES ($1, $2, $3)',
        [deploymentId, key, value]
      );
    }

    // Create default domain
    const domain = `${name}.blackroad.systems`;
    await db.query(
      'INSERT INTO domains (deployment_id, domain, status) VALUES ($1, $2, $3)',
      [deploymentId, domain, 'pending']
    );

    // Log deployment
    await db.query(
      'INSERT INTO deployment_logs (deployment_id, level, message) VALUES ($1, $2, $3)',
      [deploymentId, 'info', 'Deployment created']
    );

    res.json({
      deployment: result.rows[0],
      domain,
      message: 'Deployment created successfully',
    });
  } catch (err: any) {
    console.error('Create deployment error:', err);

    if (err.code === '23505') {
      return res.status(400).json({ error: 'Deployment name already exists' });
    }

    res.status(500).json({ error: err.message || 'Failed to create deployment' });
  }
});

// Restart deployment
deploymentRouter.post('/:name/restart', async (req: AuthRequest, res: Response) => {
  try {
    const { name } = req.params;

    const result = await db.query(
      'SELECT container_id FROM deployments WHERE name = $1',
      [name]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Deployment not found' });
    }

    const container = docker.getContainer(result.rows[0].container_id);
    await container.restart();

    await db.query(
      'UPDATE deployments SET status = $1, updated_at = NOW() WHERE name = $2',
      ['running', name]
    );

    res.json({ message: 'Deployment restarted successfully' });
  } catch (err) {
    console.error('Restart deployment error:', err);
    res.status(500).json({ error: 'Failed to restart deployment' });
  }
});

// Stop deployment
deploymentRouter.post('/:name/stop', async (req: AuthRequest, res: Response) => {
  try {
    const { name } = req.params;

    const result = await db.query(
      'SELECT container_id FROM deployments WHERE name = $1',
      [name]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Deployment not found' });
    }

    const container = docker.getContainer(result.rows[0].container_id);
    await container.stop();

    await db.query(
      'UPDATE deployments SET status = $1, updated_at = NOW() WHERE name = $2',
      ['stopped', name]
    );

    res.json({ message: 'Deployment stopped successfully' });
  } catch (err) {
    console.error('Stop deployment error:', err);
    res.status(500).json({ error: 'Failed to stop deployment' });
  }
});

// Delete deployment
deploymentRouter.delete('/:name', async (req: AuthRequest, res: Response) => {
  try {
    const { name } = req.params;

    const result = await db.query(
      'SELECT id, container_id FROM deployments WHERE name = $1',
      [name]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Deployment not found' });
    }

    // Stop and remove container
    const container = docker.getContainer(result.rows[0].container_id);
    try {
      await container.stop();
    } catch (err) {
      // Container might already be stopped
    }
    await container.remove();

    // Delete from database (cascades to env vars, logs, domains)
    await db.query('DELETE FROM deployments WHERE id = $1', [result.rows[0].id]);

    res.json({ message: 'Deployment deleted successfully' });
  } catch (err) {
    console.error('Delete deployment error:', err);
    res.status(500).json({ error: 'Failed to delete deployment' });
  }
});
