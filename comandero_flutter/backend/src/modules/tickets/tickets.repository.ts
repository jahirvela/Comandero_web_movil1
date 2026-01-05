import type { RowDataPacket } from 'mysql2';
import { pool } from '../../db/pool.js';
import { obtenerOrdenBasePorId, obtenerItemsOrden, obtenerModificadoresItem } from '../ordenes/ordenes.repository.js';
import { utcToMxISO, utcToMx } from '../../config/time.js';

interface UsuarioRow extends RowDataPacket {
  id: number;
  nombre: string;
  username: string;
}

interface RestauranteConfigRow extends RowDataPacket {
  nombre: string;
  direccion: string | null;
  rfc: string | null;
  telefono: string | null;
}

export interface TicketData {
  orden: {
    id: number;
    folio: string;
    fecha: Date;
    mesaCodigo: string | null;
    clienteNombre: string | null;
    clienteTelefono: string | null;
    subtotal: number;
    descuentoTotal: number;
    impuestoTotal: number;
    propinaSugerida: number | null;
    total: number;
  };
  cajero: {
    id: number;
    nombre: string;
    username: string;
  } | null;
  items: Array<{
    cantidad: number;
    productoNombre: string;
    productoTamanoEtiqueta: string | null;
    precioUnitario: number;
    totalLinea: number;
    nota: string | null;
    modificadores: Array<{
      nombre: string;
      precioUnitario: number;
    }>;
  }>;
  restaurante: {
    nombre: string;
    direccion: string | null;
    rfc: string | null;
    telefono: string | null;
  };
}

