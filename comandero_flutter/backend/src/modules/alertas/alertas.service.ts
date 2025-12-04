import { getIO, getSocketRooms } from '../../realtime/socket.js';
import { logger } from '../../config/logger.js';
import { crearAlerta, obtenerAlertasNoLeidas, marcarAlertaLeida, marcarTodasLasAlertasComoLeidas } from './alertas.repository.js';
import type { AlertaPayload } from './alertas.types.js';
import { TipoAlerta } from './alertas.types.js';
import { nowMxISO } from '../../config/time.js';

/**
 * Emite una alerta en tiempo real y la guarda en la BD
 * OPTIMIZADO: Emite primero para respuesta inmediata, guarda después en background
 */
export const emitirAlerta = async (
  payload: AlertaPayload,
  usuarioId: number,
  rolesDestino: string[] = []
): Promise<void> => {
  try {
    // OPTIMIZACIÓN: Emitir primero por Socket.IO para respuesta inmediata
    const io = getIO();

    // Emitir a roles específicos INMEDIATAMENTE
    for (const rol of rolesDestino) {
      const roomName = getSocketRooms.role(rol);
      const socketsInRoom = await io.in(roomName).fetchSockets();
      
      // Emitir el evento con el tipo de alerta como nombre del evento
      io.to(roomName).emit(payload.tipo, payload);
      
      logger.info({ 
        tipo: payload.tipo, 
        rol, 
        ordenId: payload.ordenId,
        room: roomName,
        socketsCount: socketsInRoom.length,
        socketsIds: socketsInRoom.map((s: any) => s.id),
        mensaje: payload.mensaje,
        metadata: payload.metadata
      }, `🔔 Alerta "${payload.tipo}" emitida a rol "${rol}" en sala "${roomName}"`);
      
      // Log adicional para debugging
      console.log(`[ALERTAS] Emitido ${payload.tipo} a ${rol}: ${payload.mensaje} (Orden: ${payload.ordenId}, SocketIds: ${socketsInRoom.length})`);
    }

    // Siempre emitir alertas importantes al administrador para supervisión
    if (payload.prioridad === 'urgente' || payload.prioridad === 'alta' || 
        payload.tipo === TipoAlerta.CANCELACION || payload.tipo === TipoAlerta.DEMORA) {
      io.to(getSocketRooms.role('administrador')).emit(payload.tipo, payload);
      logger.info({ tipo: payload.tipo, ordenId: payload.ordenId }, 'Alerta importante emitida a administrador');
    }

    // Emitir a estación específica si aplica
    if (payload.estacion) {
      io.to(getSocketRooms.station(payload.estacion)).emit(payload.tipo, payload);
      logger.info({ tipo: payload.tipo, estacion: payload.estacion }, 'Alerta emitida a estación');
    }

    // Emitir a todos si es urgente
    if (payload.prioridad === 'urgente') {
      io.emit(payload.tipo, payload);
      logger.info({ tipo: payload.tipo }, 'Alerta urgente emitida a todos');
    }

    // Guardar en BD - IMPORTANTE: Esperar a que se complete para asegurar persistencia
    try {
      const alertaId = await crearAlerta(payload, usuarioId);
      logger.info({ 
        alertaId, 
        tipo: payload.tipo, 
        ordenId: payload.ordenId,
        mensaje: payload.mensaje 
      }, '✅ Alerta guardada en BD exitosamente');
    } catch (error) {
      logger.error({ err: error, payload }, '❌ Error al guardar alerta en BD');
      // Continuar aunque falle - la alerta ya fue emitida por Socket.IO
    }
  } catch (error) {
    logger.error({ err: error, payload }, 'Error al emitir alerta');
    // No lanzar error, solo loguear
  }
};

/**
 * Emite alerta de demora en cocina
 */
export const emitirAlertaDemora = async (
  ordenId: number,
  tiempoEspera: number,
  usuarioId: number
): Promise<void> => {
  const payload: AlertaPayload = {
    tipo: TipoAlerta.DEMORA,
    mensaje: `Orden #${ordenId} lleva ${tiempoEspera} minutos en cocina`,
    ordenId,
    prioridad: tiempoEspera > 30 ? 'urgente' : tiempoEspera > 20 ? 'alta' : 'media',
    emisor: {
      id: usuarioId,
      username: 'Sistema',
      rol: 'sistema'
    },
    timestamp: nowMxISO(),
    metadata: { tiempoEspera }
  };

  await emitirAlerta(payload, usuarioId, ['capitan', 'cocinero']);
};

/**
 * Emite alerta de cancelación
 */
export const emitirAlertaCancelacion = async (
  ordenId: number,
  motivo: string,
  usuarioId: number,
  username: string,
  rol: string
): Promise<void> => {
  const payload: AlertaPayload = {
    tipo: TipoAlerta.CANCELACION,
    mensaje: `Orden #${ordenId} cancelada: ${motivo}`,
    ordenId,
    prioridad: 'alta',
    emisor: {
      id: usuarioId,
      username,
      rol
    },
    timestamp: nowMxISO(),
    metadata: { motivo }
  };

  await emitirAlerta(payload, usuarioId, ['capitan', 'cocinero', 'mesero']);
};

