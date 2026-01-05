import { getIO, getSocketRooms } from '../../realtime/socket.js';
import { logger } from '../../config/logger.js';
import { crearAlerta, obtenerAlertasNoLeidas, marcarAlertaLeida, marcarTodasLasAlertasComoLeidas } from './alertas.repository.js';
import type { AlertaPayload } from './alertas.types.js';
import { TipoAlerta } from './alertas.types.js';
import { nowMxISO } from '../../config/time.js';
import type { Server } from 'socket.io';
import { obtenerOrdenBasePorId } from '../ordenes/ordenes.repository.js';

/**
 * Emite una alerta en tiempo real y la guarda en la BD
 * OPTIMIZADO: Emite primero para respuesta inmediata, guarda después en background
 */
export const emitirAlerta = async (
  payload: AlertaPayload,
  usuarioId: number,
  rolesDestino: string[] = []
): Promise<number | null> => {
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
      // Mapear AlertaPayload a los parámetros esperados por crearAlerta
      // El tipo de BD debe ser uno de: 'sistema' | 'operacion' | 'inventario' | 'mensaje'
      let tipoBD: 'sistema' | 'operacion' | 'inventario' | 'mensaje' = 'operacion';
      if (payload.tipo === TipoAlerta.CAJA || payload.tipo === TipoAlerta.PAGO) {
        tipoBD = 'sistema';
      } else if (payload.tipo === TipoAlerta.COCINA || payload.tipo === TipoAlerta.MESA || 
                 payload.tipo === TipoAlerta.MODIFICACION || payload.tipo === TipoAlerta.DEMORA ||
                 payload.tipo === TipoAlerta.CANCELACION) {
        tipoBD = 'operacion';
      }
      
      const alertaId = await crearAlerta({
        tipo: tipoBD,
        mensaje: payload.mensaje,
        ordenId: payload.ordenId ?? null,
        mesaId: payload.mesaId ?? null,
        usuarioOrigenId: usuarioId,
        usuarioDestinoId: null
      });
      logger.info({ 
        alertaId, 
        tipo: payload.tipo, 
        ordenId: payload.ordenId,
        mensaje: payload.mensaje 
      }, '✅ Alerta guardada en BD exitosamente');
      return alertaId;
    } catch (error) {
      logger.error({ err: error, payload, usuarioId }, '❌ Error al guardar alerta en BD');
      // Continuar aunque falle - la alerta ya fue emitida por Socket.IO
      return null;
    }
  } catch (error) {
    logger.error({ err: error, payload }, 'Error al emitir alerta');
    // No lanzar error, solo loguear
    return null;
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
  // Si el cocinero cancela, el mensaje debe indicarlo específicamente para el mesero
  const rolLower = rol.toLowerCase();
  let mensaje: string;
  
  if (rolLower === 'cocinero') {
    // Mensaje específico cuando cocinero cancela: se envía principalmente al mesero
    mensaje = `Cocinero canceló la orden #${ordenId}${motivo ? `: ${motivo}` : ''}`;
  } else {
    // Mensaje genérico para otros roles
    mensaje = `Orden #${ordenId} cancelada: ${motivo}`;
  }
  
  const payload: AlertaPayload = {
    tipo: TipoAlerta.CANCELACION,
    mensaje,
    ordenId,
    prioridad: 'alta',
    emisor: {
      id: usuarioId,
      username,
      rol
    },
    timestamp: nowMxISO(),
    metadata: { motivo, canceladoPor: rol }
  };

  // Enviar a todos los roles relevantes, pero el mensaje ya está personalizado
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
  // Obtener el tiempo estimado de preparación de la orden (6 minutos por defecto)
  const { obtenerOrdenBasePorId } = await import('../ordenes/ordenes.repository.js');
  const orden = await obtenerOrdenBasePorId(ordenId);
  const tiempoEstimado = (orden as any)?.tiempoEstimadoPreparacion ?? 6; // 6 minutos por defecto
  
  // Formatear el tiempo estimado
  const tiempoNum = Number(tiempoEstimado);
  let tiempoTexto = '';
  if (tiempoNum >= 60) {
    const horas = Math.floor(tiempoNum / 60);
    const minutos = tiempoNum % 60;
    tiempoTexto = minutos > 0 
      ? ` (estimado: ${horas}h ${minutos}min)`
      : ` (estimado: ${horas}h)`;
  } else {
    tiempoTexto = ` (estimado: ${tiempoNum}min)`;
  }

  const mensaje = isTakeaway
    ? `Pedido #${ordenId} está en preparación${tiempoTexto}`
    : mesaCodigo
    ? `Pedido #${ordenId} de Mesa ${mesaCodigo} está en preparación${tiempoTexto}`
    : `Pedido #${ordenId} está en preparación${tiempoTexto}`;

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
      estado: 'preparacion',
      tiempoEstimado: Number(tiempoEstimado)
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
  
  // Si es mesero, obtener alertas de tipo 'operacion' que contengan mensajes de cocina
  // En BD se guardan como 'operacion', no como 'alerta.cocina'
  let alertas: any[];
  if (rol === 'mesero') {
    // NO filtrar por tipo en BD, obtener todas las alertas 'operacion' y filtrar por mensaje después
    // o mejor: obtener todas y filtrar las que son relevantes para mesero (preparación, listo, cancelación, etc.)
    alertas = await obtenerAlertasNoLeidas(usuarioId, rol, 'operacion');
    // Filtrar solo las que tienen mensajes relacionados con cocina (preparación, listo, cancelación, etc.)
    alertas = alertas.filter(alerta => {
      const mensaje = (alerta.mensaje || '').toLowerCase();
      return mensaje.includes('preparación') || 
             mensaje.includes('preparacion') || 
             mensaje.includes('listo') || 
             mensaje.includes('ready') ||
             mensaje.includes('cancel') ||
             mensaje.includes('cancelación') ||
             mensaje.includes('cancelado');
    });
    logger.info({ 
      usuarioId, 
      rol, 
      tipoFiltro: 'operacion',
      cantidad: alertas.length 
    }, 'Alertas obtenidas para mesero');
  } else if (rol === 'cocinero') {
    // Para cocinero, obtener alertas de tipo 'operacion' que sean de meseros hacia cocina
    // Estas son las alertas que el mesero envía directamente a cocina (demora, cancelación, etc.)
    alertas = await obtenerAlertasNoLeidas(usuarioId, rol, 'operacion');
    
    // Obtener estado "cancelada" para filtrar alertas de órdenes canceladas
    const { obtenerEstadoOrdenPorNombre } = await import('../ordenes/ordenes.repository.js');
    const estadoCancelada = await obtenerEstadoOrdenPorNombre('cancelada');
    const estadoCanceladaId = estadoCancelada?.id;
    
    // Filtrar solo las que son alertas de mesero hacia cocina (contienen palabras clave)
    // Y que NO sean de órdenes canceladas
    alertas = await Promise.all(
      alertas.map(async (alerta) => {
        const mensaje = (alerta.mensaje || '').toLowerCase();
        // Verificar si contiene palabras clave de alertas de cocina
        const esAlertaRelevante = mensaje.includes('demora') || 
                                  mensaje.includes('cancel') || 
                                  mensaje.includes('cambio') || 
                                  mensaje.includes('tiempo de espera') ||
                                  mensaje.includes('mucho tiempo');
        
        if (!esAlertaRelevante) return null;
        
        // Si la alerta es sobre una orden cancelada, verificar que la orden esté cancelada
        // Si está cancelada, excluirla (ya no es relevante)
        if (alerta.ordenId && estadoCanceladaId) {
          try {
            const { obtenerOrdenBasePorId } = await import('../ordenes/ordenes.repository.js');
            const orden = await obtenerOrdenBasePorId(alerta.ordenId);
            if (orden && orden.estadoOrdenId === estadoCanceladaId) {
              // Orden cancelada, excluir esta alerta
              return null;
            }
          } catch (e) {
            // Si hay error al obtener la orden, incluir la alerta por seguridad
            logger.warn({ alertaId: alerta.id, ordenId: alerta.ordenId, error: e }, 'Error al verificar estado de orden para alerta');
          }
        }
        
        return alerta;
      })
    );
    
    // Filtrar valores null
    alertas = alertas.filter((a): a is NonNullable<typeof a> => a !== null);
    
    logger.info({ 
      usuarioId, 
      rol, 
      tipoFiltro: 'operacion',
      cantidad: alertas.length 
    }, 'Alertas obtenidas para cocinero (filtradas por órdenes canceladas)');
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
  
  // Si es mesero, marcar alertas de tipo 'operacion' como leídas (en BD se guardan así)
  if (rol === 'mesero') {
    tipoFiltro = 'operacion';
  }
  
  const afectadas = await marcarTodasLasAlertasComoLeidas(usuarioId, tipoFiltro);
  logger.info({ usuarioId, rol, tipoFiltro, afectadas }, 'Todas las alertas marcadas como leídas');
  
  return afectadas;
};

/**
 * DTO para alertas de cocina
 */
export interface AlertaCocinaDTO {
  id: number;
  usuarioOrigenId: number;
  usuarioDestinoId: number | null;
  mesaId: number | null;
  ordenId: number | null;
  tipo: string;      // 'operacion' | 'mensaje' | 'inventario' | 'sistema'
  mensaje: string;
  creadoEn: string;
}

/**
 * Crea una alerta de mesero hacia cocinero y la emite en tiempo real
 * Este método centraliza la creación y emisión para evitar duplicados
 * 
 * IMPORTANTE: Obtiene la mesa real de la orden para respetar la FK fk_alerta_mesa
 */
export async function crearYEmitirAlertaCocina(
  params: {
    usuarioOrigenId: number;
    ordenId: number;
    tipoAlerta: string;   // p.ej. 'alerta.demora', 'alerta.cancelacion'
    mensaje: string;
  },
  io: Server
): Promise<AlertaCocinaDTO> {
  // 1. Obtener la orden real para sacar el mesa_id correcto
  const orden = await obtenerOrdenBasePorId(params.ordenId);
  if (!orden) {
    throw new Error(`Orden ${params.ordenId} no encontrada`);
  }

  // 2. Sacar la mesa REAL de la orden (puede ser null si es para llevar)
  const mesaIdReal: number | null = orden.mesaId ?? null;

  // 3. Mapear tipoAlerta de UI → ENUM de la tabla alerta
  //    Por ahora, todas las alertas manuales Mesero→Cocina se guardan como 'operacion'
  const tipoBD: 'operacion' | 'mensaje' | 'inventario' | 'sistema' = 'operacion';

  // 4. Crear alerta en la BD (USANDO mesaIdReal)
  const alertaId = await crearAlerta({
    tipo: tipoBD,
    mensaje: params.mensaje,
    ordenId: params.ordenId,
    mesaId: mesaIdReal,
    usuarioOrigenId: params.usuarioOrigenId,
    usuarioDestinoId: null
  });

  logger.info({ 
    alertaId, 
    usuarioOrigenId: params.usuarioOrigenId,
    ordenId: params.ordenId,
    mesaIdReal,
    tipoBD,
    tipoAlerta: params.tipoAlerta,
    mensaje: params.mensaje
  }, '✅ Alerta de cocina guardada en BD');

  // 5. Mapear la fila resultante a AlertaCocinaDTO
  const alertaDTO: AlertaCocinaDTO = {
    id: alertaId,
    usuarioOrigenId: params.usuarioOrigenId,
    usuarioDestinoId: null,
    mesaId: mesaIdReal,
    ordenId: params.ordenId,
    tipo: tipoBD,
    mensaje: params.mensaje,
    creadoEn: nowMxISO()
  };

  // 6. Emitir evento Socket.IO solo a cocineros
  const roomName = getSocketRooms.role('cocinero');
  const socketsInRoom = await io.in(roomName).fetchSockets();
  
  // Emitir con el tipo original (alerta.demora, etc.) para que el frontend lo procese
  io.to(roomName).emit('cocina.alerta', {
    id: alertaId,
    tipo: params.tipoAlerta, // Tipo original del frontend para procesamiento
    mensaje: params.mensaje,
    ordenId: params.ordenId,
    mesaId: mesaIdReal,
    mesaCodigo: orden.mesaCodigo, // Incluir código de mesa para mostrar en UI
    timestamp: alertaDTO.creadoEn,
    emisor: {
      id: params.usuarioOrigenId,
      username: 'Mesero'
    }
  });
  
  logger.info({ 
    alertaId,
    room: roomName,
    socketsCount: socketsInRoom.length,
    tipoAlerta: params.tipoAlerta,
    mensaje: params.mensaje
  }, `🔔 Alerta "${params.tipoAlerta}" emitida a role:cocinero`);

  // 7. Retornar alertaDTO
  return alertaDTO;
}

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

  // Crear y emitir alerta (ya guarda en BD y retorna el ID)
  const alertaId = await emitirAlerta(payload, usuarioId, rolesDestino);
  
  // Si no se pudo crear (error en BD), lanzar error
  if (!alertaId) {
    throw new Error('Error al guardar alerta en la base de datos');
  }
  
  return alertaId;
};

