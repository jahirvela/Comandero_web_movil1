import type { Server as IOServer, Socket } from 'socket.io';
import { verifyAccessToken } from '../utils/jwt.js';
import { logger } from '../config/logger.js';
import { nowMxISO } from '../config/time.js';

interface SocketUser {
  id: number;
  username: string;
  roles: string[];
}

let ioInstance: IOServer | null = null;

const SOCKET_ROOM_ROLE_PREFIX = 'role:';
const SOCKET_ROOM_STATION_PREFIX = 'station:';

const authenticateSocket = (socket: Socket): SocketUser | null => {
  const token =
    (socket.handshake.auth?.token as string | undefined) ||
    (socket.handshake.headers.authorization?.split(' ')[1] as string | undefined);

  if (!token) {
    return null;
  }

  const { valid, decoded } = verifyAccessToken(token);
  if (!valid || !decoded) {
    return null;
  }

  return {
    id: decoded.sub,
    username: decoded.username,
    roles: decoded.roles
  };
};

const handleConnection = (socket: Socket) => {
  const user = authenticateSocket(socket);

  if (!user) {
    logger.warn({ socketId: socket.id }, 'Socket rechazado por token inválido');
    socket.emit('error', { message: 'Token inválido' });
    socket.disconnect(true);
    return;
  }

  (socket as Socket & { user: SocketUser }).user = user;

  user.roles.forEach((role) => {
    socket.join(`${SOCKET_ROOM_ROLE_PREFIX}${role}`);
  });

  const station = socket.handshake.auth?.station as string | undefined;
  if (station) {
    socket.join(`${SOCKET_ROOM_STATION_PREFIX}${station}`);
  }

  logger.info(
    { socketId: socket.id, userId: user.id, roles: user.roles, rooms: Array.from(socket.rooms) },
    'Cliente Socket.IO autenticado'
  );

  socket.emit('connected', {
    socketId: socket.id,
    user
  });

  // Handler para alertas de cocina (del capitán, mesero, etc.)
  socket.on('cocina.alerta', (payload: { 
    mensaje: string; 
    estacion?: string;
    tipo?: string;
    ordenId?: number;
    mesaId?: number;
    prioridad?: string;
    metadata?: Record<string, any>;
  }) => {
    const targetRoom =
      payload.estacion && payload.estacion.length > 0
        ? `${SOCKET_ROOM_STATION_PREFIX}${payload.estacion}`
        : `${SOCKET_ROOM_ROLE_PREFIX}cocinero`;

    const alertData = {
      mensaje: payload.mensaje,
      tipo: payload.tipo ?? 'alerta.cocina',
      ordenId: payload.ordenId ?? null,
      mesaId: payload.mesaId ?? null,
      prioridad: payload.prioridad ?? 'media',
      emisor: {
        id: user.id,
        username: user.username
      },
      estacion: payload.estacion ?? null,
      metadata: payload.metadata ?? {},
      timestamp: nowMxISO()
    };

    logger.info({ 
      socketId: socket.id, 
      userId: user.id, 
      tipo: alertData.tipo,
      ordenId: alertData.ordenId,
      mesaId: alertData.mesaId 
    }, '🔔 Alerta de cocina recibida');

    // Emitir a cocina
    socket.to(targetRoom).emit('cocina.alerta', alertData);
    
    // También emitir al administrador para supervisión
    socket.to(`${SOCKET_ROOM_ROLE_PREFIX}administrador`).emit('cocina.alerta', alertData);
    
    // También emitir al capitán para que pueda ver todas las alertas
    socket.to(`${SOCKET_ROOM_ROLE_PREFIX}capitan`).emit('cocina.alerta', alertData);
    
    logger.info({ targetRoom }, '📤 Alerta emitida a cocina, admin y capitán');
  });

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
    const user = authenticateSocket(socket);
    if (!user) {
      return next(new Error('UNAUTHORIZED'));
    }
    (socket as Socket & { user: SocketUser }).user = user;
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

