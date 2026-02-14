import type { Request, Response, NextFunction } from 'express';
import { crearPagoSchema, crearPropinaSchema } from './pagos.schemas.js';
import {
  obtenerPagos,
  obtenerPago,
  crearNuevoPago,
  obtenerFormasPago,
  obtenerPropinasServicio,
  registrarPropinaServicio
} from './pagos.service.js';

export const listarPagosController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const ordenId = req.query.ordenId ? Number(req.query.ordenId) : undefined;
    const pagos = await obtenerPagos(ordenId);
    res.json({ data: pagos });
  } catch (error) {
    next(error);
  }
};

export const obtenerPagoController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = Number(req.params.id);
    const pago = await obtenerPago(id);
    res.json({ data: pago });
  } catch (error) {
    next(error);
  }
};

export const crearPagoController = async (req: Request, res: Response, next: NextFunction) => {
  try {
    // Log para debugging
    console.log('📥 CrearPagoController - Body recibido:', JSON.stringify(req.body, null, 2));
    
    const input = crearPagoSchema.parse(req.body);
    console.log('✅ CrearPagoController - Datos validados:', JSON.stringify(input, null, 2));
    
    const empleadoNombre = req.user?.nombre ?? req.user?.username ?? 'Cajero';
    const pago = await crearNuevoPago(input, req.user?.id, empleadoNombre);
    res.status(201).json({ data: pago });
  } catch (error: any) {
    // Log detallado del error para debugging
    if (error.name === 'ZodError') {
      console.error('❌ CrearPagoController - Error de validación Zod:', JSON.stringify(error.errors, null, 2));
      console.error('❌ CrearPagoController - Body recibido:', JSON.stringify(req.body, null, 2));
    } else {
      console.error('❌ CrearPagoController - Error:', error);
    }
    next(error);
  }
};

export const listarFormasPagoController = async (
  _req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const formas = await obtenerFormasPago();
    res.json({ data: formas });
  } catch (error) {
    next(error);
  }
};

export const listarPropinasController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const ordenId = req.query.ordenId ? Number(req.query.ordenId) : undefined;
    const propinas = await obtenerPropinasServicio(ordenId);
    res.json({ data: propinas });
  } catch (error) {
    next(error);
  }
};

export const registrarPropinaController = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const input = crearPropinaSchema.parse(req.body);
    const propina = await registrarPropinaServicio(input, req.user?.id);
    res.status(201).json({ data: propina });
  } catch (error) {
    next(error);
  }
};

