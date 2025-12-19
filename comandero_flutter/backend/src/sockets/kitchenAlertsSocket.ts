/**
 * Módulo de sockets para alertas de cocina (mesero/capitán → cocinero)
 * 
 * Este módulo maneja el flujo completo de alertas:
 * - Recepción de alertas desde mesero o capitán (kitchen:alert:create)
 * - Emisión a cocineros en rooms específicos (kitchen:alert:new)
 * - ACK de confirmación al emisor (kitchen:alert:created)
 * - Manejo de errores (kitchen:alert:error)
 * 
 * IMPORTANTE: Este es el NUEVO sistema de alertas. El sistema anterior
 * (cocina.alerta) está siendo reemplazado por este.
 */

import type { Server, Socket } from 'socket.io';
import { logger } from '../config/logger.js';
import { nowMxISO } from '../config/time.js';
import type { KitchenAlertPayload, AlertType, StationType } from '../types/kitchenAlert.js';
import { obtenerOrdenBasePorId } from '../modules/ordenes/ordenes.repository.js';
import { obtenerItemsOrden } from '../modules/ordenes/ordenes.repository.js';
import { crearAlerta } from '../modules/alertas/alertas.repository.js';

interface SocketUser {
  id: number;
  username: string;
  roles: string[];
}

/**
 * Determina la estación principal de una orden basándose en sus items
 * 
 * Reglas:
 * - Si todos los items son de la misma estación, retorna esa estación
 * - Si hay items de múltiples estaciones, retorna 'general'
 * - Si no se puede determinar, retorna 'general'
 */
function determineStationFromOrderItems(items: Array<{ productoNombre: string }>): StationType {
  if (items.length === 0) {
    return 'general';
  }

  const stations = new Set<StationType>();
  
  for (const item of items) {
    const productName = (item.productoNombre || '').toLowerCase();
    
    if (productName.includes('consom') || productName.includes('mix')) {
      stations.add('consomes');
    } else if (
      productName.includes('agua') ||
      productName.includes('horchata') ||
      productName.includes('refresco') ||
      productName.includes('bebida') ||
      productName.includes('jugo') ||
      productName.includes('soda')
    ) {
      stations.add('bebidas');
    } else {
      // Por defecto, todo lo demás va a tacos
      stations.add('tacos');
    }
  }

  // Si hay solo una estación, retornar esa
  if (stations.size === 1) {
    return Array.from(stations)[0];
  }

  // Si hay múltiples estaciones, retornar 'general'
  return 'general';
}

/**
 * Registra los handlers de Socket.IO para alertas de cocina
 * 
 * @param io - Instancia del servidor Socket.IO
 * @param socket - Socket del cliente conectado
 */
