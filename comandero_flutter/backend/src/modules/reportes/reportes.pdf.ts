import PDFDocument from 'pdfkit';
import type {
  VentasReporte,
  TopProducto,
  CorteCaja,
  InventarioMovimiento
} from './reportes.repository.js';
import { formatMxLocale, nowMx, formatMxDate } from '../../config/time.js';

/**
 * Librería elegida: pdfkit (v0.17.2)
 * 
 * Razones:
 * 1. Generación de PDFs desde cero con control total
 * 2. Soporte para tablas, imágenes, gráficos
 * 3. Buen rendimiento
 * 4. Activamente mantenida
 * 5. Compatible con Node.js moderno
 */

export const generarPDFVentas = (datos: VentasReporte[]): PDFDocument => {
  const doc = new PDFDocument({ margin: 50 });

  // Encabezado
  doc.fontSize(20).text('Reporte de Ventas', { align: 'center' });
  doc.moveDown();

  if (datos.length === 0) {
    doc.fontSize(12).text('No hay ventas en el período seleccionado.', { align: 'center' });
    return doc;
  }

  // Información del período - usar formato CDMX
  const fechaInicio = datos[datos.length - 1]?.fecha;
  const fechaFin = datos[0]?.fecha;
  if (fechaInicio && fechaFin) {
    doc.fontSize(10).text(`Período: ${formatMxDate(fechaInicio)} - ${formatMxDate(fechaFin)}`, {
      align: 'center'
    });
  }
  doc.moveDown();

  // Totales
  const totalVentas = datos.reduce((sum, v) => sum + v.total, 0);
  const totalPropinas = datos.reduce((sum, v) => sum + v.propinaTotal, 0);

  doc.fontSize(12).font('Helvetica-Bold').text('Resumen:', 50);
  doc.font('Helvetica').fontSize(10);
  doc.text(`Total de órdenes: ${datos.length}`, 70);
  doc.text(`Total de ventas: $${totalVentas.toFixed(2)}`, 70);
  doc.text(`Total de propinas: $${totalPropinas.toFixed(2)}`, 70);
  doc.moveDown();

  // Tabla de ventas
  doc.fontSize(10).font('Helvetica-Bold');
  let y = doc.y;
  doc.text('Folio', 50, y);
  doc.text('Fecha', 120, y);
  doc.text('Mesa', 180, y);
  doc.text('Total', 230, y);
  doc.text('Forma Pago', 280, y);

  doc.moveTo(50, y + 15).lineTo(550, y + 15).stroke();
  doc.moveDown(0.5);

  doc.font('Helvetica').fontSize(9);
  for (const venta of datos) {
    if (doc.y > 750) {
      doc.addPage();
      y = doc.y;
    }

    doc.text(venta.folio, 50);
    doc.text(formatMxDate(venta.fecha), 120);
    doc.text(venta.mesaCodigo || 'N/A', 180);
    doc.text(`$${venta.total.toFixed(2)}`, 230);
    doc.text(venta.formaPago, 280);
    doc.moveDown(0.3);
  }

  // Pie de página - usar zona horaria CDMX
  doc.fontSize(8).text(`Generado el: ${formatMxLocale(nowMx().toJSDate())}`, 50, doc.page.height - 50, {
    align: 'center'
  });

  return doc;
};

export const generarPDFTopProductos = (datos: TopProducto[]): PDFDocument => {
  const doc = new PDFDocument({ margin: 50 });

  doc.fontSize(20).text('Top Productos Vendidos', { align: 'center' });
  doc.moveDown();

  if (datos.length === 0) {
    doc.fontSize(12).text('No hay productos vendidos en el período seleccionado.', { align: 'center' });
    return doc;
  }

  // Tabla
  doc.fontSize(10).font('Helvetica-Bold');
  let y = doc.y;
  doc.text('#', 50, y);
  doc.text('Producto', 80, y);
  doc.text('Categoría', 250, y);
  doc.text('Cantidad', 350, y);
  doc.text('Ingresos', 420, y);

  doc.moveTo(50, y + 15).lineTo(550, y + 15).stroke();
  doc.moveDown(0.5);

  doc.font('Helvetica').fontSize(9);
  datos.forEach((producto, index) => {
    if (doc.y > 750) {
      doc.addPage();
      y = doc.y;
    }

    doc.text(String(index + 1), 50);
    doc.text(producto.productoNombre, 80, undefined, { width: 160 });
    doc.text(producto.categoriaNombre, 250, undefined, { width: 90 });
    doc.text(String(producto.cantidadVendida), 350);
    doc.text(`$${producto.ingresos.toFixed(2)}`, 420);
    doc.moveDown(0.3);
  });

  // Totales
  const totalIngresos = datos.reduce((sum, p) => sum + p.ingresos, 0);
  doc.moveDown();
  doc.font('Helvetica-Bold').text(`Total de ingresos: $${totalIngresos.toFixed(2)}`, 350);

  doc.fontSize(8).text(`Generado el: ${formatMxLocale(nowMx().toJSDate())}`, 50, doc.page.height - 50, {
    align: 'center'
  });

  return doc;
};

