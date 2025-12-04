import type { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../utils/jwt.js';
import { unauthorized } from '../utils/http-error.js';

const extractToken = (authorizationHeader?: string) => {
  if (!authorizationHeader) return null;
  const [scheme, token] = authorizationHeader.split(' ');
  if (scheme?.toLowerCase() !== 'bearer' || !token) {
    return null;
  }
  return token;
};

export const authenticate = (req: Request, _res: Response, next: NextFunction) => {
  const token = extractToken(req.headers.authorization);

  if (!token) {
    return next(unauthorized('Token de acceso requerido'));
  }

  const { valid, decoded } = verifyAccessToken(token);

  if (!valid || !decoded) {
    return next(unauthorized('Token de acceso inválido'));
  }

  req.user = {
    id: decoded.sub,
    username: decoded.username,
    roles: decoded.roles
  };

  return next();
};