export const obtenerDatosTicket = async (ordenId: number, cajeroId?: number, ordenIds?: number[]): Promise<TicketData> => {
  // Si hay múltiples ordenIds (cuenta agrupada), obtener datos de todas las órdenes
  const ordenIdsToProcess = (ordenIds && ordenIds.length > 1) ? ordenIds : [ordenId];
  
  // Obtener orden base principal
  const ordenBase = await obtenerOrdenBasePorId(ordenId);
  if (!ordenBase) {
    throw new Error(`Orden ${ordenId} no encontrada`);
  }

  // Obtener items de todas las órdenes si es cuenta agrupada
  let todosLosItems: Awaited<ReturnType<typeof obtenerItemsOrden>> = [];
  for (const ordenIdItem of ordenIdsToProcess) {
    const items = await obtenerItemsOrden(ordenIdItem);
    todosLosItems = todosLosItems.concat(items);
  }

  // Obtener todos los modificadores de todos los items
  const itemIds = todosLosItems.map((item) => item.id);
  const modificadores = await obtenerModificadoresItem(itemIds);

  // Crear mapa de modificadores por item
  const modificadoresPorItem = new Map<number, typeof modificadores>();
  for (const mod of modificadores) {
    if (!modificadoresPorItem.has(mod.ordenItemId)) {
      modificadoresPorItem.set(mod.ordenItemId, []);
    }
    modificadoresPorItem.get(mod.ordenItemId)!.push(mod);
  }

  // Calcular totales combinados si hay múltiples órdenes
  let subtotalTotal = ordenBase.subtotal;
  let descuentoTotal = ordenBase.descuentoTotal;
  let impuestoTotal = ordenBase.impuestoTotal;
  let propinaTotal = ordenBase.propinaSugerida || 0;
  let totalTotal = ordenBase.total;
  let fechaMasAntigua = typeof ordenBase.creadoEn === 'string' ? new Date(ordenBase.creadoEn) : ordenBase.creadoEn;

  if (ordenIdsToProcess.length > 1) {
    // Obtener datos de todas las órdenes para calcular totales
    for (const ordenIdItem of ordenIdsToProcess) {
      if (ordenIdItem !== ordenId) {
        const ordenBaseItem = await obtenerOrdenBasePorId(ordenIdItem);
        if (ordenBaseItem) {
          subtotalTotal += ordenBaseItem.subtotal;
          descuentoTotal += ordenBaseItem.descuentoTotal;
          impuestoTotal += ordenBaseItem.impuestoTotal;
          propinaTotal += (ordenBaseItem.propinaSugerida || 0);
          totalTotal += ordenBaseItem.total;
          
          // Usar la fecha más antigua
          const fechaItem = typeof ordenBaseItem.creadoEn === 'string' ? new Date(ordenBaseItem.creadoEn) : ordenBaseItem.creadoEn;
          if (fechaItem < fechaMasAntigua) {
            fechaMasAntigua = fechaItem;
          }
        }
      }
    }
  }

  // Obtener datos del cajero si se proporciona
  let cajero: TicketData['cajero'] = null;
  if (cajeroId) {
    const [usuarioRows] = await pool.query<UsuarioRow[]>(
      'SELECT id, nombre, username FROM usuario WHERE id = ?',
      [cajeroId]
    );
    if (usuarioRows.length > 0) {
      cajero = {
        id: usuarioRows[0].id,
        nombre: usuarioRows[0].nombre,
        username: usuarioRows[0].username
      };
    }
  }

  // Obtener configuración del restaurante (por ahora valores por defecto)
  // En el futuro esto podría venir de una tabla de configuración
  const restaurante: TicketData['restaurante'] = {
    nombre: process.env.RESTAURANTE_NOMBRE || 'Comandix Restaurant',
    direccion: process.env.RESTAURANTE_DIRECCION || null,
    rfc: process.env.RESTAURANTE_RFC || null,
    telefono: process.env.RESTAURANTE_TELEFONO || null
  };

  // Formatear items con modificadores
  const itemsFormateados = todosLosItems.map((item) => ({
    cantidad: item.cantidad,
    productoNombre: item.productoNombre,
    productoTamanoEtiqueta: item.productoTamanoEtiqueta,
    precioUnitario: item.precioUnitario,
    totalLinea: item.totalLinea,
    nota: item.nota,
    modificadores:
      modificadoresPorItem.get(item.id)?.map((mod) => ({
        nombre: mod.modificadorOpcionNombre,
        precioUnitario: mod.precioUnitario
      })) || []
  }));

  // Determinar si es pedido para llevar (no tiene mesa pero tiene clienteNombre)
  const isTakeaway = !ordenBase.mesaCodigo && ordenBase.clienteNombre;

  // Crear folio que indique si es cuenta agrupada
  let folio: string;
  if (ordenIdsToProcess.length > 1) {
    const folios = ordenIdsToProcess.map(id => `ORD-${String(id).padStart(6, '0')}`).join(', ');
    folio = `Cuenta agrupada (${ordenIdsToProcess.length} órdenes): ${folios}`;
  } else {
    folio = `ORD-${String(ordenBase.id).padStart(6, '0')}`;
  }

  return {
    orden: {
      id: ordenBase.id,
      folio: folio,
      // Usar la fecha más antigua si es cuenta agrupada
      fecha: fechaMasAntigua,
      mesaCodigo: ordenBase.mesaCodigo,
      clienteNombre: ordenBase.clienteNombre,
      clienteTelefono: ordenBase.clienteTelefono || null,
      subtotal: subtotalTotal,
      descuentoTotal: descuentoTotal,
      impuestoTotal: impuestoTotal,
      propinaSugerida: propinaTotal || null,
      total: totalTotal
    },
    cajero,
    items: itemsFormateados,
    restaurante
  };
};

interface TicketListRow extends RowDataPacket {
  orden_id: number;
  orden_folio: string;
  orden_fecha: Date;
  mesa_codigo: string | null;
  mesa_nombre: string | null;
  cliente_nombre: string | null;
  cliente_telefono: string | null;
  orden_subtotal: number;
  orden_descuento: number;
  orden_impuesto: number;
  orden_propina: number | null;
  orden_total: number;
  estado_orden: string;
  cajero_id: number | null;
  cajero_nombre: string | null;
  cajero_username: string | null;
  mesero_id: number | null;
  mesero_nombre: string | null;
  mesero_username: string | null;
  forma_pago_nombre: string | null;
  pago_referencia: string | null;
  impreso: number; // 0 o 1
  impreso_por_id: number | null;
  impreso_por_nombre: string | null;
  impreso_en: Date | null;
  ultima_impresion_exitosa: number; // 0 o 1
}

