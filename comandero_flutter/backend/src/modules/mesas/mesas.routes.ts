import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import {
  listarMesasController,
  obtenerMesaController,
  crearMesaController,
  actualizarMesaController,
  eliminarMesaController,
  cambiarEstadoMesaController,
  historialMesaController,
  estadosMesaController
} from './mesas.controller.js';

const mesasRouter = Router();

mesasRouter.use(authenticate);

// Todos los roles principales pueden ver mesas
const lecturaRoles = requireRoles('administrador', 'capitan', 'mesero', 'cajero', 'cocinero');
// El mesero, capitán y cajero pueden actualizar mesas (comensales, estado, etc.)
const gestionRoles = requireRoles('administrador', 'capitan', 'mesero', 'cajero');
const cambioEstadoRoles = requireRoles('administrador', 'capitan', 'mesero', 'cajero');

mesasRouter.get('/', lecturaRoles, listarMesasController);
mesasRouter.get('/estados', lecturaRoles, estadosMesaController);
mesasRouter.get('/:id', lecturaRoles, obtenerMesaController);
mesasRouter.get('/:id/historial', lecturaRoles, historialMesaController);

mesasRouter.post('/', gestionRoles, crearMesaController);
mesasRouter.put('/:id', gestionRoles, actualizarMesaController);
mesasRouter.patch('/:id/estado', cambioEstadoRoles, cambiarEstadoMesaController);
mesasRouter.delete('/:id', requireRoles('administrador'), eliminarMesaController);

export default mesasRouter;

