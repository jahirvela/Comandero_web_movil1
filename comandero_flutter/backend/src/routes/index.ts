import { Router } from 'express';
import authRouter from '../auth/auth.routes.js';
import usuariosRouter from '../modules/usuarios/usuarios.routes.js';
import rolesRouter from '../modules/roles/roles.routes.js';
import mesasRouter from '../modules/mesas/mesas.routes.js';
import categoriasRouter from '../modules/categorias/categorias.routes.js';
import productosRouter from '../modules/productos/productos.routes.js';
import inventarioRouter from '../modules/inventario/inventario.routes.js';
import ordenesRouter from '../modules/ordenes/ordenes.routes.js';
import pagosRouter from '../modules/pagos/pagos.routes.js';
import ticketsRouter from '../modules/tickets/tickets.routes.js';
import reportesRouter from '../modules/reportes/reportes.routes.js';
import cierresRouter from '../modules/cierres/cierres.routes.js';
import alertasRouter from '../modules/alertas/alertas.routes.js';
import reservasRouter from '../modules/reservas/reservas.routes.js';
import { nowMxISO } from '../config/time.js';

const apiRouter = Router();

apiRouter.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: nowMxISO() });
});

apiRouter.use('/auth', authRouter);
apiRouter.use('/usuarios', usuariosRouter);
apiRouter.use('/roles', rolesRouter);
apiRouter.use('/mesas', mesasRouter);
apiRouter.use('/categorias', categoriasRouter);
apiRouter.use('/productos', productosRouter);
apiRouter.use('/inventario', inventarioRouter);
apiRouter.use('/ordenes', ordenesRouter);
apiRouter.use('/pagos', pagosRouter);
apiRouter.use('/tickets', ticketsRouter);
apiRouter.use('/reportes', reportesRouter);
apiRouter.use('/cierres', cierresRouter);
apiRouter.use('/alertas', alertasRouter);
apiRouter.use('/reservas', reservasRouter);

// Aquí se montarán los módulos específicos, e.g. usuarios, mesas, etc.

export default apiRouter;

