import { Request, Response, NextFunction } from 'express';
import { db } from '../db';

export interface AuthRequest extends Request {
  userId?: number;
  userEmail?: string;
}

export async function authenticate(
  req: AuthRequest,
  res: Response,
  next: NextFunction
) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid authorization header' });
    }

    const apiKey = authHeader.substring(7);

    // Validate API key
    const result = await db.query(
      'SELECT id, email FROM users WHERE api_key = $1',
      [apiKey]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid API key' });
    }

    req.userId = result.rows[0].id;
    req.userEmail = result.rows[0].email;

    next();
  } catch (err) {
    console.error('Authentication error:', err);
    res.status(500).json({ error: 'Authentication failed' });
  }
}
