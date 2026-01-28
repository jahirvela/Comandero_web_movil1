import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import {
  listarUsuariosController,
  obtenerUsuarioController,
  crearUsuarioController,
  actualizarUsuarioController,
  eliminarUsuarioController,
  eliminarUsuarioPermanenteController,
  asignarRolesUsuarioController,
  listarRolesController
} from './usuarios.controller.js';

const usuariosRouter = Router();

usuariosRouter.use(authenticate);

usuariosRouter.get('/', requireRoles('administrador'), listarUsuariosController);
usuariosRouter.get('/roles/catalogo', requireRoles('administrador'), listarRolesController);
usuariosRouter.get('/:id', requireRoles('administrador'), obtenerUsuarioController);
usuariosRouter.post('/', requireRoles('administrador'), crearUsuarioController);
usuariosRouter.put('/:id', requireRoles('administrador'), actualizarUsuarioController);
usuariosRouter.delete('/:id', requireRoles('administrador'), eliminarUsuarioController);
usuariosRouter.delete(
  '/:id/permanente',
  requireRoles('administrador'),
  eliminarUsuarioPermanenteController
);
usuariosRouter.post('/:id/roles', requireRoles('administrador'), asignarRolesUsuarioController);

export default usuariosRouter;

