import type { Request, Response, NextFunction } from 'express';

export const notFoundHandler = (req: Request, res: Response, _next: NextFunction) => {
  res.status(404).json({
    error: 'not_found',
    message: `No se encontró la ruta ${req.method} ${req.originalUrl}`
  });
};

