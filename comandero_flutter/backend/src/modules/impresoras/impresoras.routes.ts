import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import { authenticateCola } from './impresoras.middleware.js';
import {
  listarImpresorasController,
  obtenerImpresoraController,
  crearImpresoraController,
  actualizarImpresoraController,
  eliminarImpresoraController,
  colaPendientesController,
  colaMarcarImpresoController,
  colaMarcarErrorController,
  generarClaveAgenteController,
} from './impresoras.controller.js';

const impresorasRouter = Router();

/** Cola de impresión: acepta JWT o clave de agente (X-Agent-Api-Key) */
impresorasRouter.get('/cola/pendientes', authenticateCola, colaPendientesController);
impresorasRouter.post('/cola/job/:id/impreso', authenticateCola, colaMarcarImpresoController);
impresorasRouter.post('/cola/job/:id/error', authenticateCola, colaMarcarErrorController);

/** Resto de rutas: solo JWT de usuario */
impresorasRouter.use(authenticate);
impresorasRouter.get('/', listarImpresorasController);
impresorasRouter.post('/', requireRoles('administrador'), crearImpresoraController);
// Ruta específica antes de GET /:id para que Express no interprete "generar-clave-agente" como :id
impresorasRouter.post('/:id/generar-clave-agente', requireRoles('administrador'), generarClaveAgenteController);
impresorasRouter.get('/:id', obtenerImpresoraController);
impresorasRouter.put('/:id', requireRoles('administrador'), actualizarImpresoraController);
impresorasRouter.delete('/:id', requireRoles('administrador'), eliminarImpresoraController);

export default impresorasRouter;
