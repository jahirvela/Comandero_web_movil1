import { Router } from 'express';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';
import { obtenerAlertas, marcarLeida, crearAlertaDesdeRequest, marcarTodasComoLeidas, crearYEmitirAlertaCocina } from './alertas.service.js';
import { getIO } from '../../realtime/socket.js';

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

// Endpoint específico para alertas de mesero hacia cocinero
alertasRouter.post('/cocina', async (req, res, next) => {
  try {
    const usuarioId = req.user?.id;
    if (!usuarioId) {
      return res.status(401).json({ error: 'Usuario no autenticado' });
    }

    const { ordenId, tipo, mensaje } = req.body;

    // Validar campos requeridos
    if (!ordenId) {
      return res.status(400).json({ error: 'ordenId es requerido' });
    }

    if (!mensaje || typeof mensaje !== 'string' || mensaje.trim().length === 0) {
      return res.status(400).json({ error: 'El mensaje no puede estar vacío' });
    }

    // Validar que ordenId sea un número válido
    const ordenIdNum = parseInt(ordenId, 10);
    if (isNaN(ordenIdNum)) {
      return res.status(400).json({ error: 'ordenId debe ser un número válido' });
    }

    // Obtener instancia de Socket.IO
    const io = getIO();

    // Crear y emitir alerta usando el método centralizado
    // El método obtiene la mesa real de la orden automáticamente
    const alertaDTO = await crearYEmitirAlertaCocina(
      {
        usuarioOrigenId: usuarioId,
        ordenId: ordenIdNum,
        tipoAlerta: tipo || 'alerta.demora', // Valor por defecto si no se envía
        mensaje: mensaje.trim()
      },
      io
    );

    res.status(201).json({
      message: 'Alerta enviada a cocina exitosamente',
      data: alertaDTO
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

