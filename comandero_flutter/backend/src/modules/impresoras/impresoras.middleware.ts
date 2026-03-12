import type { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../../utils/jwt.js';
import { unauthorized } from '../../utils/http-error.js';
import { obtenerImpresoraPorAgenteApiKey } from './impresoras.repository.js';

const extractBearer = (authorizationHeader?: string) => {
  if (!authorizationHeader) return null;
  const [scheme, token] = authorizationHeader.split(' ');
  if (scheme?.toLowerCase() !== 'bearer' || !token) return null;
  return token;
};

/**
 * Autentica las rutas de cola con JWT (usuario) o con clave de agente (X-Agent-Api-Key).
 * Con JWT: req.user queda definido.
 * Con clave: req.impresoraAgenteId queda definido (solo acceso a esa impresora).
 */
export async function authenticateCola(req: Request, _res: Response, next: NextFunction) {
  const apiKey = (req.headers['x-agent-api-key'] as string)?.trim();
  if (apiKey) {
    const impresora = await obtenerImpresoraPorAgenteApiKey(apiKey);
    if (impresora) {
      req.impresoraAgenteId = impresora.id;
      return next();
    }
  }

  const token = extractBearer(req.headers.authorization);
  if (token) {
    const { valid, decoded } = verifyAccessToken(token);
    if (valid && decoded) {
      req.user = {
        id: decoded.sub,
        username: decoded.username,
        roles: decoded.roles,
      };
      return next();
    }
  }

  return next(unauthorized('Token de acceso o clave de agente requeridos'));
}
