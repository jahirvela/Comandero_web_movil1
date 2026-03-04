import type { AuthenticatedUser } from '../../types/global';

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
      /** Cuando el agente usa X-Agent-Api-Key en vez de JWT. */
      impresoraAgenteId?: number;
    }
  }
}

export {};

