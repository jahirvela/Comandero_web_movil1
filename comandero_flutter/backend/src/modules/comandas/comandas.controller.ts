import type { Request, Response } from 'express';
import { reimprimirComanda } from './comandas.service.js';
import { imprimirComandaSchema } from './comandas.schemas.js';
import { badRequest } from '../../utils/http-error.js';

/**
 * Handler para reimpresión manual de comanda (desde mesero)
 */
export const reimprimirComandaHandler = async (req: Request, res: Response): Promise<void> => {
  try {
    const parsed = imprimirComandaSchema.safeParse(req.body);
    if (!parsed.success) {
      throw badRequest('Datos inválidos', parsed.error.flatten().fieldErrors);
    }

    const usuarioId = req.user?.id;
    if (!usuarioId) {
      throw badRequest('Usuario no autenticado');
    }

    const resultado = await reimprimirComanda(parsed.data, usuarioId);

    if (resultado.exito) {
      res.status(200).json({
        success: true,
        data: {
          mensaje: resultado.mensaje,
          rutaArchivo: resultado.rutaArchivo
        }
      });
    } else {
      res.status(500).json({
        success: false,
        error: resultado.mensaje
      });
    }
  } catch (error: any) {
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Error al reimprimir comanda'
    });
  }
};

