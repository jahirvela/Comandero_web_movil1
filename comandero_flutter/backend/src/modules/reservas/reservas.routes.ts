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
  requireRoles('administrador', 'capitan', 'mesero'),
  listarReservasController
);

// GET /api/reservas/:id - Obtener una reserva
reservasRouter.get(
  '/:id',
  requireRoles('administrador', 'capitan', 'mesero'),
  obtenerReservaController
);

// POST /api/reservas - Crear reserva
reservasRouter.post(
  '/',
  requireRoles('administrador', 'capitan', 'mesero'),
  crearReservaController
);

// PUT /api/reservas/:id - Actualizar reserva
reservasRouter.put(
  '/:id',
  requireRoles('administrador', 'capitan', 'mesero'),
  actualizarReservaController
);

// DELETE /api/reservas/:id - Eliminar reserva
reservasRouter.delete(
  '/:id',
  requireRoles('administrador', 'capitan'),
  eliminarReservaController
);

export default reservasRouter;

