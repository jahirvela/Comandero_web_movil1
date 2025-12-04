import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import {
  listarProductosController,
  obtenerProductoController,
  crearProductoController,
  actualizarProductoController,
  desactivarProductoController
} from './productos.controller.js';

const productosRouter = Router();

productosRouter.use(authenticate);

const lecturaRoles = requireRoles('administrador', 'capitan', 'mesero', 'cocinero', 'cajero');
const gestionRoles = requireRoles('administrador', 'capitan');

productosRouter.get('/', lecturaRoles, listarProductosController);
productosRouter.get('/:id', lecturaRoles, obtenerProductoController);
productosRouter.post('/', gestionRoles, crearProductoController);
productosRouter.put('/:id', gestionRoles, actualizarProductoController);
productosRouter.delete('/:id', requireRoles('administrador'), desactivarProductoController);

export default productosRouter;

