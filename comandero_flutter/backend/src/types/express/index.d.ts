import type { AuthenticatedUser } from '../../types/global';

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}

export {};

