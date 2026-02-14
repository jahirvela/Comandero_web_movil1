import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import {
  listarImpresorasController,
  obtenerImpresoraController,
  crearImpresoraController,
  actualizarImpresoraController,
  eliminarImpresoraController,
} from './impresoras.controller.js';

const impresorasRouter = Router();

impresorasRouter.use(authenticate);

impresorasRouter.get('/', listarImpresorasController);
impresorasRouter.get('/:id', obtenerImpresoraController);
impresorasRouter.post('/', requireRoles('administrador'), crearImpresoraController);
impresorasRouter.put('/:id', requireRoles('administrador'), actualizarImpresoraController);
impresorasRouter.delete('/:id', requireRoles('administrador'), eliminarImpresoraController);

export default impresorasRouter;
