import type { Request, Response } from 'express';
import {
  listarImpresoras,
  obtenerImpresoraPorId,
  crearImpresora,
  actualizarImpresora,
  eliminarImpresora,
  type CrearImpresoraInput,
  type ActualizarImpresoraInput,
} from './impresoras.repository.js';
import {
  listarPendientesPorImpresora,
  marcarImpreso,
  marcarError,
  obtenerJobPorId,
} from './cola-impresion.repository.js';
import { generarClaveAgente } from './impresoras.repository.js';
import { crearImpresoraSchema, actualizarImpresoraSchema } from './impresoras.schemas.js';

export async function listarImpresorasController(_req: Request, res: Response) {
  const list = await listarImpresoras();
  res.json(list);
}

export async function obtenerImpresoraController(req: Request, res: Response) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id < 1) {
    return res.status(400).json({ error: 'ID de impresora inválido' });
  }
  const impresora = await obtenerImpresoraPorId(id);
  if (!impresora) {
    return res.status(404).json({ error: 'Impresora no encontrada' });
  }
  res.json(impresora);
}

export async function crearImpresoraController(req: Request, res: Response) {
  const parsed = crearImpresoraSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten() });
  }
  const data = parsed.data as CrearImpresoraInput;
  const id = await crearImpresora(data);
  const impresora = await obtenerImpresoraPorId(id);
  res.status(201).json(impresora!);
}

export async function actualizarImpresoraController(req: Request, res: Response) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id < 1) {
    return res.status(400).json({ error: 'ID de impresora inválido' });
  }
  const parsed = actualizarImpresoraSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten() });
  }
  const updated = await actualizarImpresora(id, parsed.data as ActualizarImpresoraInput);
  if (!updated) {
    return res.status(404).json({ error: 'Impresora no encontrada' });
  }
  const impresora = await obtenerImpresoraPorId(id);
  res.json(impresora!);
}

export async function eliminarImpresoraController(req: Request, res: Response) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id < 1) {
    return res.status(400).json({ error: 'ID de impresora inválido' });
  }
  const deleted = await eliminarImpresora(id);
  if (!deleted) {
    return res.status(404).json({ error: 'Impresora no encontrada' });
  }
  res.status(204).send();
}

/** GET /impresoras/cola/pendientes?impresora_id=1 - Para el agente local (USB remoto). */
export async function colaPendientesController(req: Request, res: Response) {
  const impresoraId = Number(req.query.impresora_id);
  if (!Number.isInteger(impresoraId) || impresoraId < 1) {
    return res.status(400).json({ error: 'impresora_id requerido y debe ser un entero positivo' });
  }
  if (req.impresoraAgenteId != null && req.impresoraAgenteId !== impresoraId) {
    return res.status(403).json({ error: 'Solo puede consultar la cola de su impresora' });
  }
  const jobs = await listarPendientesPorImpresora(impresoraId);
  res.json({ data: jobs });
}

/** POST /impresoras/cola/job/:id/impreso - Marcar trabajo como impreso (agente local). */
export async function colaMarcarImpresoController(req: Request, res: Response) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id < 1) {
    return res.status(400).json({ error: 'ID de trabajo inválido' });
  }
  if (req.impresoraAgenteId != null) {
    const job = await obtenerJobPorId(id);
    if (!job || job.impresoraId !== req.impresoraAgenteId) {
      return res.status(403).json({ error: 'El trabajo no pertenece a su impresora' });
    }
  }
  const ok = await marcarImpreso(id);
  if (!ok) {
    return res.status(404).json({ error: 'Trabajo no encontrado o ya procesado' });
  }
  res.json({ success: true });
}

/** POST /impresoras/cola/job/:id/error - Marcar trabajo con error (agente local). Body: { mensaje?: string } */
export async function colaMarcarErrorController(req: Request, res: Response) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id < 1) {
    return res.status(400).json({ error: 'ID de trabajo inválido' });
  }
  if (req.impresoraAgenteId != null) {
    const job = await obtenerJobPorId(id);
    if (!job || job.impresoraId !== req.impresoraAgenteId) {
      return res.status(403).json({ error: 'El trabajo no pertenece a su impresora' });
    }
  }
  const mensaje = (req.body?.mensaje as string) || 'Error al imprimir';
  const ok = await marcarError(id, mensaje);
  if (!ok) {
    return res.status(404).json({ error: 'Trabajo no encontrado o ya procesado' });
  }
  res.json({ success: true });
}

/** POST /impresoras/:id/generar-clave-agente - Genera clave para el agente (solo se muestra una vez). */
export async function generarClaveAgenteController(req: Request, res: Response) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id < 1) {
    return res.status(400).json({ error: 'ID de impresora inválido' });
  }
  const clave = await generarClaveAgente(id);
  if (!clave) {
    return res.status(404).json({ error: 'Impresora no encontrada' });
  }
  res.json({ clave });
}
