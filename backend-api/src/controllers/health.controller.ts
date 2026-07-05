import { Request, Response } from 'express';

export class HealthController {
  public getHealth(_req: Request, res: Response): void {
    // TODO: Implement production health checks.
    res.status(200).json({ status: 'ok', service: 'backend-api' });
  }
}