export function registerKitchenAlertsHandlers(io: Server, socket: Socket) {
  const user = (socket as Socket & { user: SocketUser }).user;
  
  if (!user) {
    logger.warn({ socketId: socket.id }, 'KitchenAlerts: Socket sin usuario autenticado');
    return;
  }

  // Listener para crear alerta desde mesero o capitán
  socket.on('kitchen:alert:create', async (data: {
    orderId: number;
    tableId?: number | null;
    station?: StationType;
    type: AlertType;
    message: string;
    priority?: string; // 'Normal' o 'Urgente'
  }) => {
    try {
      // Validar que el usuario es mesero o capitán
      if (!user.roles.includes('mesero') && !user.roles.includes('capitan')) {
        logger.warn(
          { socketId: socket.id, userId: user.id, roles: user.roles },
          'KitchenAlerts: Intento de crear alerta por usuario no autorizado (debe ser mesero o capitán)'
        );
        socket.emit('kitchen:alert:error', {
          message: 'Solo los meseros y capitanes pueden crear alertas de cocina',
          details: { userId: user.id, roles: user.roles }
        });
        return;
      }

      // Validar campos requeridos
      if (!data.orderId || !data.type || !data.message || data.message.trim().length === 0) {
        socket.emit('kitchen:alert:error', {
          message: 'Campos inválidos: orderId, type y message son requeridos',
          details: data
        });
        return;
      }

      // Determinar el rol del emisor (mesero o capitan) - debe definirse antes de usarse
      const userRole = user.roles.includes('capitan') ? 'capitan' : 'mesero';

      logger.info(
        { socketId: socket.id, userId: user.id, orderId: data.orderId, type: data.type, role: userRole },
        `KitchenAlerts: Alerta recibida desde ${userRole}`
      );

      // Obtener información de la orden
      const orden = await obtenerOrdenBasePorId(data.orderId);
      if (!orden) {
        socket.emit('kitchen:alert:error', {
          message: `Orden ${data.orderId} no encontrada`,
          details: { orderId: data.orderId }
        });
        return;
      }

      // Determinar estación si no se proporcionó
      let station: StationType = data.station || 'general';
      if (station === 'general' || !data.station) {
        // Obtener items de la orden para determinar estación
        const items = await obtenerItemsOrden(data.orderId);
        station = determineStationFromOrderItems(items);
      }

      // Obtener tableId/mesaCodigo de la orden si no se proporcionó
      let tableId = data.tableId !== undefined ? data.tableId : orden.mesaId;
      const mesaCodigo = orden.mesaCodigo; // Código de la mesa (ej: "11")
      
      // Obtener el ID real de la mesa buscando por código (más confiable que usar mesaId directo)
      // Prioridad: 1) Buscar por código, 2) Buscar por ID si no hay código, 3) null si no se encuentra
      let mesaIdParaBD: number | null = null;
      let mesaIdReal: number | null = null;
      
      if (mesaCodigo) {
        try {
          const { obtenerMesaPorCodigo } = await import('../modules/mesas/mesas.repository.js');
          const mesaPorCodigo = await obtenerMesaPorCodigo(mesaCodigo);
          if (mesaPorCodigo) {
            mesaIdReal = mesaPorCodigo.id;
            mesaIdParaBD = mesaPorCodigo.id;
            logger.info({ 
              mesaCodigo, 
              mesaIdReal: mesaPorCodigo.id, 
              ordenId: data.orderId 
            }, 'KitchenAlerts: Mesa encontrada por código');
          }
        } catch (e) {
          logger.warn({ 
            mesaCodigo, 
            ordenId: data.orderId, 
            error: e 
          }, 'KitchenAlerts: Error al buscar mesa por código');
        }
      }
      
      // Si no se encontró por código y tenemos un mesaId, intentar buscar por ID
      if (mesaIdParaBD == null && tableId != null) {
        try {
          const { obtenerMesaPorId } = await import('../modules/mesas/mesas.repository.js');
          const mesaPorId = await obtenerMesaPorId(tableId);
          if (mesaPorId) {
            mesaIdReal = mesaPorId.id;
            mesaIdParaBD = mesaPorId.id;
            logger.info({ 
              mesaId: tableId, 
              ordenId: data.orderId 
            }, 'KitchenAlerts: Mesa encontrada por ID');
          } else {
            logger.warn({ 
              mesaId: tableId, 
              mesaCodigo, 
              ordenId: data.orderId 
            }, 'KitchenAlerts: Mesa no encontrada por ID ni por código, guardando alerta sin mesa_id');
          }
        } catch (e) {
          logger.warn({ 
            mesaId: tableId, 
            ordenId: data.orderId, 
            error: e 
          }, 'KitchenAlerts: Error al buscar mesa por ID');
        }
      }
      
      // Si no se encontró mesa, usar null (para órdenes para llevar o mesas inexistentes)
      if (mesaIdParaBD == null) {
        logger.info({ 
          mesaIdOriginal: tableId, 
          mesaCodigo, 
          ordenId: data.orderId 
        }, 'KitchenAlerts: Guardando alerta sin mesa_id (mesa no encontrada o para llevar)');
      }
      
      // Actualizar tableId con el ID real si se encontró
      if (mesaIdReal != null) {
        tableId = mesaIdReal;
      }
      
      // Construir payload completo de la alerta
      const alertPayload: KitchenAlertPayload = {
        orderId: data.orderId,
        tableId: tableId,
        station: station,
        type: data.type,
        message: data.message.trim(),
        createdByUserId: user.id,
        createdAt: nowMxISO(),
        priority: data.priority || 'Normal', // Incluir prioridad, por defecto 'Normal'
        createdByUsername: user.username, // Incluir username del emisor
        createdByRole: userRole, // Incluir rol del emisor (mesero o capitan)
      };

      // CRÍTICO: Guardar la alerta en BD ANTES de emitirla
      // Esto asegura que si el cocinero no está conectado, pueda cargarla después
      let alertaId: number | null = null;
      try {
        // Construir metadata con información adicional incluyendo prioridad y emisor
        const metadata: Record<string, unknown> = {
          priority: alertPayload.priority || 'Normal',
          station: alertPayload.station,
          type: alertPayload.type,
          createdByUsername: user.username,
          createdByRole: userRole,
        };
        
        // Mapear el tipo de alerta al formato de BD
        // Las alertas de cocina se guardan como tipo 'operacion' en BD
        alertaId = await crearAlerta({
          tipo: 'operacion',
          mensaje: alertPayload.message,
          ordenId: alertPayload.orderId,
          mesaId: mesaIdParaBD, // Usar el mesaId verificado (puede ser null)
          usuarioOrigenId: user.id,
          usuarioDestinoId: null, // null = para todos los cocineros
          metadata: metadata // Guardar prioridad y otros metadatos
        });
        
        // Agregar el ID de BD al payload
        alertPayload.id = alertaId;
        
        logger.info(
          {
            socketId: socket.id,
            userId: user.id,
            orderId: alertPayload.orderId,
            alertaId: alertaId
          },
          'KitchenAlerts: Alerta guardada en BD'
        );
      } catch (error) {
        logger.error(
          {
            socketId: socket.id,
            userId: user.id,
            orderId: alertPayload.orderId,
            error
          },
          'KitchenAlerts: Error al guardar alerta en BD (continuando con emisión)'
        );
        // Continuar aunque falle el guardado en BD para no bloquear la emisión en tiempo real
      }

      logger.info(
        {
          socketId: socket.id,
          userId: user.id,
          orderId: alertPayload.orderId,
          station: alertPayload.station,
          type: alertPayload.type,
          alertaId: alertaId
        },
        'KitchenAlerts: Emitiendo alerta a cocineros'
      );

      // Obtener lista de sockets en las rooms para verificar quién está escuchando
      const socketsInAllRoom = await io.in('room:kitchen:all').fetchSockets();
      
      logger.info(
        {
          socketId: socket.id,
          userId: user.id,
          orderId: alertPayload.orderId,
          station: alertPayload.station,
          socketsInAllRoom: socketsInAllRoom.length,
          socketIds: socketsInAllRoom.map((s: any) => s.id)
        },
        'KitchenAlerts: Sockets en room:kitchen:all antes de emitir'
      );

      // Emitir a todos los cocineros (room general de cocina)
      io.to('room:kitchen:all').emit('kitchen:alert:new', alertPayload);
      
      logger.info(
        {
          socketId: socket.id,
          userId: user.id,
          orderId: alertPayload.orderId,
          room: 'room:kitchen:all',
          socketsCount: socketsInAllRoom.length
        },
        'KitchenAlerts: Alerta emitida a room:kitchen:all'
      );

      // Si la estación no es 'general', también emitir a la estación específica
      if (station !== 'general') {
        const roomName = `room:kitchen:${station}`;
        const socketsInStationRoom = await io.in(roomName).fetchSockets();
        
        io.to(roomName).emit('kitchen:alert:new', alertPayload);
        
        logger.info(
          {
            socketId: socket.id,
            userId: user.id,
            orderId: alertPayload.orderId,
            room: roomName,
            socketsCount: socketsInStationRoom.length,
            socketIds: socketsInStationRoom.map((s: any) => s.id)
          },
          `KitchenAlerts: Alerta emitida a ${roomName}`
        );
      }

      // Enviar ACK al mesero que creó la alerta
      socket.emit('kitchen:alert:created', alertPayload);

      logger.info(
        {
          socketId: socket.id,
          userId: user.id,
          orderId: alertPayload.orderId,
          station: alertPayload.station,
          rooms: station === 'general' 
            ? ['room:kitchen:all']
            : ['room:kitchen:all', `room:kitchen:${station}`]
        },
        'KitchenAlerts: Alerta emitida exitosamente'
      );
    } catch (error) {
      logger.error(
        { socketId: socket.id, userId: user.id, error, data },
        'KitchenAlerts: Error al procesar alerta'
      );
      
      socket.emit('kitchen:alert:error', {
        message: 'Error interno al procesar la alerta',
        details: error instanceof Error ? error.message : String(error)
      });
    }
  });

  // Listener opcional para ACK de cocinero (futuro)
  socket.on('kitchen:alert:ack', (data: { alertId?: number; orderId: number }) => {
    try {
      // Validar que el usuario es cocinero
      if (!user.roles.includes('cocinero')) {
        return;
      }

      logger.info(
        { socketId: socket.id, userId: user.id, data },
        'KitchenAlerts: ACK recibido de cocinero'
      );

      // Por ahora solo logueamos, en el futuro podríamos guardar en BD
      // o notificar al mesero que el cocinero vio la alerta
    } catch (error) {
      logger.error(
        { socketId: socket.id, userId: user.id, error, data },
        'KitchenAlerts: Error al procesar ACK'
      );
    }
  });
}

