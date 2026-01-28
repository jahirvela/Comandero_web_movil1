import type { Server as IOServer, Socket } from 'socket.io';
import { verifyAccessToken } from '../utils/jwt.js';
import { logger } from '../config/logger.js';
import { nowMxISO } from '../config/time.js';
import { registerKitchenAlertsHandlers, joinKitchenRooms } from '../sockets/kitchenAlertsSocket.js';

interface SocketUser {
  id: number;
  username: string;
  roles: string[];
  station?: string | null; // Estación opcional del usuario (puede venir del JWT)
}

let ioInstance: IOServer | null = null;

const SOCKET_ROOM_ROLE_PREFIX = 'role:';
const SOCKET_ROOM_STATION_PREFIX = 'station:';

/**
 * Autentica un socket usando SOLO el JWT del token.
 * NO confía en ningún dato enviado por el cliente (userId, role, etc.)
 * La única fuente de verdad es el JWT verificado.
 */
const authenticateSocket = (socket: Socket): SocketUser | null => {
  // CRÍTICO: Solo obtener el token, NO otros datos del cliente
  const token =
    (socket.handshake.auth?.token as string | undefined) ||
    (socket.handshake.query?.token as string | undefined) ||
    (socket.handshake.headers.authorization?.split(' ')[1] as string | undefined);

  if (!token) {
    logger.warn({ socketId: socket.id }, 'Socket rechazado: No hay token en handshake');
    return null;
  }

  // Verificar el JWT con la clave secreta del servidor
  const { valid, decoded } = verifyAccessToken(token);
  if (!valid || !decoded) {
    logger.warn({ socketId: socket.id }, 'Socket rechazado: Token inválido o expirado');
    return null;
  }

  // La única fuente de verdad es el JWT decodificado
  const user: SocketUser = {
    id: decoded.sub,        // userId desde JWT
    username: decoded.username || 'usuario',
    roles: decoded.roles || [],
    station: (decoded as any)?.station || null // Estación opcional del JWT
  };

  logger.info({ 
    socketId: socket.id, 
    userId: user.id, 
    username: user.username, 
    roles: user.roles,
    tokenSource: 'JWT_VERIFIED'
  }, '✅ Socket autenticado correctamente (solo JWT)');

  return user;
};

