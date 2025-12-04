import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import {
  listarCategoriasController,
  obtenerCategoriaController,
  crearCategoriaController,
  actualizarCategoriaController,
  eliminarCategoriaController
} from './categorias.controller.js';

const categoriasRouter = Router();

categoriasRouter.use(authenticate);

const lecturaRoles = requireRoles('administrador', 'capitan', 'mesero', 'cocinero');

categoriasRouter.get('/', lecturaRoles, listarCategoriasController);
categoriasRouter.get('/:id', lecturaRoles, obtenerCategoriaController);

categoriasRouter.post('/', requireRoles('administrador', 'capitan'), crearCategoriaController);
categoriasRouter.put('/:id', requireRoles('administrador', 'capitan'), actualizarCategoriaController);
categoriasRouter.delete('/:id', requireRoles('administrador'), eliminarCategoriaController);

export default categoriasRouter;

