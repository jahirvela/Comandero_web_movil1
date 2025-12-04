import { 
  listarCierresCaja, 
  crearCierreCaja,
  actualizarEstadoCierreCaja,
  obtenerCierreCajaPorId,
  type CierreCajaItem,
  type CrearCierreCajaInput as CrearCierreCajaInputRepo
} from './cierres.repository.js';
import type { CrearCierreCajaInput } from './cierres.schemas.js';
import { logger } from '../../config/logger.js';
import { utcToMx } from '../../config/time.js';

export const obtenerCierresCaja = async (
  fechaInicio?: Date,
  fechaFin?: Date,
  cajeroId?: number
): Promise<CierreCajaItem[]> => {
  try {
    const cierres = await listarCierresCaja(fechaInicio, fechaFin, cajeroId);
    return cierres;
  } catch (error: any) {
    logger.error({ err: error }, 'Error al obtener cierres de caja');
    throw error;
  }
};

export const crearNuevoCierreCaja = async (
  input: CrearCierreCajaInput,
  usuarioId?: number
) => {
  try {
    // Calcular totales si no se proporcionan
    const totalPagos = input.totalPagos ?? (input.totalEfectivo ?? 0) + (input.totalTarjeta ?? 0) + (input.otrosIngresos ?? 0);
    const totalEfectivo = input.totalEfectivo ?? input.efectivoFinal ?? 0;
    const totalTarjeta = input.totalTarjeta ?? 0;

    // La fecha viene parseada del schema, la convertimos a Date si es necesario
    const fechaParseada = input.fecha instanceof Date ? input.fecha : new Date(input.fecha);
    const cierreInput: CrearCierreCajaInputRepo = {
      fecha: fechaParseada,
      efectivoInicial: input.efectivoInicial,
      efectivoFinal: input.efectivoFinal,
      totalPagos: totalPagos > 0 ? totalPagos : null,
      totalEfectivo: totalEfectivo > 0 ? totalEfectivo : null,
      totalTarjeta: totalTarjeta > 0 ? totalTarjeta : null,
      notas: input.notas ?? null,
      otrosIngresos: input.otrosIngresos,
      otrosIngresosTexto: input.otrosIngresosTexto ?? null,
      notaCajero: input.notaCajero ?? null,
      efectivoContado: input.efectivoContado ?? null,
      totalDeclarado: input.totalDeclarado ?? null
    };

    const cierre = await crearCierreCaja(cierreInput, usuarioId);
    logger.info({ cierreId: cierre.id, usuarioId }, 'Cierre de caja creado exitosamente');
    return cierre;
  } catch (error: any) {
    logger.error({ err: error }, 'Error al crear cierre de caja');
    throw error;
  }
};

export const actualizarEstadoCierre = async (
  cierreId: number,
  estado: 'pending' | 'approved' | 'rejected' | 'clarification',
  revisadoPorUsuarioId: number,
  comentarioRevision?: string | null
) => {
  try {
    await actualizarEstadoCierreCaja(cierreId, estado, revisadoPorUsuarioId, comentarioRevision);
    const cierreActualizado = await obtenerCierreCajaPorId(cierreId);
    
    logger.info({ cierreId, estado, revisadoPorUsuarioId }, 'Estado de cierre actualizado exitosamente');
    return cierreActualizado;
  } catch (error: any) {
    logger.error({ err: error, cierreId }, 'Error al actualizar estado de cierre');
    throw error;
  }
};

