import { Router, Response } from 'express';
import Docker from 'dockerode';
import { db } from '../db';
import { AuthRequest } from '../middleware/auth';

export const logsRouter = Router();
const docker = new Docker();

// Get logs for a deployment
logsRouter.get('/:name', async (req: AuthRequest, res: Response) => {
  try {
    const { name } = req.params;
    const { tail = '100', follow = 'false' } = req.query;

    const result = await db.query(
      'SELECT container_id FROM deployments WHERE name = $1',
      [name]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Deployment not found' });
    }

    const container = docker.getContainer(result.rows[0].container_id);

    if (follow === 'true') {
      // Stream logs
      res.setHeader('Content-Type', 'text/plain');
      res.setHeader('Transfer-Encoding', 'chunked');

      const stream = await container.logs({
        follow: true,
        stdout: true,
        stderr: true,
        tail: parseInt(tail as string),
      });

      stream.on('data', (chunk) => {
        res.write(chunk.toString());
      });

      stream.on('end', () => {
        res.end();
      });

      req.on('close', () => {
        stream.destroy();
      });
    } else {
      // Get static logs
      const logs = await container.logs({
        stdout: true,
        stderr: true,
        tail: parseInt(tail as string),
      });

      res.setHeader('Content-Type', 'text/plain');
      res.send(logs.toString());
    }
  } catch (err) {
    console.error('Get logs error:', err);
    res.status(500).json({ error: 'Failed to get logs' });
  }
});

// Get deployment logs from database
logsRouter.get('/:name/history', async (req: AuthRequest, res: Response) => {
  try {
    const { name } = req.params;
    const { limit = '100', offset = '0' } = req.query;

    const deploymentResult = await db.query(
      'SELECT id FROM deployments WHERE name = $1',
      [name]
    );

    if (deploymentResult.rows.length === 0) {
      return res.status(404).json({ error: 'Deployment not found' });
    }

    const result = await db.query(
      'SELECT timestamp, level, message FROM deployment_logs WHERE deployment_id = $1 ORDER BY timestamp DESC LIMIT $2 OFFSET $3',
      [deploymentResult.rows[0].id, parseInt(limit as string), parseInt(offset as string)]
    );

    res.json({ logs: result.rows });
  } catch (err) {
    console.error('Get deployment logs error:', err);
    res.status(500).json({ error: 'Failed to get deployment logs' });
  }
});