export const generarPDFCorteCaja = (datos: CorteCaja): PDFDocument => {
  const doc = new PDFDocument({ margin: 50 });

  doc.fontSize(20).text('Corte de Caja', { align: 'center' });
  doc.moveDown();

  doc.fontSize(12);
  doc.font('Helvetica-Bold').text('Fecha:', 50);
  doc.font('Helvetica').text(formatMxDate(datos.fecha), 120);
  doc.moveDown();

  if (datos.cajero) {
    doc.font('Helvetica-Bold').text('Cajero:', 50);
    doc.font('Helvetica').text(datos.cajero, 120);
    doc.moveDown();
  }

  doc.moveDown();
  doc.fontSize(14).font('Helvetica-Bold').text('Resumen:', 50);
  doc.moveDown(0.5);

  doc.fontSize(12);
  doc.font('Helvetica').text(`Número de órdenes: ${datos.numeroOrdenes}`, 70);
  doc.text(`Total de ventas: $${datos.totalVentas.toFixed(2)}`, 70);
  doc.moveDown();
  doc.text(`Efectivo: $${datos.totalEfectivo.toFixed(2)}`, 70);
  doc.text(`Tarjeta: $${datos.totalTarjeta.toFixed(2)}`, 70);
  doc.text(`Otros: $${datos.totalOtros.toFixed(2)}`, 70);
  doc.moveDown();
  doc.font('Helvetica-Bold').text(`Total propinas: $${datos.totalPropinas.toFixed(2)}`, 70);

  doc.fontSize(8).text(`Generado el: ${formatMxLocale(nowMx().toJSDate())}`, 50, doc.page.height - 50, {
    align: 'center'
  });

  return doc;
};

export const generarPDFInventario = (datos: InventarioMovimiento[]): PDFDocument => {
  const doc = new PDFDocument({ margin: 50 });

  doc.fontSize(20).text('Reporte de Inventario', { align: 'center' });
  doc.moveDown();

  if (datos.length === 0) {
    doc.fontSize(12).text('No hay movimientos en el período seleccionado.', { align: 'center' });
    return doc;
  }

  // Tabla
  doc.fontSize(10).font('Helvetica-Bold');
  let y = doc.y;
  doc.text('Fecha', 50, y);
  doc.text('Item', 120, y);
  doc.text('Tipo', 250, y);
  doc.text('Cantidad', 300, y);
  doc.text('Costo', 360, y);
  doc.text('Usuario', 420, y);

  doc.moveTo(50, y + 15).lineTo(550, y + 15).stroke();
  doc.moveDown(0.5);

  doc.font('Helvetica').fontSize(9);
  for (const movimiento of datos) {
    if (doc.y > 750) {
      doc.addPage();
      y = doc.y;
    }

    doc.text(formatMxDate(movimiento.fecha), 50);
    doc.text(movimiento.itemNombre, 120, undefined, { width: 120 });
    doc.text(movimiento.tipo, 250);
    doc.text(`${movimiento.cantidad} ${movimiento.unidad}`, 300);
    doc.text(
      movimiento.costoUnitario !== null ? `$${movimiento.costoUnitario.toFixed(2)}` : 'N/A',
      360
    );
    doc.text(movimiento.usuario || 'N/A', 420);
    doc.moveDown(0.3);
  }

  doc.fontSize(8).text(`Generado el: ${formatMxLocale(nowMx().toJSDate())}`, 50, doc.page.height - 50, {
    align: 'center'
  });

  return doc;
};

