import { getEnv } from '../../config/env.js';
import { logger } from '../../config/logger.js';
import { createPrinter } from '../tickets/tickets.printer.js';
import { formatMxLocale, nowMx } from '../../config/time.js';
import type { OrdenDetalle } from '../ordenes/ordenes.service.js';

/**
 * Genera el contenido de la comanda en formato texto plano compatible con POS-80
 * La comanda es diferente al ticket: muestra información relevante para cocina
 */
export const generarContenidoComanda = (orden: OrdenDetalle): string => {
  let contenido = '';

  // Comandos ESC/POS para formato
  const ESC = '\x1B';
  const centrar = `${ESC}a1`; // Centrar texto
  const izquierda = `${ESC}a0`; // Alinear izquierda
  const negrita = `${ESC}E1`; // Negrita ON
  const negritaOff = `${ESC}E0`; // Negrita OFF
  const dobleAltura = `${ESC}d1`; // Doble altura
  const alturaNormal = `${ESC}d0`; // Altura normal
  const cortar = `${ESC}i`; // Cortar papel

  // Encabezado - COMANDA
  contenido += centrar;
  contenido += negrita;
  contenido += dobleAltura;
  contenido += '*** COMANDA ***\n';
  contenido += alturaNormal;
  contenido += negritaOff;
  contenido += `${'='.repeat(42)}\n`;
  contenido += izquierda;

  // Información de la orden
  const folio = `ORD-${String(orden.id).padStart(6, '0')}`;
  contenido += `Folio: ${folio}\n`;
  contenido += `Fecha: ${formatMxLocale(orden.creadoEn, { dateStyle: 'short', timeStyle: 'short' })}\n`;

  // Mesa o Para llevar
  if (orden.mesaCodigo) {
    contenido += `Mesa: ${orden.mesaCodigo}\n`;
  } else if (orden.clienteNombre) {
    contenido += centrar;
    contenido += negrita;
    contenido += '*** PARA LLEVAR ***\n';
    contenido += negritaOff;
    contenido += izquierda;
    contenido += `Cliente: ${orden.clienteNombre}\n`;
    if (orden.clienteTelefono) {
      contenido += `Tel: ${orden.clienteTelefono}\n`;
    }
  }

  // Mesero
  if (orden.creadoPorNombre) {
    contenido += `Mesero: ${orden.creadoPorNombre}\n`;
  }

  // Tiempo estimado
  if (orden.tiempoEstimadoPreparacion) {
    contenido += `Tiempo estimado: ${orden.tiempoEstimadoPreparacion} min\n`;
  }

  contenido += `${'-'.repeat(42)}\n`;

  // Items de la orden - Formato para cocina
  contenido += negrita;
  contenido += 'CANT  PRODUCTO\n';
  contenido += negritaOff;
  contenido += `${'-'.repeat(42)}\n`;

  // Agrupar items por estación/categoría si es posible
  for (const item of orden.items) {
    const cantidad = String(item.cantidad).padStart(3);
    const nombreProducto = item.productoNombre || 'Producto';
    const tamano = item.productoTamanoEtiqueta;
    const descripcion = tamano ? `${nombreProducto} (${tamano})` : nombreProducto;

    // Truncar si es muy largo
    const descripcionCorta = descripcion.length > 35 ? descripcion.substring(0, 32) + '...' : descripcion;

    contenido += `${cantidad}x  ${descripcionCorta}\n`;

    // Mostrar modificadores (extras, salsas, etc.)
    if (item.modificadores && item.modificadores.length > 0) {
      for (const mod of item.modificadores) {
        contenido += `     + ${mod.modificadorOpcionNombre}\n`;
      }
    }

    // Mostrar nota del item si existe
    if (item.nota) {
      contenido += `     NOTA: ${item.nota}\n`;
    }
  }

  contenido += `${'-'.repeat(42)}\n`;

  // Notas generales de la orden si existen
  if (orden.notas && orden.notas.length > 0) {
    contenido += negrita;
    contenido += 'NOTAS GENERALES:\n';
    contenido += negritaOff;
    for (const nota of orden.notas) {
      contenido += `- ${nota.contenido}\n`;
    }
    contenido += `${'-'.repeat(42)}\n`;
  }

  // Pie de página
  contenido += centrar;
  contenido += `\n${folio}\n`;
  contenido += `${formatMxLocale(orden.creadoEn, { dateStyle: 'short', timeStyle: 'short' })}\n`;
  contenido += izquierda;

  // Cortar papel
  contenido += cortar;
  contenido += '\n'; // Avanzar papel

  return contenido;
};

/**
 * Imprime una comanda usando la impresora configurada
 */
export const imprimirComanda = async (
  orden: OrdenDetalle,
  esReimpresion: boolean = false
): Promise<{ exito: boolean; mensaje: string; rutaArchivo?: string }> => {
  try {
    const contenido = generarContenidoComanda(orden);
    const printer = createPrinter();

    await printer.print(contenido);
    await printer.close();

    const tipoImpresion = esReimpresion ? 'reimpresión manual' : 'impresión automática';
    logger.info(
      { ordenId: orden.id, tipoImpresion },
      `✅ Comanda impresa exitosamente (${tipoImpresion})`
    );

    return {
      exito: true,
      mensaje: `Comanda impresa exitosamente (${tipoImpresion})`,
      rutaArchivo: getEnv().PRINTER_TYPE === 'simulation' 
        ? `./${getEnv().PRINTER_SIMULATION_PATH}/comanda-${orden.id}-${nowMx().toFormat('yyyy-MM-dd-HH-mm-ss')}.txt`
        : undefined
    };
  } catch (error: any) {
    logger.error({ err: error, ordenId: orden.id }, '❌ Error al imprimir comanda');
    
    // En caso de error, intentar modo simulación
    try {
      const contenido = generarContenidoComanda(orden);
      const simulationPrinter = createPrinter();
      await simulationPrinter.print(contenido);
      await simulationPrinter.close();

      logger.warn({ ordenId: orden.id }, '⚠️ Comanda guardada en modo simulación debido a error de impresora');
      
      return {
        exito: true,
        mensaje: 'Comanda guardada en modo simulación (impresora no disponible)',
        rutaArchivo: `./${getEnv().PRINTER_SIMULATION_PATH}/comanda-${orden.id}-${nowMx().toFormat('yyyy-MM-dd-HH-mm-ss')}.txt`
      };
    } catch (simError) {
      logger.error({ err: simError, ordenId: orden.id }, '❌ Error incluso en modo simulación');
      return {
        exito: false,
        mensaje: `Error al imprimir comanda: ${error.message || 'Error desconocido'}`
      };
    }
  }
};

