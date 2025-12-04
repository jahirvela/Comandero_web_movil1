import type { Request, Response } from 'express';
import {
  generarReporteVentasPDF,
  generarReporteVentasCSV,
  generarReporteTopProductosPDF,
  generarReporteTopProductosCSV,
  generarCorteCajaPDF,
  generarCorteCajaCSV,
  generarReporteInventarioPDF,
  generarReporteInventarioCSV
} from './reportes.service.js';
import {
  reporteVentasSchema,
  reporteTopProductosSchema,
  corteCajaSchema,
  reporteInventarioSchema
} from './reportes.schemas.js';
import { badRequest } from '../../utils/http-error.js';
import { getDateOnlyMx } from '../../config/time.js';

const sendPDF = (res: Response, doc: any, filename: string) => {
  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  doc.pipe(res);
  doc.end();
};

const sendCSV = (res: Response, csv: string, filename: string) => {
  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  res.send('\ufeff' + csv); // BOM para Excel
};

export const reporteVentasPDFHandler = async (req: Request, res: Response): Promise<void> => {
  try {
    const parsed = reporteVentasSchema.safeParse(req.query);
    if (!parsed.success) {
      throw badRequest('Parámetros inválidos', parsed.error.flatten().fieldErrors);
    }

    const doc = await generarReporteVentasPDF(parsed.data.fechaInicio, parsed.data.fechaFin);
    const fechaInicioStr = getDateOnlyMx(parsed.data.fechaInicio) ?? parsed.data.fechaInicio.toISOString().split('T')[0];
    const fechaFinStr = getDateOnlyMx(parsed.data.fechaFin) ?? parsed.data.fechaFin.toISOString().split('T')[0];
    const filename = `reporte-ventas-${fechaInicioStr}-${fechaFinStr}.pdf`;
    sendPDF(res, doc, filename);
  } catch (error: any) {
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Error al generar reporte PDF'
    });
  }
};

export const reporteVentasCSVHandler = async (req: Request, res: Response): Promise<void> => {
  try {
    const parsed = reporteVentasSchema.safeParse(req.query);
    if (!parsed.success) {
      throw badRequest('Parámetros inválidos', parsed.error.flatten().fieldErrors);
    }

    const csv = await generarReporteVentasCSV(parsed.data.fechaInicio, parsed.data.fechaFin);
    const fechaInicioStr = getDateOnlyMx(parsed.data.fechaInicio) ?? parsed.data.fechaInicio.toISOString().split('T')[0];
    const fechaFinStr = getDateOnlyMx(parsed.data.fechaFin) ?? parsed.data.fechaFin.toISOString().split('T')[0];
    const filename = `reporte-ventas-${fechaInicioStr}-${fechaFinStr}.csv`;
    sendCSV(res, csv, filename);
  } catch (error: any) {
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Error al generar reporte CSV'
    });
  }
};

export const reporteTopProductosPDFHandler = async (req: Request, res: Response): Promise<void> => {
  try {
    const parsed = reporteTopProductosSchema.safeParse(req.query);
    if (!parsed.success) {
      throw badRequest('Parámetros inválidos', parsed.error.flatten().fieldErrors);
    }

    const doc = await generarReporteTopProductosPDF(
      parsed.data.fechaInicio,
      parsed.data.fechaFin,
      parsed.data.limite
    );
    const fechaInicioStr = getDateOnlyMx(parsed.data.fechaInicio) ?? parsed.data.fechaInicio.toISOString().split('T')[0];
    const fechaFinStr = getDateOnlyMx(parsed.data.fechaFin) ?? parsed.data.fechaFin.toISOString().split('T')[0];
    const filename = `top-productos-${fechaInicioStr}-${fechaFinStr}.pdf`;
    sendPDF(res, doc, filename);
  } catch (error: any) {
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Error al generar reporte PDF'
    });
  }
};