/**
 * Emite alerta de modificación en orden
 */
export const emitirAlertaModificacion = async (
  ordenId: number,
  productoId: number,
  cambio: string,
  usuarioId: number,
  username: string,
  rol: string
): Promise<void> => {
  const payload: AlertaPayload = {
    tipo: TipoAlerta.MODIFICACION,
    mensaje: `Orden #${ordenId} modificada: ${cambio}`,
    ordenId,
    productoId,
    prioridad: 'media',
    emisor: {
      id: usuarioId,
      username,
      rol
    },
    timestamp: nowMxISO(),
    metadata: { cambio }
  };

  await emitirAlerta(payload, usuarioId, ['capitan', 'cocinero']);
};

/**
 * Emite alerta de caja
 */
export const emitirAlertaCaja = async (
  mensaje: string,
  prioridad: 'baja' | 'media' | 'alta' | 'urgente',
  usuarioId: number,
  username: string,
  rol: string,
  metadata?: Record<string, unknown>
): Promise<void> => {
  const payload: AlertaPayload = {
    tipo: TipoAlerta.CAJA,
    mensaje,
    prioridad,
    emisor: {
      id: usuarioId,
      username,
      rol
    },
    timestamp: nowMxISO(),
    metadata
  };

  await emitirAlerta(payload, usuarioId, ['administrador', 'cajero']);
};

/**
 * Emite alerta cuando un pedido está listo
 */
export const emitirAlertaPedidoListo = async (
  ordenId: number,
  mesaId: number | null,
  mesaCodigo: string | null,
  usuarioId: number,
  username: string,
  rol: string,
  isTakeaway: boolean = false
): Promise<void> => {
  const mensaje = isTakeaway
    ? `Pedido #${ordenId} está listo para recoger`
    : mesaCodigo
    ? `Pedido #${ordenId} de Mesa ${mesaCodigo} está listo`
    : `Pedido #${ordenId} está listo`;

  const payload: AlertaPayload = {
    tipo: TipoAlerta.COCINA,
    mensaje,
    ordenId,
    mesaId: mesaId ?? undefined,
    prioridad: 'alta',
    emisor: {
      id: usuarioId,
      username,
      rol
    },
    timestamp: nowMxISO(),
    metadata: {
      isTakeaway,
      mesaCodigo,
      estado: 'listo'
    }
  };

  logger.info({ 
    ordenId, 
    mesaId, 
    mesaCodigo, 
    isTakeaway, 
    mensaje,
    metadata: payload.metadata
  }, '🔔 Emitiendo alerta: Pedido LISTO');

  // Enviar alerta principalmente al mesero, pero también a capitan y administrador
  // IMPORTANTE: Esperar a que se complete para asegurar que se guarde en BD
  await emitirAlerta(payload, usuarioId, ['mesero', 'capitan', 'administrador']);
  
  logger.info({ ordenId }, '✅ Alerta de listo completada (emitida y guardada)');
};

/**
 * Emite alerta cuando un pedido está en preparación
 */
export const emitirAlertaPedidoEnPreparacion = async (
  ordenId: number,
  mesaId: number | null,
  mesaCodigo: string | null,
  usuarioId: number,
  username: string,
  rol: string,
  isTakeaway: boolean = false
): Promise<void> => {
  const mensaje = isTakeaway
    ? `Pedido #${ordenId} está en preparación`
    : mesaCodigo
    ? `Pedido #${ordenId} de Mesa ${mesaCodigo} está en preparación`
    : `Pedido #${ordenId} está en preparación`;

  const payload: AlertaPayload = {
    tipo: TipoAlerta.COCINA,
    mensaje,
    ordenId,
    mesaId: mesaId ?? undefined,
    prioridad: 'media',
    emisor: {
      id: usuarioId,
      username,
      rol
    },
    timestamp: nowMxISO(),
    metadata: {
      isTakeaway,
      mesaCodigo,
      estado: 'preparacion'
    }
  };

  logger.info({ 
    ordenId, 
    mesaId, 
    mesaCodigo, 
    isTakeaway, 
    mensaje,
    metadata: payload.metadata
  }, '🔔 Emitiendo alerta: Pedido EN PREPARACIÓN');

  // Enviar alerta principalmente al mesero, pero también a capitan y administrador
  // IMPORTANTE: Esperar a que se complete para asegurar que se guarde en BD
  await emitirAlerta(payload, usuarioId, ['mesero', 'capitan', 'administrador']);
  
  logger.info({ ordenId }, '✅ Alerta de preparación completada (emitida y guardada)');
};

/**
 * Obtiene alertas no leídas para un usuario
 * Si el usuario es mesero, solo retorna alertas de cocina
 */
