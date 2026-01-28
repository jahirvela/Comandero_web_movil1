import { obtenerOrdenDetalle } from '../ordenes/ordenes.service.js';
import { imprimirComanda } from './comandas.printer.js';
import { verificarComandaImpresa, marcarComandaImpresa } from './comandas.repository.js';
import { logger } from '../../config/logger.js';
import { notFound } from '../../utils/http-error.js';
import type { ImprimirComandaInput } from './comandas.schemas.js';

/**
 * Imprime una comanda automáticamente (solo si no ha sido impresa antes)
 */
export const imprimirComandaAutomatica = async (
  ordenId: number
): Promise<{ exito: boolean; mensaje: string; rutaArchivo?: string }> => {
  try {
    // Verificar si ya fue impresa
    const yaImpresa = await verificarComandaImpresa(ordenId);
    if (yaImpresa) {
      logger.info({ ordenId }, '⏭️ Comanda ya fue impresa anteriormente, omitiendo impresión automática');
      return {
        exito: true,
        mensaje: 'Comanda ya fue impresa anteriormente'
      };
    }

    // Obtener datos de la orden
    const orden = await obtenerOrdenDetalle(ordenId);
    if (!orden) {
      throw notFound('Orden no encontrada');
    }

    // Imprimir comanda
    const resultado = await imprimirComanda(orden, false);

    // Marcar como impresa solo si la impresión fue exitosa
    if (resultado.exito) {
      await marcarComandaImpresa(ordenId, null, false);
    }

    return resultado;
  } catch (error: any) {
    logger.error({ err: error, ordenId }, 'Error en impresión automática de comanda');
    return {
      exito: false,
      mensaje: error.message || 'Error al imprimir comanda automáticamente'
    };
  }
};

/**
 * Reimprime una comanda manualmente (desde mesero)
 */
export const reimprimirComanda = async (
  input: ImprimirComandaInput,
  usuarioId: number
): Promise<{ exito: boolean; mensaje: string; rutaArchivo?: string }> => {
  try {
    // Obtener datos de la orden
    const orden = await obtenerOrdenDetalle(input.ordenId);
    if (!orden) {
      throw notFound('Orden no encontrada');
    }

    // Imprimir comanda (reimpresión)
    const resultado = await imprimirComanda(orden, true);

    // Marcar como reimpresa solo si la impresión fue exitosa
    if (resultado.exito) {
      await marcarComandaImpresa(input.ordenId, usuarioId, true);
    }

    logger.info(
      { ordenId: input.ordenId, usuarioId, esReimpresion: true },
      '✅ Comanda reimpresa manualmente'
    );

    return resultado;
  } catch (error: any) {
    logger.error({ err: error, ordenId: input.ordenId, usuarioId }, 'Error en reimpresión manual de comanda');
    return {
      exito: false,
      mensaje: error.message || 'Error al reimprimir comanda'
    };
  }
};

