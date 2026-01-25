import { Router, Response } from 'express';
import { db } from '../db';
import { AuthRequest } from '../middleware/auth';

export const envRouter = Router();

// Get environment variables for a deployment
envRouter.get('/:name', async (req: AuthRequest, res: Response) => {
  try {
    const { name } = req.params;

    const deploymentResult = await db.query(
      'SELECT id FROM deployments WHERE name = $1',
      [name]
    );

    if (deploymentResult.rows.length === 0) {
      return res.status(404).json({ error: 'Deployment not found' });
    }

    const result = await db.query(
      'SELECT key, value FROM environment_variables WHERE deployment_id = $1',
      [deploymentResult.rows[0].id]
    );

    const env: Record<string, string> = {};
    result.rows.forEach((row) => {
      env[row.key] = row.value;
    });

    res.json({ env });
  } catch (err) {
    console.error('Get env error:', err);
    res.status(500).json({ error: 'Failed to get environment variables' });
  }
});

// Set environment variable
envRouter.post('/:name', async (req: AuthRequest, res: Response) => {
  try {
    const { name } = req.params;
    const { key, value } = req.body;

    if (!key || value === undefined) {
      return res.status(400).json({ error: 'Key and value required' });
    }

    const deploymentResult = await db.query(
      'SELECT id FROM deployments WHERE name = $1',
      [name]
    );

    if (deploymentResult.rows.length === 0) {
      return res.status(404).json({ error: 'Deployment not found' });
    }

    await db.query(
      `INSERT INTO environment_variables (deployment_id, key, value)
       VALUES ($1, $2, $3)
       ON CONFLICT (deployment_id, key)
       DO UPDATE SET value = $3`,
      [deploymentResult.rows[0].id, key, value]
    );

    res.json({ message: 'Environment variable set successfully' });
  } catch (err) {
    console.error('Set env error:', err);
    res.status(500).json({ error: 'Failed to set environment variable' });
  }
});

// Delete environment variable
envRouter.delete('/:name/:key', async (req: AuthRequest, res: Response) => {
  try {
    const { name, key } = req.params;

    const deploymentResult = await db.query(
      'SELECT id FROM deployments WHERE name = $1',
      [name]
    );

    if (deploymentResult.rows.length === 0) {
      return res.status(404).json({ error: 'Deployment not found' });
    }

    await db.query(
      'DELETE FROM environment_variables WHERE deployment_id = $1 AND key = $2',
      [deploymentResult.rows[0].id, key]
    );

    res.json({ message: 'Environment variable deleted successfully' });
  } catch (err) {
    console.error('Delete env error:', err);
    res.status(500).json({ error: 'Failed to delete environment variable' });
  }
});
