import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { createServer } from 'http';
import { WebSocketServer } from 'ws';
import { deploymentRouter } from './routes/deployments';
import { logsRouter } from './routes/logs';
import { envRouter } from './routes/env';
import { authRouter } from './routes/auth';
import { domainsRouter } from './routes/domains';
import { db } from './db';
import { authenticate } from './middleware/auth';

dotenv.config();

const app = express();
const server = createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

// Middleware
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Health check (public)
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Auth routes (public)
app.use('/api/auth', authRouter);

// Protected routes
app.use('/api/deployments', authenticate, deploymentRouter);
app.use('/api/logs', authenticate, logsRouter);
app.use('/api/env', authenticate, envRouter);
app.use('/api/domains', authenticate, domainsRouter);

// WebSocket for real-time logs
wss.on('connection', (ws, req) => {
  console.log('WebSocket client connected');

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message.toString());
      console.log('WebSocket message:', data);
      // Handle log streaming subscriptions
    } catch (err) {
      console.error('WebSocket error:', err);
    }
  });

  ws.on('close', () => {
    console.log('WebSocket client disconnected');
  });
});

// Error handler
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  console.error('Error:', err);
  res.status(500).json({ error: err.message });
});

const PORT = process.env.PORT || 3000;

// Initialize database and start server
db.initialize()
  .then(() => {
    server.listen(PORT, () => {
      console.log(`🚀 BlackRoad Deploy API listening on port ${PORT}`);
      console.log(`📊 Health: http://localhost:${PORT}/health`);
      console.log(`🔌 WebSocket: ws://localhost:${PORT}/ws`);
    });
  })
  .catch((err) => {
    console.error('Failed to initialize database:', err);
    process.exit(1);
  });

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down...');
  server.close(() => {
    db.close();
    process.exit(0);
  });
});
