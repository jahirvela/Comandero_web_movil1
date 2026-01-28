import { Router } from 'express';
import { reimprimirComandaHandler } from './comandas.controller.js';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';

const router = Router();

/**
 * POST /api/comandas/reimprimir
 * Reimprime una comanda manualmente (mesero, administrador, capitan)
 */
router.post(
  '/reimprimir',
  authenticate,
  requireRoles('mesero', 'administrador', 'capitan'),
  reimprimirComandaHandler
);

export default router;

