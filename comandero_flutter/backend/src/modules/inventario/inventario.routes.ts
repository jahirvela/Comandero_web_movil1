import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import {
  listarInsumosController,
  obtenerInsumoController,
  obtenerInsumoPorCodigoBarrasController,
  crearInsumoController,
  actualizarInsumoController,
  eliminarInsumoController,
  registrarMovimientoController,
  listarMovimientosController,
  listarCategoriasController,
  crearCategoriaInventarioController,
  eliminarCategoriaInventarioController,
  renombrarCategoriaInventarioController
} from './inventario.controller.js';

const inventarioRouter = Router();

inventarioRouter.use(authenticate);

const lecturaRoles = requireRoles('administrador', 'capitan', 'cocinero', 'gerente');
const gestionRoles = requireRoles('administrador', 'capitan', 'gerente');

inventarioRouter.get('/items', lecturaRoles, listarInsumosController);
inventarioRouter.get('/items/por-codigo-barras', lecturaRoles, obtenerInsumoPorCodigoBarrasController);
inventarioRouter.get('/items/:id', lecturaRoles, obtenerInsumoController);
inventarioRouter.post('/items', gestionRoles, crearInsumoController);
inventarioRouter.put('/items/:id', gestionRoles, actualizarInsumoController);
inventarioRouter.delete('/items/:id', requireRoles('administrador'), eliminarInsumoController);

inventarioRouter.get('/categorias', lecturaRoles, listarCategoriasController);
inventarioRouter.post('/categorias', gestionRoles, crearCategoriaInventarioController);
inventarioRouter.put('/categorias/:nombre', gestionRoles, renombrarCategoriaInventarioController);
inventarioRouter.delete('/categorias/:nombre', gestionRoles, eliminarCategoriaInventarioController);

inventarioRouter.get('/movimientos', lecturaRoles, listarMovimientosController);
inventarioRouter.post('/movimientos', gestionRoles, registrarMovimientoController);

export default inventarioRouter;

