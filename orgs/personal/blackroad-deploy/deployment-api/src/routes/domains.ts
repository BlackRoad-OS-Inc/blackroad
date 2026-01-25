import { Router, Response } from 'express';
import { db } from '../db';
import { AuthRequest } from '../middleware/auth';

export const domainsRouter = Router();

// Get domains for a deployment
domainsRouter.get('/:name', async (req: AuthRequest, res: Response) => {
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
      'SELECT domain, status, created_at FROM domains WHERE deployment_id = $1',
      [deploymentResult.rows[0].id]
    );

    res.json({ domains: result.rows });
  } catch (err) {
    console.error('Get domains error:', err);
    res.status(500).json({ error: 'Failed to get domains' });
  }
});

// Add custom domain
domainsRouter.post('/:name', async (req: AuthRequest, res: Response) => {
  try {
    const { name } = req.params;
    const { domain } = req.body;

    if (!domain) {
      return res.status(400).json({ error: 'Domain required' });
    }

    const deploymentResult = await db.query(
      'SELECT id FROM deployments WHERE name = $1',
      [name]
    );

    if (deploymentResult.rows.length === 0) {
      return res.status(404).json({ error: 'Deployment not found' });
    }

    await db.query(
      'INSERT INTO domains (deployment_id, domain, status) VALUES ($1, $2, $3)',
      [deploymentResult.rows[0].id, domain, 'pending']
    );

    res.json({ message: 'Domain added successfully' });
  } catch (err: any) {
    if (err.code === '23505') {
      return res.status(400).json({ error: 'Domain already exists' });
    }
    console.error('Add domain error:', err);
    res.status(500).json({ error: 'Failed to add domain' });
  }
});

// Delete domain
domainsRouter.delete('/:name/:domain', async (req: AuthRequest, res: Response) => {
  try {
    const { name, domain } = req.params;

    const deploymentResult = await db.query(
      'SELECT id FROM deployments WHERE name = $1',
      [name]
    );

    if (deploymentResult.rows.length === 0) {
      return res.status(404).json({ error: 'Deployment not found' });
    }

    await db.query(
      'DELETE FROM domains WHERE deployment_id = $1 AND domain = $2',
      [deploymentResult.rows[0].id, domain]
    );

    res.json({ message: 'Domain deleted successfully' });
  } catch (err) {
    console.error('Delete domain error:', err);
    res.status(500).json({ error: 'Failed to delete domain' });
  }
});
