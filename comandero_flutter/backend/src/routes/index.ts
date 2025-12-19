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

// Endpoint para obtener la IP del servidor (útil para APK móvil)
apiRouter.get('/server-info', (_req, res) => {
  const interfaces = require('os').networkInterfaces();
  const addresses: string[] = [];
  
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      // Solo IPv4, no interno, no loopback
      if (iface.family === 'IPv4' && !iface.internal) {
        const ip = iface.address;
        // Filtrar IPs de red local
        if (ip.startsWith('192.168.') || 
            ip.startsWith('10.') ||
            (ip.startsWith('172.') && parseInt(ip.split('.')[1]) >= 16 && parseInt(ip.split('.')[1]) <= 31)) {
          addresses.push(ip);
        }
      }
    }
  }
  
  res.json({ 
    status: 'ok', 
    serverIp: addresses[0] || null, // Primera IP de red local encontrada
    allIps: addresses,
    timestamp: nowMxISO() 
  });
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

