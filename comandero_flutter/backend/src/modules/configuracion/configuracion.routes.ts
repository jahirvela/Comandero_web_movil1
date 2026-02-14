import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import { getConfiguracionController, patchConfiguracionController } from './configuracion.controller.js';

const configuracionRouter = Router();

configuracionRouter.use(authenticate);

// Cualquier rol autenticado puede leer la configuración (cajero, mesero, admin, etc.)
configuracionRouter.get('/', getConfiguracionController);

// Solo administrador puede modificar (IVA y futuras opciones)
configuracionRouter.patch('/', requireRoles('administrador'), patchConfiguracionController);

export default configuracionRouter;
