import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import { obtenerAlertas, marcarLeida, crearAlertaDesdeRequest, marcarTodasComoLeidas } from './alertas.service.js';

const alertasRouter = Router();

alertasRouter.use(authenticate);

// Crear nueva alerta
alertasRouter.post('/', async (req, res, next) => {
  try {
    const usuarioId = req.user?.id;
    if (!usuarioId) {
      return res.status(401).json({ error: 'Usuario no autenticado' });
    }

    const alertaId = await crearAlertaDesdeRequest(req.body, usuarioId);
    res.status(201).json({ 
      message: 'Alerta creada exitosamente',
      data: { id: alertaId }
    });
  } catch (error) {
    next(error);
  }
});

// Obtener alertas no leídas (todos los roles pueden ver sus alertas)
alertasRouter.get('/', async (req, res, next) => {
  try {
    const usuarioId = req.user?.id;
    if (!usuarioId) {
      return res.status(401).json({ error: 'Usuario no autenticado' });
    }

    const rol = req.user?.roles?.[0] || '';
    const alertas = await obtenerAlertas(usuarioId, rol);
    
    // Log para debugging
    console.log(`[Alertas] Usuario ${usuarioId} (rol: ${rol}) - ${alertas.length} alertas encontradas`);
    
    res.json({ data: alertas });
  } catch (error) {
    next(error);
  }
});

// Marcar alerta como leída
alertasRouter.patch('/:id/leida', async (req, res, next) => {
  try {
    const usuarioId = req.user?.id;
    if (!usuarioId) {
      return res.status(401).json({ error: 'Usuario no autenticado' });
    }

    const alertaId = parseInt(req.params.id, 10);
    if (isNaN(alertaId)) {
      return res.status(400).json({ error: 'ID de alerta inválido' });
    }

    await marcarLeida(alertaId, usuarioId);
    res.json({ message: 'Alerta marcada como leída' });
  } catch (error) {
    next(error);
  }
});

// Marcar todas las alertas como leídas
alertasRouter.post('/marcar-todas-leidas', async (req, res, next) => {
  try {
    const usuarioId = req.user?.id;
    if (!usuarioId) {
      return res.status(401).json({ error: 'Usuario no autenticado' });
    }

    const rol = req.user?.roles?.[0] || '';
    const afectadas = await marcarTodasComoLeidas(usuarioId, rol);
    
    res.json({ 
      message: 'Todas las alertas marcadas como leídas',
      data: { alertasMarcadas: afectadas }
    });
  } catch (error) {
    next(error);
  }
});

export default alertasRouter;