export const reporteTopProductosCSVHandler = async (req: Request, res: Response): Promise<void> => {
  try {
    const parsed = reporteTopProductosSchema.safeParse(req.query);
    if (!parsed.success) {
      throw badRequest('Parámetros inválidos', parsed.error.flatten().fieldErrors);
    }

    const csv = await generarReporteTopProductosCSV(
      parsed.data.fechaInicio,
      parsed.data.fechaFin,
      parsed.data.limite
    );
    const fechaInicioStr = getDateOnlyMx(parsed.data.fechaInicio) ?? parsed.data.fechaInicio.toISOString().split('T')[0];
    const fechaFinStr = getDateOnlyMx(parsed.data.fechaFin) ?? parsed.data.fechaFin.toISOString().split('T')[0];
    const filename = `top-productos-${fechaInicioStr}-${fechaFinStr}.csv`;
    sendCSV(res, csv, filename);
  } catch (error: any) {
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Error al generar reporte CSV'
    });
  }
};

export const corteCajaPDFHandler = async (req: Request, res: Response): Promise<void> => {
  try {
    const parsed = corteCajaSchema.safeParse(req.query);
    if (!parsed.success) {
      throw badRequest('Parámetros inválidos', parsed.error.flatten().fieldErrors);
    }

    const doc = await generarCorteCajaPDF(parsed.data.fecha, parsed.data.cajeroId);
    const fechaStr = getDateOnlyMx(parsed.data.fecha) ?? parsed.data.fecha.toISOString().split('T')[0];
    const filename = `corte-caja-${fechaStr}.pdf`;
    sendPDF(res, doc, filename);
  } catch (error: any) {
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Error al generar corte de caja PDF'
    });
  }
};

export const corteCajaCSVHandler = async (req: Request, res: Response): Promise<void> => {
  try {
    const parsed = corteCajaSchema.safeParse(req.query);
    if (!parsed.success) {
      throw badRequest('Parámetros inválidos', parsed.error.flatten().fieldErrors);
    }

    const csv = await generarCorteCajaCSV(parsed.data.fecha, parsed.data.cajeroId);
    const fechaStr = getDateOnlyMx(parsed.data.fecha) ?? parsed.data.fecha.toISOString().split('T')[0];
    const filename = `corte-caja-${fechaStr}.csv`;
    sendCSV(res, csv, filename);
  } catch (error: any) {
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Error al generar corte de caja CSV'
    });
  }
};

export const reporteInventarioPDFHandler = async (req: Request, res: Response): Promise<void> => {
  try {
    const parsed = reporteInventarioSchema.safeParse(req.query);
    if (!parsed.success) {
      throw badRequest('Parámetros inválidos', parsed.error.flatten().fieldErrors);
    }

    const doc = await generarReporteInventarioPDF(parsed.data.fechaInicio, parsed.data.fechaFin);
    const fechaInicioStr = getDateOnlyMx(parsed.data.fechaInicio) ?? parsed.data.fechaInicio.toISOString().split('T')[0];
    const fechaFinStr = getDateOnlyMx(parsed.data.fechaFin) ?? parsed.data.fechaFin.toISOString().split('T')[0];
    const filename = `reporte-inventario-${fechaInicioStr}-${fechaFinStr}.pdf`;
    sendPDF(res, doc, filename);
  } catch (error: any) {
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Error al generar reporte PDF'
    });
  }
};

export const reporteInventarioCSVHandler = async (req: Request, res: Response): Promise<void> => {
  try {
    const parsed = reporteInventarioSchema.safeParse(req.query);
    if (!parsed.success) {
      throw badRequest('Parámetros inválidos', parsed.error.flatten().fieldErrors);
    }

    const csv = await generarReporteInventarioCSV(parsed.data.fechaInicio, parsed.data.fechaFin);
    const fechaInicioStr = getDateOnlyMx(parsed.data.fechaInicio) ?? parsed.data.fechaInicio.toISOString().split('T')[0];
    const fechaFinStr = getDateOnlyMx(parsed.data.fechaFin) ?? parsed.data.fechaFin.toISOString().split('T')[0];
    const filename = `reporte-inventario-${fechaInicioStr}-${fechaFinStr}.csv`;
    sendCSV(res, csv, filename);
  } catch (error: any) {
    res.status(error.statusCode || 500).json({
      success: false,
      error: error.message || 'Error al generar reporte CSV'
    });
  }
};

