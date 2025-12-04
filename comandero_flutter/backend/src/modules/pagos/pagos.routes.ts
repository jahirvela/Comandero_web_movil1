import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import {
  listarPagosController,
  obtenerPagoController,
  crearPagoController,
  listarFormasPagoController,
  listarPropinasController,
  registrarPropinaController
} from './pagos.controller.js';

const pagosRouter = Router();

pagosRouter.use(authenticate);

// Permitir lectura a todos los roles principales
const lecturaRoles = requireRoles('administrador', 'cajero', 'capitan', 'mesero');

pagosRouter.get('/', lecturaRoles, listarPagosController);
pagosRouter.get('/formas', lecturaRoles, listarFormasPagoController);
pagosRouter.get('/propinas', lecturaRoles, listarPropinasController);
pagosRouter.get('/:id', lecturaRoles, obtenerPagoController);

// Permitir crear pagos a cajero, admin, capitan y mesero (para flujos completos)
pagosRouter.post('/', requireRoles('administrador', 'cajero', 'capitan', 'mesero'), crearPagoController);
pagosRouter.post('/propinas', requireRoles('administrador', 'cajero', 'capitan', 'mesero'), registrarPropinaController);

export default pagosRouter;

