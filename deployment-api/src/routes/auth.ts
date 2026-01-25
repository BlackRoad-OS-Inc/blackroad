import { Router, Request, Response } from 'express';
import bcrypt from 'bcrypt';
import crypto from 'crypto';
import { db } from '../db';

export const authRouter = Router();

// Register new user
authRouter.post('/register', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // Generate API key
    const apiKey = 'br_' + crypto.randomBytes(32).toString('hex');

    // Insert user
    const result = await db.query(
      'INSERT INTO users (email, password_hash, api_key) VALUES ($1, $2, $3) RETURNING id, email, api_key',
      [email, passwordHash, apiKey]
    );

    res.json({
      user: {
        id: result.rows[0].id,
        email: result.rows[0].email,
      },
      apiKey: result.rows[0].api_key,
    });
  } catch (err: any) {
    if (err.code === '23505') {
      return res.status(400).json({ error: 'Email already registered' });
    }
    console.error('Registration error:', err);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// Login
authRouter.post('/login', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    // Get user
    const result = await db.query(
      'SELECT id, email, password_hash, api_key FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = result.rows[0];

    // Verify password
    const valid = await bcrypt.compare(password, user.password_hash);

    if (!valid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    res.json({
      user: {
        id: user.id,
        email: user.email,
      },
      apiKey: user.api_key,
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Regenerate API key
authRouter.post('/regenerate-key', async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    // Verify user
    const result = await db.query(
      'SELECT id, password_hash FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const valid = await bcrypt.compare(password, result.rows[0].password_hash);

    if (!valid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate new API key
    const apiKey = 'br_' + crypto.randomBytes(32).toString('hex');

    await db.query(
      'UPDATE users SET api_key = $1 WHERE id = $2',
      [apiKey, result.rows[0].id]
    );

    res.json({ apiKey });
  } catch (err) {
    console.error('Key regeneration error:', err);
    res.status(500).json({ error: 'Key regeneration failed' });
  }
});
