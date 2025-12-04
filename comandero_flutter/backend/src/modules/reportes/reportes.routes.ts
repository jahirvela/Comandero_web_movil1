import { Router } from 'express';
import {
  reporteVentasPDFHandler,
  reporteVentasCSVHandler,
  reporteTopProductosPDFHandler,
  reporteTopProductosCSVHandler,
  corteCajaPDFHandler,
  corteCajaCSVHandler,
  reporteInventarioPDFHandler,
  reporteInventarioCSVHandler
} from './reportes.controller.js';
import { authenticate } from '../../middlewares/authentication.js';
import { authorize } from '../../middlewares/authorization.js';

const reportesRouter = Router();

// Todas las rutas requieren autenticación
reportesRouter.use(authenticate);

// Reporte de ventas
reportesRouter.get('/ventas/pdf', authorize(['administrador', 'cajero']), reporteVentasPDFHandler);
reportesRouter.get('/ventas/csv', authorize(['administrador', 'cajero']), reporteVentasCSVHandler);

// Top productos
reportesRouter.get('/top-productos/pdf', authorize(['administrador']), reporteTopProductosPDFHandler);
reportesRouter.get('/top-productos/csv', authorize(['administrador']), reporteTopProductosCSVHandler);

// Corte de caja
reportesRouter.get('/corte-caja/pdf', authorize(['administrador', 'cajero']), corteCajaPDFHandler);
reportesRouter.get('/corte-caja/csv', authorize(['administrador', 'cajero']), corteCajaCSVHandler);

// Reporte de inventario
reportesRouter.get('/inventario/pdf', authorize(['administrador']), reporteInventarioPDFHandler);
reportesRouter.get('/inventario/csv', authorize(['administrador']), reporteInventarioCSVHandler);

export default reportesRouter;

