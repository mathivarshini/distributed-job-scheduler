import express, { Express } from 'express';
import dotenv from 'dotenv';

dotenv.config();

export function createApp(): Express {
  const app = express();

  app.use(express.json());

  app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'ok', service: 'backend-api' });
  });

  return app;
}
