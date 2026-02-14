import { Router } from 'express';
import { networkInterfaces } from 'os';
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
import comandasRouter from '../modules/comandas/comandas.routes.js';
import reportesRouter from '../modules/reportes/reportes.routes.js';
import cierresRouter from '../modules/cierres/cierres.routes.js';
import alertasRouter from '../modules/alertas/alertas.routes.js';
import reservasRouter from '../modules/reservas/reservas.routes.js';
import configuracionRouter from '../modules/configuracion/configuracion.routes.js';
import impresorasRouter from '../modules/impresoras/impresoras.routes.js';
import { nowMxISO } from '../config/time.js';

const apiRouter = Router();

apiRouter.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: nowMxISO() });
});

// Endpoint temporal de desarrollo para habilitar usuarios deshabilitados
// SOLO PARA DESARROLLO - Remover en producción
if (process.env.NODE_ENV === 'development') {
  apiRouter.post('/dev/enable-user', async (req, res, next) => {
    try {
      const { username } = req.body;
      if (!username) {
        return res.status(400).json({ error: 'Username requerido' });
      }

      const { pool } = await import('../db/pool.js');
      const [result] = await pool.execute(
        `UPDATE usuario SET activo = 1, actualizado_en = NOW() WHERE username = ?`,
        [username]
      );

      const affectedRows = (result as any).affectedRows;
      
      if (affectedRows > 0) {
        const [rows] = await pool.query<any[]>(
          `SELECT id, nombre, username, activo FROM usuario WHERE username = ?`,
          [username]
        );
        res.json({ 
          success: true, 
          message: `Usuario "${username}" habilitado correctamente`,
          user: rows[0] 
        });
      } else {
        res.status(404).json({ 
          success: false, 
          message: `Usuario "${username}" no encontrado o ya estaba habilitado` 
        });
      }
    } catch (error: any) {
      next(error);
    }
  });
}

// Endpoint para obtener la IP del servidor (útil para APK móvil)
apiRouter.get('/server-info', (_req, res) => {
  const interfaces = networkInterfaces();
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
apiRouter.use('/comandas', comandasRouter);
apiRouter.use('/reportes', reportesRouter);
apiRouter.use('/cierres', cierresRouter);
apiRouter.use('/alertas', alertasRouter);
apiRouter.use('/reservas', reservasRouter);
apiRouter.use('/configuracion', configuracionRouter);
apiRouter.use('/impresoras', impresorasRouter);

// Aquí se montarán los módulos específicos, e.g. usuarios, mesas, etc.

export default apiRouter;

