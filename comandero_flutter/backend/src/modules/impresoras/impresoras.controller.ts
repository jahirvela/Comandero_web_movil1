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