export const obtenerAlertas = async (usuarioId: number, rol?: string): Promise<any[]> => {
  logger.info({ usuarioId, rol }, 'Obteniendo alertas para usuario');
  
  // Si es mesero, solo obtener alertas de cocina
  let alertas: any[];
  if (rol === 'mesero') {
    alertas = await obtenerAlertasNoLeidas(usuarioId, rol, TipoAlerta.COCINA);
    logger.info({ 
      usuarioId, 
      rol, 
      tipoFiltro: TipoAlerta.COCINA,
      cantidad: alertas.length 
    }, 'Alertas obtenidas para mesero');
  } else {
    alertas = await obtenerAlertasNoLeidas(usuarioId, rol);
    logger.info({ 
      usuarioId, 
      rol, 
      cantidad: alertas.length 
    }, 'Alertas obtenidas');
  }
  
  // Agregar metadatos por defecto si no existen (para compatibilidad)
  return alertas.map((alerta) => {
    // Si no tiene metadata, intentar inferirlo del mensaje
    if (!alerta.metadata) {
      const mensaje = (alerta.mensaje || '').toLowerCase();
      const metadata: any = {};
      
      if (mensaje.includes('preparación') || mensaje.includes('preparacion')) {
        metadata.estado = 'preparacion';
      } else if (mensaje.includes('listo')) {
        metadata.estado = 'listo';
      }
      
      // Intentar extraer mesaCodigo del mensaje si es posible
      const mesaMatch = mensaje.match(/mesa\s+(\w+)/i);
      if (mesaMatch) {
        metadata.mesaCodigo = mesaMatch[1];
      }
      
      // Determinar si es para llevar
      metadata.isTakeaway = alerta.mesaId == null;
      
      alerta.metadata = metadata;
    }
    
    return alerta;
  });
};

/**
 * Marca una alerta como leída
 */
export const marcarLeida = async (alertaId: number, usuarioId: number): Promise<void> => {
  await marcarAlertaLeida(alertaId, usuarioId);
};

/**
 * Marca todas las alertas no leídas como leídas para un usuario
 * Si se especifica un rol, filtra por tipo de alerta correspondiente
 */
export const marcarTodasComoLeidas = async (usuarioId: number, rol?: string): Promise<number> => {
  let tipoFiltro: string | null = null;
  
  // Si es mesero, solo marcar alertas de cocina como leídas
  if (rol === 'mesero') {
    tipoFiltro = TipoAlerta.COCINA;
  }
  
  const afectadas = await marcarTodasLasAlertasComoLeidas(usuarioId, tipoFiltro);
  logger.info({ usuarioId, rol, tipoFiltro, afectadas }, 'Todas las alertas marcadas como leídas');
  
  return afectadas;
};

/**
 * Crea una alerta desde un request HTTP
 */
export const crearAlertaDesdeRequest = async (
  body: any,
  usuarioId: number
): Promise<number> => {
  const { tipo, mensaje, ordenId, mesaId, productoId, prioridad, estacion, emisor, metadata } = body;

  // Validar campos requeridos
  if (!tipo || !mensaje) {
    throw new Error('Tipo y mensaje son requeridos');
  }

  // Construir payload
  const payload: AlertaPayload = {
    tipo: tipo as TipoAlerta,
    mensaje,
    ordenId: ordenId ? parseInt(ordenId, 10) : undefined,
    mesaId: mesaId ? parseInt(mesaId, 10) : undefined,
    productoId: productoId ? parseInt(productoId, 10) : undefined,
    prioridad: (prioridad || 'media') as 'baja' | 'media' | 'alta' | 'urgente',
    estacion: estacion || undefined,
    emisor: emisor || {
      id: usuarioId,
      username: 'Usuario',
      rol: 'mesero'
    },
    timestamp: nowMxISO(),
    metadata: metadata || {}
  };

  // Determinar roles destino según el tipo de alerta
  let rolesDestino: string[] = [];
  switch (payload.tipo) {
    case TipoAlerta.DEMORA:
    case TipoAlerta.MODIFICACION:
      rolesDestino = ['capitan', 'cocinero'];
      break;
    case TipoAlerta.CANCELACION:
      rolesDestino = ['capitan', 'cocinero', 'mesero'];
      break;
    case TipoAlerta.COCINA:
      rolesDestino = ['cocinero'];
      // Si hay estación, también emitir a esa estación específica
      if (payload.estacion) {
        rolesDestino.push(payload.estacion);
      }
      break;
    case TipoAlerta.CAJA:
      rolesDestino = ['administrador', 'cajero'];
      break;
    default:
      rolesDestino = ['cocinero'];
  }

  // Crear y emitir alerta
  await emitirAlerta(payload, usuarioId, rolesDestino);

  // Retornar el ID de la alerta creada (se obtiene del repository)
  // Como crearAlerta retorna el ID, lo obtenemos de ahí
  const alertaId = await crearAlerta(payload, usuarioId);
  return alertaId;
};

