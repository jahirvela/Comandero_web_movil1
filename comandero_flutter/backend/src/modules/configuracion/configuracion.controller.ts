import type { Request, Response } from 'express';
import {
  obtenerConfiguracion,
  actualizarIvaHabilitado,
  actualizarConfiguracionCajon,
} from './configuracion.repository.js';
import { actualizarConfiguracionSchema } from './configuracion.schemas.js';

export const getConfiguracionController = async (_req: Request, res: Response) => {
  const config = await obtenerConfiguracion();
  res.json(config);
};

export const patchConfiguracionController = async (req: Request, res: Response) => {
  const parsed = actualizarConfiguracionSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten() });
  }
  const { ivaHabilitado, cajon } = parsed.data;
  if (ivaHabilitado !== undefined) {
    await actualizarIvaHabilitado(ivaHabilitado);
  }
  if (cajon !== undefined && Object.keys(cajon).length > 0) {
    await actualizarConfiguracionCajon(cajon);
  }
  const config = await obtenerConfiguracion();
  res.json(config);
};
