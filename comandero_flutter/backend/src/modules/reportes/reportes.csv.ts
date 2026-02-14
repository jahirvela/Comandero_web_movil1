import { Parser } from 'json2csv';
import type {
  VentasReporte,
  TopProducto,
  CorteCaja,
  InventarioMovimiento
} from './reportes.repository.js';
import { formatMxLocale, formatMxDate } from '../../config/time.js';

/**
 * Librería elegida: json2csv (v6.0.0-alpha.2)
 * 
 * Razones:
 * 1. Conversión simple de JSON a CSV
 * 2. Soporte para encabezados personalizados
 * 3. Manejo correcto de encoding UTF-8
 * 4. Fácil de usar
 */

export const generarCSVVentas = (datos: VentasReporte[]): string => {
  const fields = [
    { label: 'Folio', value: 'folio' },
    { label: 'Fecha', value: (row: VentasReporte) => formatMxLocale(row.fecha) },
    { label: 'Mesa', value: 'mesaCodigo' },
    { label: 'Cliente', value: 'clienteNombre' },
    { label: 'Subtotal', value: (row: VentasReporte) => row.subtotal.toFixed(2) },
    { label: 'Descuento', value: (row: VentasReporte) => row.descuentoTotal.toFixed(2) },
    { label: 'Impuesto', value: (row: VentasReporte) => row.impuestoTotal.toFixed(2) },
    { label: 'Propina', value: (row: VentasReporte) => row.propinaTotal.toFixed(2) },
    { label: 'Total', value: (row: VentasReporte) => row.total.toFixed(2) },
    { label: 'Forma de Pago', value: 'formaPago' },
    { label: 'Cajero', value: 'cajero' }
  ];

  const parser = new Parser({ fields, withBOM: true });
  return parser.parse(datos);
};

export const generarCSVTopProductos = (datos: TopProducto[]): string => {
  const fields = [
    { label: 'Posición', value: (_: TopProducto, index: number) => index + 1 },
    { label: 'Producto', value: 'productoNombre' },
    { label: 'Categoría', value: 'categoriaNombre' },
    { label: 'Cantidad Vendida', value: 'cantidadVendida' },
    { label: 'Ingresos', value: (row: TopProducto) => row.ingresos.toFixed(2) }
  ];

  const parser = new Parser({ fields, withBOM: true });
  return parser.parse(datos);
};

export const generarCSVCorteCaja = (datos: CorteCaja): string => {
  const fields = [
    { label: 'Fecha', value: (row: CorteCaja) => formatMxDate(row.fecha) },
    { label: 'Cajero', value: 'cajero' },
    { label: 'Número de Órdenes', value: 'numeroOrdenes' },
    { label: 'Total Ventas', value: (row: CorteCaja) => row.totalVentas.toFixed(2) },
    { label: 'Total IVA', value: (row: CorteCaja) => row.totalImpuesto.toFixed(2) },
    { label: 'Efectivo', value: (row: CorteCaja) => row.totalEfectivo.toFixed(2) },
    { label: 'Tarjeta', value: (row: CorteCaja) => row.totalTarjeta.toFixed(2) },
    { label: 'Otros', value: (row: CorteCaja) => row.totalOtros.toFixed(2) },
    { label: 'Total Propinas', value: (row: CorteCaja) => row.totalPropinas.toFixed(2) }
  ];

  const parser = new Parser({ fields, withBOM: true });
  return parser.parse([datos]);
};

export const generarCSVInventario = (datos: InventarioMovimiento[]): string => {
  const fields = [
    { label: 'Fecha', value: (row: InventarioMovimiento) => formatMxLocale(row.fecha) },
    { label: 'Item', value: 'itemNombre' },
    { label: 'Unidad', value: 'unidad' },
    { label: 'Tipo', value: 'tipo' },
    { label: 'Cantidad', value: 'cantidad' },
    {
      label: 'Costo Unitario',
      value: (row: InventarioMovimiento) => (row.costoUnitario !== null ? row.costoUnitario.toFixed(2) : 'N/A')
    },
    { label: 'Motivo', value: 'motivo' },
    { label: 'Usuario', value: 'usuario' }
  ];

  const parser = new Parser({ fields, withBOM: true });
  return parser.parse(datos);
};

