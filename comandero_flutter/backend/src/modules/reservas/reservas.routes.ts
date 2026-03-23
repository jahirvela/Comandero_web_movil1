import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import {
  listarReservasController,
  obtenerReservaController,
  crearReservaController,
  actualizarReservaController,
  eliminarReservaController,
} from './reservas.controller.js';

const reservasRouter = Router();

reservasRouter.use(authenticate);

// GET /api/reservas - Listar reservas
reservasRouter.get(
  '/',
  requireRoles('administrador', 'capitan', 'mesero', 'gerente'),
  listarReservasController
);

// GET /api/reservas/:id - Obtener una reserva
reservasRouter.get(
  '/:id',
  requireRoles('administrador', 'capitan', 'mesero', 'gerente'),
  obtenerReservaController
);

// POST /api/reservas - Crear reserva
reservasRouter.post(
  '/',
  requireRoles('administrador', 'capitan', 'mesero', 'gerente'),
  crearReservaController
);

// PUT /api/reservas/:id - Actualizar reserva
reservasRouter.put(
  '/:id',
  requireRoles('administrador', 'capitan', 'mesero', 'gerente'),
  actualizarReservaController
);

// DELETE /api/reservas/:id - Eliminar reserva
reservasRouter.delete(
  '/:id',
  requireRoles('administrador', 'capitan', 'gerente'),
  eliminarReservaController
);

export default reservasRouter;

