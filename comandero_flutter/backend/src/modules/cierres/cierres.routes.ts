import { Router } from 'express';
import { listarCierresCajaHandler, crearCierreCajaHandler, actualizarEstadoCierreHandler } from './cierres.controller.js';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';

const cierresRouter = Router();

// GET /api/cierres
// Listar cierres de caja
cierresRouter.get(
  '/',
  authenticate,
  requireRoles('administrador', 'cajero', 'capitan'),
  listarCierresCajaHandler
);

// POST /api/cierres
// Crear/enviar un cierre de caja
cierresRouter.post(
  '/',
  authenticate,
  requireRoles('administrador', 'cajero', 'capitan'),
  crearCierreCajaHandler
);

// PATCH /api/cierres/:id/estado
// Actualizar el estado de un cierre de caja (solo administrador)
cierresRouter.patch(
  '/:id/estado',
  authenticate,
  requireRoles('administrador'),
  actualizarEstadoCierreHandler
);

export default cierresRouter;

