import {
  listarReservas,
  obtenerReservaPorId,
  crearReserva,
  actualizarReserva,
  eliminarReserva,
  type ReservaItem,
} from './reservas.repository.js';
import type { CrearReservaInput, ActualizarReservaInput, ListarReservasInput } from './reservas.schemas.js';
import { notFound, badRequest } from '../../utils/http-error.js';
import { logger } from '../../config/logger.js';
import { obtenerMesaPorId } from '../mesas/mesas.repository.js';
import { parseMxToUtc, utcToMx } from '../../config/time.js';

export const obtenerReservas = async (input: ListarReservasInput): Promise<ReservaItem[]> => {
  try {
    const reservas = await listarReservas(
      input.mesaId,
      input.fechaInicio,
      input.fechaFin,
      input.estado
    );
    return reservas;
  } catch (error: any) {
    logger.error({ err: error }, 'Error al obtener reservas');
    throw error;
  }
};

export const obtenerReserva = async (id: number): Promise<ReservaItem> => {
  const reserva = await obtenerReservaPorId(id);
  if (!reserva) {
    throw notFound('Reserva no encontrada');
  }
  return reserva;
};

export const crearNuevaReserva = async (
  input: CrearReservaInput,
  usuarioId?: number
): Promise<ReservaItem> => {
  try {
    // Verificar que la mesa existe
    const mesa = await obtenerMesaPorId(input.mesaId);
    if (!mesa) {
      throw badRequest('La mesa especificada no existe');
    }

    // Validar que la fecha de inicio sea anterior a la de fin (si se proporciona)
    // Las fechas vienen en formato ISO y se interpretan como zona CDMX, convertir a UTC para guardar
    const fechaInicioUtc = parseMxToUtc(input.fechaHoraInicio);
    if (!fechaInicioUtc) {
      throw badRequest('Fecha de inicio inválida');
    }
    const fechaInicio = fechaInicioUtc.toJSDate();
    
    if (input.fechaHoraFin) {
      const fechaFinUtc = parseMxToUtc(input.fechaHoraFin);
      if (!fechaFinUtc) {
        throw badRequest('Fecha de fin inválida');
      }
      if (fechaFinUtc <= fechaInicioUtc) {
        throw badRequest('La fecha de fin debe ser posterior a la fecha de inicio');
      }
    }

    // Validar que no haya conflictos de reserva para la misma mesa en el mismo horario
    const reservasExistentes = await listarReservas(
      input.mesaId,
      fechaInicio,
      input.fechaHoraFin ? parseMxToUtc(input.fechaHoraFin)?.toJSDate() : undefined,
      'confirmada'
    );

    // Verificar conflictos (simplificado: si hay alguna reserva confirmada en el rango)
    for (const reserva of reservasExistentes) {
      if (reserva.estado === 'confirmada') {
        const reservaInicioMx = utcToMx(reserva.fechaHoraInicio);
        const reservaFinMx = reserva.fechaHoraFin 
          ? utcToMx(reserva.fechaHoraFin) 
          : reservaInicioMx?.plus({ hours: 2 }); // 2 horas por defecto
        
        const inputInicioMx = utcToMx(fechaInicio);
        const inputFinMx = input.fechaHoraFin ? parseMxToUtc(input.fechaHoraFin) : null;
        
        if (reservaInicioMx && reservaFinMx && inputInicioMx) {
          // Verificar solapamiento
          if (
            (inputInicioMx >= reservaInicioMx && inputInicioMx < reservaFinMx) ||
            (inputFinMx && inputFinMx > reservaInicioMx && inputFinMx <= reservaFinMx) ||
            (inputInicioMx <= reservaInicioMx && inputFinMx && inputFinMx >= reservaFinMx)
          ) {
            throw badRequest('Ya existe una reserva confirmada para esta mesa en el horario seleccionado');
          }
        }
      }
    }

    const reservaId = await crearReserva({
      mesaId: input.mesaId,
      nombreCliente: input.nombreCliente ?? null,
      telefono: input.telefono ?? null,
      fechaHoraInicio: fechaInicio,
      fechaHoraFin: input.fechaHoraFin ? parseMxToUtc(input.fechaHoraFin)?.toJSDate() ?? null : null,
      estado: input.estado ?? 'pendiente',
      creadoPorUsuarioId: usuarioId ?? null,
    });

    const reserva = await obtenerReserva(reservaId);
    logger.info({ reservaId: reserva.id, mesaId: input.mesaId }, 'Reserva creada exitosamente');
    return reserva;
  } catch (error: any) {
    logger.error({ err: error }, 'Error al crear reserva');
    throw error;
  }
};

export const actualizarReservaExistente = async (
  id: number,
  input: ActualizarReservaInput,
  usuarioId?: number
): Promise<ReservaItem> => {
  try {
    const reservaExistente = await obtenerReservaPorId(id);
    if (!reservaExistente) {
      throw notFound('Reserva no encontrada');
    }

    // Validaciones similares a crear
    if (input.mesaId !== undefined) {
      const mesa = await obtenerMesaPorId(input.mesaId);
      if (!mesa) {
        throw badRequest('La mesa especificada no existe');
      }
    }

    // Convertir fechas de CDMX a UTC para guardar
    const fechaInicioUtc = input.fechaHoraInicio ? parseMxToUtc(input.fechaHoraInicio)?.toJSDate() : undefined;
    const fechaFinUtc = input.fechaHoraFin !== undefined 
      ? (input.fechaHoraFin ? parseMxToUtc(input.fechaHoraFin)?.toJSDate() ?? null : null) 
      : undefined;
    
    const fechaInicioFinal = fechaInicioUtc ?? reservaExistente.fechaHoraInicio;
    const fechaFinFinal = fechaFinUtc !== undefined ? fechaFinUtc : reservaExistente.fechaHoraFin;

    if (fechaFinFinal && fechaFinFinal <= fechaInicioFinal) {
      throw badRequest('La fecha de fin debe ser posterior a la fecha de inicio');
    }

    await actualizarReserva(id, {
      mesaId: input.mesaId,
      nombreCliente: input.nombreCliente,
      telefono: input.telefono,
      fechaHoraInicio: fechaInicioUtc,
      fechaHoraFin: fechaFinUtc,
      estado: input.estado,
    });

    const reserva = await obtenerReserva(id);
    logger.info({ reservaId: id }, 'Reserva actualizada exitosamente');
    return reserva;
  } catch (error: any) {
    logger.error({ err: error }, 'Error al actualizar reserva');
    throw error;
  }
};

export const eliminarReservaExistente = async (id: number): Promise<void> => {
  try {
    const reserva = await obtenerReservaPorId(id);
    if (!reserva) {
      throw notFound('Reserva no encontrada');
    }

    await eliminarReserva(id);
    logger.info({ reservaId: id }, 'Reserva eliminada exitosamente');
  } catch (error: any) {
    logger.error({ err: error }, 'Error al eliminar reserva');
    throw error;
  }
};

