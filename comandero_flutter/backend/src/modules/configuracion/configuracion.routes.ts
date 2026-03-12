import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import {
  getConfiguracionController,
  patchConfiguracionController,
  getPlantillaImpresionController,
  putPlantillaImpresionController,
} from './configuracion.controller.js';

const configuracionRouter = Router();

configuracionRouter.use(authenticate);

// Cualquier rol autenticado puede leer la configuración (cajero, mesero, admin, etc.)
configuracionRouter.get('/', getConfiguracionController);

// Solo administrador puede modificar (IVA y futuras opciones)
configuracionRouter.patch('/', requireRoles('administrador'), patchConfiguracionController);

// Plantillas de impresión (ticket de cobro, comanda): solo admin edita
configuracionRouter.get('/plantillas-impresion/:tipo', getPlantillaImpresionController);
configuracionRouter.put('/plantillas-impresion/:tipo', requireRoles('administrador'), putPlantillaImpresionController);

export default configuracionRouter;
