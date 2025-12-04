import {
  obtenerReporteVentas,
  obtenerTopProductos,
  obtenerCorteCaja,
  obtenerReporteInventario
} from './reportes.repository.js';
import {
  generarPDFVentas,
  generarPDFTopProductos,
  generarPDFCorteCaja,
  generarPDFInventario
} from './reportes.pdf.js';
import {
  generarCSVVentas,
  generarCSVTopProductos,
  generarCSVCorteCaja,
  generarCSVInventario
} from './reportes.csv.js';

export const generarReporteVentasPDF = async (fechaInicio: Date, fechaFin: Date) => {
  const datos = await obtenerReporteVentas(fechaInicio, fechaFin);
  return generarPDFVentas(datos);
};

export const generarReporteVentasCSV = async (fechaInicio: Date, fechaFin: Date) => {
  const datos = await obtenerReporteVentas(fechaInicio, fechaFin);
  return generarCSVVentas(datos);
};

export const generarReporteTopProductosPDF = async (
  fechaInicio: Date,
  fechaFin: Date,
  limite: number = 10
) => {
  const datos = await obtenerTopProductos(fechaInicio, fechaFin, limite);
  return generarPDFTopProductos(datos);
};

export const generarReporteTopProductosCSV = async (
  fechaInicio: Date,
  fechaFin: Date,
  limite: number = 10
) => {
  const datos = await obtenerTopProductos(fechaInicio, fechaFin, limite);
  return generarCSVTopProductos(datos);
};

export const generarCorteCajaPDF = async (fecha: Date, cajeroId?: number) => {
  const datos = await obtenerCorteCaja(fecha, cajeroId);
  return generarPDFCorteCaja(datos);
};

export const generarCorteCajaCSV = async (fecha: Date, cajeroId?: number) => {
  const datos = await obtenerCorteCaja(fecha, cajeroId);
  return generarCSVCorteCaja(datos);
};

export const generarReporteInventarioPDF = async (fechaInicio: Date, fechaFin: Date) => {
  const datos = await obtenerReporteInventario(fechaInicio, fechaFin);
  return generarPDFInventario(datos);
};

export const generarReporteInventarioCSV = async (fechaInicio: Date, fechaFin: Date) => {
  const datos = await obtenerReporteInventario(fechaInicio, fechaFin);
  return generarCSVInventario(datos);
};

