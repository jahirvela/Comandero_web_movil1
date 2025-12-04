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

export const obtenerDatosTicket = async (ordenId: number, cajeroId?: number): Promise<TicketData> => {
  // Obtener orden base
  const ordenBase = await obtenerOrdenBasePorId(ordenId);
  if (!ordenBase) {
    throw new Error(`Orden ${ordenId} no encontrada`);
  }

  // Obtener items de la orden
  const items = await obtenerItemsOrden(ordenId);
  const itemIds = items.map((item) => item.id);
  const modificadores = await obtenerModificadoresItem(itemIds);

  // Crear mapa de modificadores por item
  const modificadoresPorItem = new Map<number, typeof modificadores>();
  for (const mod of modificadores) {
    if (!modificadoresPorItem.has(mod.ordenItemId)) {
      modificadoresPorItem.set(mod.ordenItemId, []);
    }
    modificadoresPorItem.get(mod.ordenItemId)!.push(mod);
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
  const itemsFormateados = items.map((item) => ({
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

  return {
    orden: {
      id: ordenBase.id,
      folio: `ORD-${String(ordenBase.id).padStart(6, '0')}`,
      // Convertir creadoEn (string ISO) a Date para mantener compatibilidad con TicketData
      fecha: typeof ordenBase.creadoEn === 'string' ? new Date(ordenBase.creadoEn) : ordenBase.creadoEn,
      mesaCodigo: ordenBase.mesaCodigo,
      clienteNombre: ordenBase.clienteNombre,
      clienteTelefono: ordenBase.clienteTelefono || null,
      subtotal: ordenBase.subtotal,
      descuentoTotal: ordenBase.descuentoTotal,
      impuestoTotal: ordenBase.impuestoTotal,
      propinaSugerida: ordenBase.propinaSugerida,
      total: ordenBase.total
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
  impreso: number; // 0 o 1
  impreso_por_id: number | null;
  impreso_por_nombre: string | null;
  impreso_en: Date | null;
  ultima_impresion_exitosa: number; // 0 o 1
}

export interface TicketListItem {
  id: string; // Folio de la orden
  ordenId: number;
  tableNumber: number | null;
  customerName: string | null;
  subtotal: number;
  discount: number;
  tax: number;
  total: number;
  status: string; // 'pending', 'printed', 'delivered'
  createdAt: string; // ISO string en zona CDMX
  waiterName: string | null;
  cashierName: string | null;
  isPrinted: boolean;
  printedBy: string | null;
  printedAt: string | null; // ISO string en zona CDMX
}

export const listarTickets = async (): Promise<TicketListItem[]> => {
  try {
    // Verificar si la tabla bitacora_impresion existe
    const [tableCheck] = await pool.query<RowDataPacket[]>(
      `SELECT COUNT(*) as count 
       FROM information_schema.tables 
       WHERE table_schema = DATABASE() 
       AND table_name = 'bitacora_impresion'`
    );

    const hasBitacoraTable = (tableCheck[0]?.count as number) > 0;

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
      ORDER BY o.creado_en DESC
    `;

    const [rows] = await pool.query<TicketListRow[]>(query);

    return rows.map((row) => {
      // Determinar el estado del ticket
      let status = 'pending';
      if (row.impreso === 1 && row.ultima_impresion_exitosa === 1) {
        status = 'printed';
      }

      return {
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
        tip: row.orden_propina ? Number(row.orden_propina) : null,
        total: Number(row.orden_total),
        status,
        createdAt: utcToMxISO(row.orden_fecha) ?? new Date().toISOString(),
        waiterName: row.mesero_nombre,
        cashierName: row.cajero_nombre,
        isPrinted: row.impreso === 1,
        printedBy: row.impreso_por_nombre,
        printedAt: row.impreso_en ? utcToMxISO(row.impreso_en) : null
      };
    });
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

