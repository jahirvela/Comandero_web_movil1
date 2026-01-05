import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import {
  listarOrdenesController,
  obtenerOrdenController,
  crearOrdenController,
  actualizarOrdenController,
  actualizarEstadoOrdenController,
  actualizarTiempoEstimadoController,
  agregarItemsOrdenController,
  listarEstadosOrdenController,
  listarOrdenesCocinaController
} from './ordenes.controller.js';

const ordenesRouter = Router();

ordenesRouter.use(authenticate);

const lecturaRoles = requireRoles(
  'administrador',
  'capitan',
  'mesero',
  'cocinero',
  'cajero'
);
const gestionOrdenRoles = requireRoles('administrador', 'capitan', 'mesero');

ordenesRouter.get('/', lecturaRoles, listarOrdenesController);
ordenesRouter.get('/cocina', requireRoles('administrador', 'cocinero'), listarOrdenesCocinaController);
ordenesRouter.get('/estados', lecturaRoles, listarEstadosOrdenController);
ordenesRouter.get('/:id', lecturaRoles, obtenerOrdenController);
ordenesRouter.post('/', gestionOrdenRoles, crearOrdenController);
ordenesRouter.put('/:id', gestionOrdenRoles, actualizarOrdenController);
ordenesRouter.post('/:id/items', gestionOrdenRoles, agregarItemsOrdenController);
ordenesRouter.patch(
  '/:id/estado',
  requireRoles('administrador', 'capitan', 'mesero', 'cocinero', 'cajero'),
  actualizarEstadoOrdenController
);
ordenesRouter.patch(
  '/:id/tiempo-estimado',
  requireRoles('administrador', 'cocinero'),
  actualizarTiempoEstimadoController
);

export default ordenesRouter;