const handleConnection = (socket: Socket) => {
  // CRÍTICO: Re-autenticar SIEMPRE usando el token del handshake actual
  // No confiar en socket.user del middleware porque puede estar en caché
  const user = authenticateSocket(socket);
  
  if (!user) {
    logger.warn({ socketId: socket.id }, 'Socket rechazado: No hay usuario autenticado');
    socket.emit('error', { message: 'Token inválido' });
    socket.disconnect(true);
    return;
  }
  
  // Asignar el usuario autenticado al socket
  (socket as Socket & { user: SocketUser }).user = user;
  
  // Logging adicional para debugging
  logger.info({ 
    socketId: socket.id, 
    userId: user.id, 
    username: user.username, 
    roles: user.roles 
  }, '🔐 handleConnection: Usuario autenticado y asignado al socket');

  // Room por usuario
  socket.join(`user:${user.id}`);

  // Rooms por rol
  if (Array.isArray(user.roles)) {
    for (const role of user.roles) {
      const normalizedRole = typeof role === 'string' ? role.toLowerCase() : String(role);
      socket.join(`${SOCKET_ROOM_ROLE_PREFIX}${normalizedRole}`);
    }
  }

  // Station puede venir del user (ya viene del JWT en authenticateSocket)
  // o del handshake como fallback (opcional, no crítico para auth)
  const station = user.station || 
                  (socket.handshake.auth?.station as string | undefined);
  if (station) {
    socket.join(`${SOCKET_ROOM_STATION_PREFIX}${station}`);
  }

  logger.info(
    { socketId: socket.id, userId: user.id, roles: user.roles, rooms: Array.from(socket.rooms) },
    'Cliente Socket.IO autenticado'
  );

  // CRÍTICO: Emitir el evento 'connected' con el usuario correcto
  // Asegurarse de que el objeto user tenga la estructura correcta
  const connectedUser = {
    id: user.id,
    username: user.username,
    roles: user.roles
  };
  
  logger.info({ 
    socketId: socket.id, 
    connectedUser 
  }, '📤 Emitiendo evento connected con usuario');
  
  socket.emit('connected', {
    socketId: socket.id,
    user: connectedUser
  });

  // ============================================
  // NUEVO SISTEMA DE ALERTAS DE COCINA
  // ============================================
  // Unir a rooms de cocina según el rol y estaciones del usuario
  joinKitchenRooms(socket);
  
  // Registrar handlers para el nuevo sistema de alertas
  // IMPORTANTE: getIO() debe ser llamado aquí porque ioInstance ya está inicializado
  const io = getIO();
  registerKitchenAlertsHandlers(io, socket);

  // ============================================
  // CÓDIGO VIEJO DE ALERTAS (DEPRECADO)
  // ============================================
  // TODO: Este handler antiguo (cocina.alerta) será eliminado después de verificar
  // que el nuevo sistema funciona correctamente. Por ahora se mantiene para compatibilidad.
  // 
  // El nuevo sistema usa:
  // - Eventos: kitchen:alert:create, kitchen:alert:new, kitchen:alert:created
  // - Rooms: room:kitchen:all, room:kitchen:tacos, room:kitchen:consomes, room:kitchen:bebidas
  //
  // socket.on('cocina.alerta', (payload: { 
  //   mensaje: string; 
  //   estacion?: string;
  //   tipo?: string;
  //   ordenId?: number;
  //   mesaId?: number;
  //   prioridad?: string;
  //   metadata?: Record<string, any>;
  // }) => {
  //   ... código antiguo comentado ...
  // });

  // Handler para re-emitir cuenta.enviada del mesero al cajero y admin
  socket.on('cuenta.enviada', (payload: any) => {
    logger.info({ socketId: socket.id, userId: user.id, ordenId: payload.ordenId }, '📄 Cuenta enviada por mesero');
    
    const billData = {
      ...payload,
      emisor: {
        id: user.id,
        username: user.username
      },
      timestamp: nowMxISO()
    };

    // Obtener IO instance para broadcast
    const io = getIO();
    
    // Emitir al cajero (a todos los sockets en el room)
    io.to(`${SOCKET_ROOM_ROLE_PREFIX}cajero`).emit('cuenta.enviada', billData);
    logger.info('📤 Emitido cuenta.enviada a room: role:cajero');
    
    // Emitir al administrador para supervisión
    io.to(`${SOCKET_ROOM_ROLE_PREFIX}administrador`).emit('cuenta.enviada', billData);
    logger.info('📤 Emitido cuenta.enviada a room: role:administrador');
    
    // Emitir al capitán
    io.to(`${SOCKET_ROOM_ROLE_PREFIX}capitan`).emit('cuenta.enviada', billData);
    logger.info('📤 Emitido cuenta.enviada a room: role:capitan');
    
    logger.info({ ordenId: payload.ordenId, tableNumber: payload.tableNumber }, '✅ Cuenta re-emitida a cajero, admin y capitán');
  });

  socket.on('disconnect', (reason) => {
    logger.info({ socketId: socket.id, reason }, 'Cliente Socket.IO desconectado');
  });
};

export const initRealtime = (io: IOServer) => {
  ioInstance = io;
  io.use((socket, next) => {
    // CRÍTICO: Leer el token SIEMPRE directamente del handshake en cada conexión
    // No usar ningún caché o estado previo
    const token =
      (socket.handshake.auth?.token as string | undefined) ||
      (socket.handshake.headers.authorization?.split(' ')[1] as string | undefined);

    if (!token) {
      logger.warn({ socketId: socket.id }, 'Socket rechazado en middleware: No hay token');
      return next(new Error('UNAUTHORIZED'));
    }
    
    // Verificar el JWT - esta es la ÚNICA fuente de verdad
    const { valid, decoded } = verifyAccessToken(token);
    if (!valid || !decoded) {
      logger.warn({ socketId: socket.id }, 'Socket rechazado en middleware: Token inválido o expirado');
      return next(new Error('UNAUTHORIZED'));
    }

    // Extraer usuario SOLO del JWT verificado, ignorar cualquier dato del cliente
    const user: SocketUser = {
      id: decoded.sub,
      username: decoded.username || 'usuario',
      roles: decoded.roles || [],
      station: (decoded as any)?.station || null // Estación opcional del JWT
    };

    // Asignar usuario al socket (esto es lo que usaremos en todas partes)
    (socket as Socket & { user: SocketUser }).user = user;
    
    logger.info({ 
      socketId: socket.id, 
      userId: user.id, 
      username: user.username, 
      roles: user.roles,
      source: 'JWT_VERIFIED_ONLY'
    }, '✅ Middleware: Socket autenticado (solo JWT)');
    
    return next();
  });

  io.on('connection', handleConnection);
};

export const getIO = () => {
  if (!ioInstance) {
    throw new Error('Socket.IO no inicializado');
  }
  return ioInstance;
};

export const getSocketRooms = {
  role: (role: string) => `${SOCKET_ROOM_ROLE_PREFIX}${role}`,
  station: (station: string) => `${SOCKET_ROOM_STATION_PREFIX}${station}`
};