export interface TicketListItem {
  id: string; // Folio de la orden o ID de cuenta agrupada
  ordenId: number; // Orden principal (para compatibilidad)
  ordenIds?: number[]; // Para cuentas agrupadas: todas las órdenes
  mesaCodigo?: string | null;
  mesaNombre?: string | null;
  customerPhone?: string | null;
  tableNumber: number | null;
  customerName: string | null;
  subtotal: number;
  discount: number;
  tax: number;
  tip?: number | null;
  total: number;
  status: string; // 'pending', 'printed', 'delivered'
  createdAt: string; // ISO string en zona CDMX
  waiterName: string | null;
  cashierName: string | null;
  paymentMethod: string | null; // Método de pago (ej: 'Efectivo', 'Tarjeta', etc.)
  paymentReference: string | null; // Referencia del pago (incluye info de débito/crédito)
  isPrinted: boolean;
  printedBy: string | null;
  printedAt: string | null; // ISO string en zona CDMX
  isGrouped?: boolean; // Flag para indicar que es una cuenta agrupada
}

export const listarTickets = async (): Promise<TicketListItem[]> => {
  try {
    const { logger } = await import('../../config/logger.js');
    
    // Verificar si la tabla bitacora_impresion existe
    const [tableCheck] = await pool.query<RowDataPacket[]>(
      `SELECT COUNT(*) as count 
       FROM information_schema.tables 
       WHERE table_schema = DATABASE() 
       AND table_name = 'bitacora_impresion'`
    );

    const hasBitacoraTable = (tableCheck[0]?.count as number) > 0;
    
    logger.debug('TicketsRepository: Listando tickets - hasBitacoraTable: ' + hasBitacoraTable);

    // Query para obtener tickets de órdenes pagadas
    const query = `
      SELECT 
        o.id AS orden_id,
        CONCAT('ORD-', LPAD(o.id, 6, '0')) AS orden_folio,
        o.creado_en AS orden_fecha,
        m.codigo AS mesa_codigo,
        m.nombre AS mesa_nombre,
        o.cliente_nombre,
        c.telefono AS cliente_telefono,
        o.subtotal AS orden_subtotal,
        o.descuento_total AS orden_descuento,
        o.impuesto_total AS orden_impuesto,
        o.propina_sugerida AS orden_propina,
        -- Propina real del pago (de la tabla propina)
        (SELECT COALESCE(SUM(pr.monto), 0)
         FROM propina pr
         WHERE pr.orden_id = o.id) AS propina_pago,
        o.total AS orden_total,
        eo.nombre AS estado_orden,
        -- Cajero (del último pago)
        (SELECT p.empleado_id 
         FROM pago p 
         WHERE p.orden_id = o.id 
         ORDER BY p.fecha_pago DESC 
         LIMIT 1) AS cajero_id,
        (SELECT u.nombre 
         FROM pago p 
         JOIN usuario u ON u.id = p.empleado_id 
         WHERE p.orden_id = o.id 
         ORDER BY p.fecha_pago DESC 
         LIMIT 1) AS cajero_nombre,
        (SELECT u.username 
         FROM pago p 
         JOIN usuario u ON u.id = p.empleado_id 
         WHERE p.orden_id = o.id 
         ORDER BY p.fecha_pago DESC 
         LIMIT 1) AS cajero_username,
        -- Método de pago (del último pago)
        (SELECT fp.nombre 
         FROM pago p 
         JOIN forma_pago fp ON fp.id = p.forma_pago_id 
         WHERE p.orden_id = o.id 
         ORDER BY p.fecha_pago DESC 
         LIMIT 1) AS forma_pago_nombre,
        -- Referencia del pago (incluye info de débito/crédito)
        (SELECT p.referencia 
         FROM pago p 
         WHERE p.orden_id = o.id 
         ORDER BY p.fecha_pago DESC 
         LIMIT 1) AS pago_referencia,
        -- Mesero (quien creó la orden)
        o.creado_por_usuario_id AS mesero_id,
        u_mesero.nombre AS mesero_nombre,
        u_mesero.username AS mesero_username,
        -- Información de impresión
        ${hasBitacoraTable ? `
        CASE WHEN EXISTS(
          SELECT 1 FROM bitacora_impresion bi 
          WHERE bi.orden_id = o.id AND bi.exito = 1
        ) THEN 1 ELSE 0 END AS impreso,
        (SELECT bi.usuario_id 
         FROM bitacora_impresion bi 
         WHERE bi.orden_id = o.id AND bi.exito = 1 
         ORDER BY bi.creado_en DESC 
         LIMIT 1) AS impreso_por_id,
        (SELECT u_imp.nombre 
         FROM bitacora_impresion bi 
         JOIN usuario u_imp ON u_imp.id = bi.usuario_id 
         WHERE bi.orden_id = o.id AND bi.exito = 1 
         ORDER BY bi.creado_en DESC 
         LIMIT 1) AS impreso_por_nombre,
        (SELECT bi.creado_en 
         FROM bitacora_impresion bi 
         WHERE bi.orden_id = o.id AND bi.exito = 1 
         ORDER BY bi.creado_en DESC 
         LIMIT 1) AS impreso_en,
        (SELECT CASE WHEN bi.exito = 1 THEN 1 ELSE 0 END
         FROM bitacora_impresion bi 
         WHERE bi.orden_id = o.id 
         ORDER BY bi.creado_en DESC 
         LIMIT 1) AS ultima_impresion_exitosa
        ` : `
        0 AS impreso,
        NULL AS impreso_por_id,
        NULL AS impreso_por_nombre,
        NULL AS impreso_en,
        0 AS ultima_impresion_exitosa
        `}
      FROM orden o
      LEFT JOIN mesa m ON m.id = o.mesa_id
      LEFT JOIN cliente c ON c.id = o.cliente_id
      JOIN estado_orden eo ON eo.id = o.estado_orden_id
      LEFT JOIN usuario u_mesero ON u_mesero.id = o.creado_por_usuario_id
      WHERE eo.nombre = 'pagada'
        -- Excluir órdenes que son parte de una cuenta agrupada (tienen referencia "Cuenta agrupada")
        -- PERO solo si NO es la orden principal (la orden principal debe aparecer)
        AND NOT EXISTS (
          SELECT 1 
          FROM pago p 
          WHERE p.orden_id = o.id 
            AND p.referencia LIKE 'Cuenta agrupada (%'
            -- Excluir solo si la referencia menciona otra orden (no esta misma)
            AND p.referencia NOT LIKE CONCAT('Cuenta agrupada (Orden ', o.id, ')')
        )
        -- Asegurar que la orden tenga al menos un pago aplicado (esto garantiza que realmente fue pagada)
        AND EXISTS (
          SELECT 1 
          FROM pago p 
          WHERE p.orden_id = o.id 
            AND p.estado = 'aplicado'
        )
      ORDER BY o.creado_en DESC
      LIMIT 500
    `;

    const [rows] = await pool.query<TicketListRow[]>(query);

    // Mapa para rastrear órdenes que son parte de cuentas agrupadas
    const ordenesAgrupadas = new Map<number, number[]>(); // ordenPrincipal -> [ordenId1, ordenId2, ...]
    
    // Buscar todas las órdenes que son parte de cuentas agrupadas (optimización: una sola query)
    const [pagosAgrupados] = await pool.query<RowDataPacket[]>(
      `SELECT 
         p.orden_id,
         p.referencia
       FROM pago p 
       WHERE p.referencia LIKE 'Cuenta agrupada (%'
       ORDER BY p.orden_id`
    );
    
    // Extraer órdenes principales desde las referencias
    for (const pago of pagosAgrupados) {
      const referencia = pago.referencia as string;
      const match = referencia.match(/Cuenta agrupada \(Orden (\d+)\)/);
      if (match) {
        const ordenPrincipalId = parseInt(match[1]);
        const ordenSecundariaId = pago.orden_id as number;
        
        // Agregar a la lista de órdenes agrupadas
        if (!ordenesAgrupadas.has(ordenPrincipalId)) {
          ordenesAgrupadas.set(ordenPrincipalId, [ordenPrincipalId]);
        }
        const ordenIds = ordenesAgrupadas.get(ordenPrincipalId)!;
        if (!ordenIds.includes(ordenSecundariaId)) {
          ordenIds.push(ordenSecundariaId);
        }
      }
    }

    // Filtrar tickets: solo incluir órdenes principales (no las relacionadas)
    const tickets: TicketListItem[] = [];
    const ordenesProcesadas = new Set<number>();

    for (const row of rows) {
      // Si esta orden es parte de una cuenta agrupada, ya fue procesada o será procesada como principal
      if (ordenesProcesadas.has(row.orden_id)) {
        continue;
      }

      const ordenIdsAgrupados = ordenesAgrupadas.get(row.orden_id);
      
      if (ordenIdsAgrupados && ordenIdsAgrupados.length > 1) {
        // Esta es una cuenta agrupada: obtener datos de todas las órdenes y combinarlos
        const [ordenesAgrupadasData] = await pool.query<RowDataPacket[]>(
          `SELECT 
            o.id, o.subtotal, o.descuento_total, o.impuesto_total, 
            o.total, o.creado_en,
            (SELECT COALESCE(SUM(pr.monto), 0)
             FROM propina pr
             WHERE pr.orden_id = o.id) AS propina_pago
           FROM orden o
           WHERE o.id IN (${ordenIdsAgrupados.map(() => '?').join(',')})`,
          ordenIdsAgrupados
        );

        // Calcular totales combinados
        let subtotalTotal = Number(row.orden_subtotal);
        let descuentoTotal = Number(row.orden_descuento);
        let impuestoTotal = Number(row.orden_impuesto);
        // Usar propina real del pago (de la tabla propina) en lugar de propina sugerida
        let propinaTotal = row.propina_pago ? Number(row.propina_pago) : 0;
        let totalTotal = Number(row.orden_total);
        let fechaMasAntigua = new Date(row.orden_fecha);

        for (const ordenData of ordenesAgrupadasData) {
          if (ordenData.id !== row.orden_id) {
            subtotalTotal += Number(ordenData.subtotal);
            descuentoTotal += Number(ordenData.descuento_total);
            impuestoTotal += Number(ordenData.impuesto_total);
            propinaTotal += ordenData.propina_pago ? Number(ordenData.propina_pago) : 0;
            totalTotal += Number(ordenData.total);
            const fechaOrden = new Date(ordenData.creado_en);
            if (fechaOrden < fechaMasAntigua) {
              fechaMasAntigua = fechaOrden;
            }
          }
        }

        // Generar ID de ticket agrupado
        const ordenIdsOrdenados = [...ordenIdsAgrupados].sort((a, b) => a - b);
        const ticketId = `CUENTA-AGRUPADA-${ordenIdsOrdenados.map(id => String(id).padStart(6, '0')).join('-')}`;

        // Determinar el estado del ticket (considerando todas las órdenes)
        let status = 'pending';
        if (hasBitacoraTable) {
          const [impresiones] = await pool.query<RowDataPacket[]>(
            `SELECT COUNT(*) as count 
             FROM bitacora_impresion bi 
             WHERE bi.orden_id IN (${ordenIdsAgrupados.map(() => '?').join(',')}) 
               AND bi.exito = 1`,
            ordenIdsAgrupados
          );
          if ((impresiones[0]?.count as number) > 0) {
            status = 'printed';
          }
        }

        // Obtener método de pago y referencia del último pago de la orden principal
        const [pagoAgrupado] = await pool.query<RowDataPacket[]>(
          `SELECT fp.nombre, p.referencia 
           FROM pago p 
           JOIN forma_pago fp ON fp.id = p.forma_pago_id 
           WHERE p.orden_id = ? 
           ORDER BY p.fecha_pago DESC 
           LIMIT 1`,
          [row.orden_id]
        );
        // Si la referencia contiene información de débito/crédito, usarla; si no, usar el nombre de la forma de pago
        const referencia = pagoAgrupado[0]?.referencia;
        const formaPagoNombre = pagoAgrupado[0]?.nombre || null;
        const paymentMethod = (referencia && (referencia.includes('Tarjeta Débito') || referencia.includes('Tarjeta Crédito')))
          ? referencia.split(' - ')[0] // Extraer solo el tipo de tarjeta (ej: "Tarjeta Débito")
          : formaPagoNombre;
        const paymentReference = referencia || null;

        tickets.push({
          id: ticketId,
          ordenId: row.orden_id, // Orden principal para compatibilidad
          ordenIds: ordenIdsAgrupados, // TODAS las órdenes agrupadas
          tableNumber: row.mesa_codigo ? parseInt(row.mesa_codigo.replace(/\D/g, '')) || null : null,
          mesaCodigo: row.mesa_codigo,
          mesaNombre: row.mesa_nombre,
          customerName: row.cliente_nombre,
          customerPhone: row.cliente_telefono || null,
          subtotal: subtotalTotal,
          discount: descuentoTotal,
          tax: impuestoTotal,
          tip: propinaTotal > 0 ? propinaTotal : null,
          total: totalTotal,
          status,
          createdAt: utcToMxISO(fechaMasAntigua) ?? new Date().toISOString(),
          waiterName: row.mesero_nombre,
          cashierName: row.cajero_nombre,
          paymentMethod: paymentMethod,
          paymentReference: paymentReference,
          isPrinted: status === 'printed',
          printedBy: row.impreso_por_nombre,
          printedAt: row.impreso_en ? utcToMxISO(row.impreso_en) : null,
          isGrouped: true
        });

        // Marcar todas las órdenes como procesadas
        for (const ordenId of ordenIdsAgrupados) {
          ordenesProcesadas.add(ordenId);
        }
      } else {
        // Ticket individual (no agrupado)
        let status = 'pending';
        if (row.impreso === 1 && row.ultima_impresion_exitosa === 1) {
          status = 'printed';
        }

        tickets.push({
          id: row.orden_folio,
          ordenId: row.orden_id,
          tableNumber: row.mesa_codigo ? parseInt(row.mesa_codigo.replace(/\D/g, '')) || null : null,
          mesaCodigo: row.mesa_codigo,
          mesaNombre: row.mesa_nombre,
          customerName: row.cliente_nombre,
          customerPhone: row.cliente_telefono || null,
          subtotal: Number(row.orden_subtotal),
          discount: Number(row.orden_descuento),
          tax: Number(row.orden_impuesto),
          tip: row.propina_pago && Number(row.propina_pago) > 0 ? Number(row.propina_pago) : null,
          total: Number(row.orden_total),
          status,
          createdAt: utcToMxISO(row.orden_fecha) ?? new Date().toISOString(),
          waiterName: row.mesero_nombre,
          cashierName: row.cajero_nombre,
          paymentMethod: (() => {
            // Si la referencia contiene información de débito/crédito, usarla
            const referencia = row.pago_referencia;
            const formaPagoNombre = row.forma_pago_nombre || null;
            if (referencia && (referencia.includes('Tarjeta Débito') || referencia.includes('Tarjeta Crédito'))) {
              return referencia.split(' - ')[0]; // Extraer solo el tipo de tarjeta
            }
            return formaPagoNombre;
          })(),
          paymentReference: row.pago_referencia || null,
          isPrinted: row.impreso === 1,
          printedBy: row.impreso_por_nombre,
          printedAt: row.impreso_en ? utcToMxISO(row.impreso_en) : null
        });

        ordenesProcesadas.add(row.orden_id);
      }
    }

    return tickets;
  } catch (error: any) {
    // Si hay error con bitacora_impresion, retornar lista vacía o manejar el error
    if (error.code === 'ER_NO_SUCH_TABLE') {
      console.warn('Tabla bitacora_impresion no existe, retornando tickets sin información de impresión');
      // Retornar solo órdenes pagadas sin info de impresión
      return [];
    }
    throw error;
  }
};

