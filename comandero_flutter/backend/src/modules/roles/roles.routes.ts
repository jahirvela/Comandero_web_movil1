import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import {
  listarRolesController,
  obtenerRolController,
  crearRolController,
  actualizarRolController,
  eliminarRolController,
  listarPermisosController
} from './roles.controller.js';

const rolesRouter = Router();

rolesRouter.use(authenticate);
rolesRouter.use(requireRoles('administrador'));

rolesRouter.get('/', listarRolesController);
rolesRouter.get('/permisos', listarPermisosController);
rolesRouter.get('/:id', obtenerRolController);
rolesRouter.post('/', crearRolController);
rolesRouter.put('/:id', actualizarRolController);
rolesRouter.delete('/:id', eliminarRolController);

export default rolesRouter;