/**
 * Une un socket a las rooms de cocina apropiadas
 * 
 * @param socket - Socket del cliente
 */
export function joinKitchenRooms(socket: Socket) {
  const user = (socket as Socket & { user: SocketUser }).user;
  
  if (!user) {
    return;
  }

  // Si el usuario es cocinero, unirlo a la room general de cocina
  if (user.roles.includes('cocinero')) {
    socket.join('room:kitchen:all');
    
    // Verificar que se unió correctamente
    const rooms = Array.from(socket.rooms);
    
    logger.info(
      { 
        socketId: socket.id, 
        userId: user.id,
        username: user.username,
        rooms: rooms,
        joinedToKitchenAll: rooms.includes('room:kitchen:all')
      },
      'KitchenAlerts: Cocinero unido a room:kitchen:all'
    );

    // Si el cocinero tiene estaciones asignadas en el handshake, unirlo también a esas rooms
    const station = socket.handshake.auth?.station as string | undefined;
    if (station && ['tacos', 'consomes', 'bebidas'].includes(station)) {
      socket.join(`room:kitchen:${station}`);
      const roomsAfterStation = Array.from(socket.rooms);
      logger.info(
        { 
          socketId: socket.id, 
          userId: user.id,
          station,
          rooms: roomsAfterStation,
          joinedToStation: roomsAfterStation.includes(`room:kitchen:${station}`)
        },
        `KitchenAlerts: Cocinero unido a room:kitchen:${station}`
      );
    }
  } else {
    logger.info(
      { socketId: socket.id, userId: user.id, roles: user.roles },
      'KitchenAlerts: Usuario no es cocinero, no se unirá a rooms de cocina'
    );
  }
}

