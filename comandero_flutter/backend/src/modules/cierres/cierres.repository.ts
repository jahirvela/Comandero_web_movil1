import type { RowDataPacket, ResultSetHeader } from 'mysql2';
import { pool } from '../../db/pool.js';
import {
  utcToMx,
  utcToMxISO,
  getDateOnlyMx,
  sqlDateColumnToMxStartIso,
  sqlDateUtcToYmd,
  todayMxString
} from '../../config/time.js';

const FECHA_PAGO_MX_SQL = "DATE(CONVERT_TZ(p.fecha_pago, '+00:00', '-06:00'))";
const FECHA_PP_MX_SQL = "DATE(CONVERT_TZ(pp.fecha, '+00:00', '-06:00'))";

/** Apertura de caja: no debe heredar propinas agregadas del día completo. */
function esAperturaCajaManual(
  eventoTipo: unknown,
  totalVentas: number,
  efectivoInicial: unknown
): boolean {
  const t =
    eventoTipo === null || eventoTipo === undefined ? '' : String(eventoTipo).trim();
  if (t === 'apertura') return true;
  if (t === 'cierre' || t === 'cierre_dia') return false;
  let ini = 0;
  if (efectivoInicial != null && efectivoInicial !== '') {
    const n = Number(efectivoInicial);
    if (!Number.isNaN(n)) ini = n;
  }
  return totalVentas < 0.01 && ini > 0.01;
}

interface CierreCajaRow extends RowDataPacket {
  fecha: Date;
  cajero_id: number | null;
  cajero_nombre: string | null;
  cajero_username: string | null;
  numero_ordenes: number;
  total_ventas: number;
  total_efectivo: number;
  total_tarjeta: number;
  total_otros: number;
  total_propinas: number;
  total_propinas_efectivo: number;
  total_propinas_tarjeta: number;
}

export interface CierreCajaItem {
  id: string; // ID único: para manuales es "cierre-{id}", para calculados es "calc-{fecha}-{cajero_id}"
  fecha: string; // ISO string
  cajeroId: number | null;
  cajeroNombre: string | null;
  cajeroUsername: string | null;
  numeroOrdenes: number;
  totalVentas: number;
  totalEfectivo: number;
  totalTarjeta: number;
  totalOtros: number;
  totalPropinas: number;
  propinasEfectivo: number; // Propinas registradas en pagos con efectivo
  propinasTarjeta: number;  // Propinas registradas en pagos con tarjeta
  status: string; // 'pending', 'approved', 'rejected', 'clarification'
  cierreId?: number; // ID real del cierre manual en la BD (opcional, solo para manuales)
  creadoEn?: string; // Fecha de creación del cierre manual (opcional)
  notas?: string | null; // Notas/comentarios del cajero (opcional)
  comentarioRevision?: string | null; // Comentario del administrador al revisar (opcional)
  efectivoInicial?: number; // Efectivo inicial de la apertura de caja (opcional)
  eventoTipo?: 'apertura' | 'cierre' | 'cierre_dia';
  turnoCodigo?: string | null;
  turnoLabel?: string | null;
}

function normalizeNotasHuella(s: string | null | undefined): string {
  if (s == null || !String(s).trim()) return '';
  return String(s)
    .trim()
    .replace(/\s+/g, ' ')
    .toLowerCase();
}

/** Colapsa el mismo evento insertado varias veces en BD (IDs distintos). No fusiona filas `calc-*`. */
function huellaListaCierre(item: CierreCajaItem): string {
  if (item.id.startsWith('calc-')) return `calc:${item.id}`;
  const fechaMs = Date.parse(item.fecha);
  const bucket = Number.isFinite(fechaMs) ? Math.floor(fechaMs / 60000) : 0;
  const evt = (item.eventoTipo ?? '').trim().toLowerCase();
  const turno = (item.turnoCodigo ?? '').trim().toLowerCase();
  const usr = (item.cajeroNombre ?? '').trim().toLowerCase();
  const cents = (n: number) => Math.round((Number.isFinite(n) ? n : 0) * 100);
  const note = normalizeNotasHuella(item.notas ?? null);
  const tipoTag =
    evt === 'apertura' ? 'A' : evt === 'cierre_dia' ? 'D' : 'C';
  return `${tipoTag}|${evt}|${turno}|${usr}|${bucket}|${cents(item.totalVentas)}|${cents(
    item.efectivoInicial ?? 0
  )}|${cents(item.totalEfectivo)}|${cents(item.totalTarjeta)}|${note}`;
}

function dedupeListarCierresResult(items: CierreCajaItem[]): CierreCajaItem[] {
  const groups = new Map<string, CierreCajaItem[]>();
  for (const it of items) {
    const k = huellaListaCierre(it);
    const g = groups.get(k);
    if (g) g.push(it);
    else groups.set(k, [it]);
  }
  const out: CierreCajaItem[] = [];
  for (const arr of groups.values()) {
    if (arr.length === 1) {
      out.push(arr[0]);
      continue;
    }
    arr.sort((a, b) => {
      const ida = a.cierreId ?? Number.MAX_SAFE_INTEGER;
      const idb = b.cierreId ?? Number.MAX_SAFE_INTEGER;
      return ida - idb;
    });
    out.push(arr[0]);
  }
  return out;
}

export const listarCierresCaja = async (
  fechaInicio?: Date,
  fechaFin?: Date,
  cajeroId?: number
): Promise<CierreCajaItem[]> => {
  console.log('🔍 CierresRepository: listarCierresCaja llamado con:', { fechaInicio, fechaFin, cajeroId });
  
  const conditionsPago: string[] = [];
  const conditionsCierre: string[] = [];
  const params: Record<string, unknown> = {};

  // Filtro de fechas para pagos - convertir a string usando zona CDMX
  if (fechaInicio && fechaFin) {
    const fechaInicioStr = getDateOnlyMx(fechaInicio) ?? (fechaInicio instanceof Date ? fechaInicio.toISOString().split('T')[0] : fechaInicio);
    const fechaFinStr = getDateOnlyMx(fechaFin) ?? (fechaFin instanceof Date ? fechaFin.toISOString().split('T')[0] : fechaFin);
    conditionsPago.push(`${FECHA_PAGO_MX_SQL} BETWEEN DATE(:fechaInicio) AND DATE(:fechaFin)`);
    conditionsCierre.push('DATE(cc.fecha) BETWEEN DATE(:fechaInicio) AND DATE(:fechaFin)');
    params.fechaInicio = fechaInicioStr;
    params.fechaFin = fechaFinStr;
  } else if (fechaInicio) {
    const fechaInicioStr = getDateOnlyMx(fechaInicio) ?? (fechaInicio instanceof Date ? fechaInicio.toISOString().split('T')[0] : fechaInicio);
    conditionsPago.push(`${FECHA_PAGO_MX_SQL} >= DATE(:fechaInicio)`);
    conditionsCierre.push('DATE(cc.fecha) >= DATE(:fechaInicio)');
    params.fechaInicio = fechaInicioStr;
  } else if (fechaFin) {
    const fechaFinStr = getDateOnlyMx(fechaFin) ?? (fechaFin instanceof Date ? fechaFin.toISOString().split('T')[0] : fechaFin);
    conditionsPago.push(`${FECHA_PAGO_MX_SQL} <= DATE(:fechaFin)`);
    conditionsCierre.push('DATE(cc.fecha) <= DATE(:fechaFin)');
    params.fechaFin = fechaFinStr;
  }

  // Filtro por cajero
  if (cajeroId) {
    conditionsPago.push('p.empleado_id = :cajeroId');
    conditionsCierre.push('cc.creado_por_usuario_id = :cajeroId');
    params.cajeroId = cajeroId;
  }

  const whereClausePago = conditionsPago.length > 0 ? `AND ${conditionsPago.join(' AND ')}` : '';
  const whereClauseCierre = conditionsCierre.length > 0 ? `WHERE ${conditionsCierre.join(' AND ')}` : '';

  // 1. Obtener cierres calculados desde pagos (totales reales de ventas)
  const [rowsCalculados] = await pool.execute<CierreCajaRow[]>(
    `
    SELECT
      ${FECHA_PAGO_MX_SQL} AS fecha,
      p.empleado_id AS cajero_id,
      u.nombre AS cajero_nombre,
      u.username AS cajero_username,
      COUNT(DISTINCT o.id) AS numero_ordenes,
      COALESCE(SUM(o.total), 0) AS total_ventas,
      COALESCE(SUM(CASE WHEN LOWER(fp.nombre) = 'efectivo' THEN p.monto ELSE 0 END), 0) AS total_efectivo,
      COALESCE(SUM(CASE WHEN LOWER(fp.nombre) LIKE 'tarjeta%' THEN p.monto ELSE 0 END), 0) AS total_tarjeta,
      COALESCE(SUM(CASE WHEN LOWER(fp.nombre) NOT IN ('efectivo') AND LOWER(fp.nombre) NOT LIKE 'tarjeta%' THEN p.monto ELSE 0 END), 0) AS total_otros,
      COALESCE(SUM(prop.monto), 0) AS total_propinas,
      0 AS total_propinas_efectivo,
      0 AS total_propinas_tarjeta
    FROM pago p
    INNER JOIN orden o ON o.id = p.orden_id
    LEFT JOIN forma_pago fp ON fp.id = p.forma_pago_id
    LEFT JOIN propina prop ON prop.orden_id = o.id
    LEFT JOIN usuario u ON u.id = p.empleado_id
    WHERE p.estado = 'aplicado'
      AND o.estado_orden_id IN (
        SELECT id FROM estado_orden WHERE nombre IN ('pagada', 'cerrada')
      )
      ${whereClausePago}
    GROUP BY ${FECHA_PAGO_MX_SQL}, p.empleado_id, u.id, u.nombre, u.username
    `,
    params
  );
  console.log(`✅ CierresRepository: ${rowsCalculados.length} cierres calculados encontrados`);

  // 1b. Obtener propinas por tipo (efectivo vs tarjeta) prorrateadas por monto de pago
  // Para cada orden con propina: prorratear según monto efectivo/tarjeta de sus pagos
  const wherePropinas = conditionsPago.length > 0
    ? ' AND ' + conditionsPago
        .map(c => c.replace(new RegExp(FECHA_PAGO_MX_SQL.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g'), FECHA_PP_MX_SQL).replace(/p\.empleado_id/g, 'pp.empleado_id'))
        .join(' AND ')
    : '';
  interface PropinasTipoRow extends RowDataPacket { fecha: Date; cajero_id: number | null; total_propinas_efectivo: number; total_propinas_tarjeta: number; }
  const [rowsPropinasTipo] = await pool.execute<PropinasTipoRow[]>(
    `
    SELECT
      pp.fecha AS fecha,
      pp.empleado_id AS cajero_id,
      COALESCE(SUM(
        pr.propina_monto *
        COALESCE(
          (SELECT SUM(CASE WHEN LOWER(fp2.nombre) = 'efectivo' THEN p2.monto ELSE 0 END) / NULLIF(SUM(p2.monto), 0)
           FROM pago p2 JOIN forma_pago fp2 ON fp2.id = p2.forma_pago_id
           WHERE p2.orden_id = pr.orden_id AND p2.estado = 'aplicado'),
          0.5
        )
      ), 0) AS total_propinas_efectivo,
      COALESCE(SUM(
        pr.propina_monto *
        COALESCE(
          (SELECT SUM(CASE WHEN LOWER(fp2.nombre) LIKE 'tarjeta%' THEN p2.monto ELSE 0 END) / NULLIF(SUM(p2.monto), 0)
           FROM pago p2 JOIN forma_pago fp2 ON fp2.id = p2.forma_pago_id
           WHERE p2.orden_id = pr.orden_id AND p2.estado = 'aplicado'),
          0.5
        )
      ), 0) AS total_propinas_tarjeta
    FROM (SELECT orden_id, SUM(monto) AS propina_monto FROM propina GROUP BY orden_id) pr
    INNER JOIN orden o ON o.id = pr.orden_id
    INNER JOIN (
      SELECT p1.orden_id, p1.empleado_id, p1.fecha_pago AS fecha
      FROM pago p1
      WHERE p1.estado = 'aplicado'
        AND NOT EXISTS (
          SELECT 1 FROM pago p2
          WHERE p2.orden_id = p1.orden_id AND p2.estado = 'aplicado'
            AND p2.fecha_pago < p1.fecha_pago
        )
    ) pp ON pp.orden_id = o.id
    WHERE o.estado_orden_id IN (SELECT id FROM estado_orden WHERE nombre IN ('pagada', 'cerrada'))
      ${wherePropinas}
    GROUP BY pp.fecha, pp.empleado_id
    `,
    params
  );

  // Map (fecha-cajero_id) -> { propinasEfectivo, propinasTarjeta }
  const propinasTipoMap = new Map<string, { propinasEfectivo: number; propinasTarjeta: number }>();
  // Map fecha -> total propinas del día (suma de todos los empleados) - para cierres manuales
  const propinasPorFechaMap = new Map<string, { propinasEfectivo: number; propinasTarjeta: number }>();
  for (const row of rowsPropinasTipo) {
    const fechaStr = row.fecha instanceof Date ? row.fecha.toISOString().split('T')[0] : String(row.fecha).split('T')[0];
    const key = `${fechaStr}-${row.cajero_id ?? 'sin-cajero'}`;
    const propEf = Number(row.total_propinas_efectivo);
    const propTj = Number(row.total_propinas_tarjeta);
    propinasTipoMap.set(key, { propinasEfectivo: propEf, propinasTarjeta: propTj });
    // Acumular por fecha (para cierres manuales que pueden ser de un cajero distinto al que procesó pagos)
    const prev = propinasPorFechaMap.get(fechaStr) ?? { propinasEfectivo: 0, propinasTarjeta: 0 };
    propinasPorFechaMap.set(fechaStr, {
      propinasEfectivo: prev.propinasEfectivo + propEf,
      propinasTarjeta: prev.propinasTarjeta + propTj
    });
  }

  // 2. Obtener cierres manuales desde caja_cierre (declaraciones del cajero)
  // Primero hacer una consulta sin filtros para verificar que hay cierres manuales
  const [todosLosCierres] = await pool.execute<RowDataPacket[]>(
    `SELECT COUNT(*) as total FROM caja_cierre`
  );
  console.log(`🔍 CierresRepository: Total de cierres manuales en BD: ${todosLosCierres[0]?.total || 0}`);
  
  const [rowsManuales] = await pool.execute<RowDataPacket[]>(
    `
            SELECT
              cc.fecha AS fecha,
              cc.creado_por_usuario_id AS cajero_id,
              u_cc.nombre AS cajero_nombre,
              u_cc.username AS cajero_username,
              COALESCE(cc.total_pagos, cc.total_efectivo + cc.total_tarjeta, 0) AS total_ventas,
              COALESCE(cc.total_efectivo, 0) AS total_efectivo,
              COALESCE(cc.total_tarjeta, 0) AS total_tarjeta,
              COALESCE(cc.otros_ingresos, 0) AS otros_ingresos,
              cc.otros_ingresos_texto AS otros_ingresos_texto,
              cc.id AS cierre_id,
              cc.efectivo_inicial AS efectivo_inicial,
              cc.efectivo_final AS efectivo_final,
              cc.notas AS notas,
              cc.creado_en AS creado_en,
              COALESCE(cc.estado, 'pending') AS estado,
              cc.comentario_revision AS comentario_revision,
              cc.evento_tipo AS evento_tipo,
              cc.turno_codigo AS turno_codigo,
              cc.turno_label AS turno_label
            FROM caja_cierre cc
            LEFT JOIN usuario u_cc ON u_cc.id = cc.creado_por_usuario_id
            ${whereClauseCierre}
            ORDER BY cc.creado_en DESC, cc.fecha DESC
    `,
    params
  );
  
  console.log(`✅ CierresRepository: ${rowsManuales.length} cierres manuales encontrados con filtros`);
  console.log(`🔍 CierresRepository: whereClauseCierre: "${whereClauseCierre}"`);
  console.log(`🔍 CierresRepository: params:`, params);
  if (rowsManuales.length > 0) {
    console.log('📋 CierresRepository: Primer cierre manual:', JSON.stringify(rowsManuales[0], null, 2));
  } else {
    console.log('⚠️ CierresRepository: No se encontraron cierres manuales con los filtros aplicados');
  }

  // 3. Combinar ambos resultados, dando prioridad absoluta a los cierres manuales
  // Cada cierre manual tiene su propio ID único, no se combinan
  const cierresList: CierreCajaItem[] = [];
  const cierresCalculadosMap = new Map<string, CierreCajaItem>();

  // Primero agregar los cierres calculados a un mapa temporal
  for (const row of rowsCalculados) {
    // row.fecha proviene de SQL DATE(...), sin hora. Si se trata como UTC y luego se convierte
    // a CDMX, se desplaza a 18:00 del día anterior. Anclar explícitamente al inicio del día CDMX.
    const fecha = sqlDateColumnToMxStartIso(row.fecha) ?? new Date().toISOString();
    const fechaSoloStr = getDateOnlyMx(fecha) ?? new Date().toISOString().split('T')[0];
    
    const key = `calc-${fechaSoloStr}-${row.cajero_id ?? 'sin-cajero'}`;
    const propinasKey = `${fechaSoloStr}-${row.cajero_id ?? 'sin-cajero'}`; // Sin "calc-" para coincidir con propinasTipoMap
    const propinasTipo = propinasTipoMap.get(propinasKey) ?? { propinasEfectivo: 0, propinasTarjeta: 0 };

    cierresCalculadosMap.set(key, {
      id: key,
      fecha,
      cajeroId: row.cajero_id,
      cajeroNombre: row.cajero_nombre,
      cajeroUsername: row.cajero_username,
      numeroOrdenes: Number(row.numero_ordenes),
      totalVentas: Number(row.total_ventas),
      totalEfectivo: Number(row.total_efectivo),
      totalTarjeta: Number(row.total_tarjeta),
      totalOtros: Number(row.total_otros),
      totalPropinas: Number(row.total_propinas),
      propinasEfectivo: propinasTipo.propinasEfectivo,
      propinasTarjeta: propinasTipo.propinasTarjeta,
      status: 'pending' // Cierres calculados también están pendientes de revisión
    });
  }

  // Agregar TODOS los cierres manuales con ID único (cada uno es independiente)
  const fechasConManual = new Set<string>(); // Para rastrear qué fechas/cajeros ya tienen manual
  
  for (const row of rowsManuales) {
    // Para cierres manuales, usar la fecha de creación (creado_en) si existe, sino usar la fecha del cierre
    // Convertir a zona CDMX para mostrar correctamente
    let fecha: string;
    if (row.creado_en) {
      // Si hay fecha de creación, convertirla a zona CDMX
      fecha = utcToMxISO(row.creado_en) ?? new Date().toISOString();
    } else {
      // DATE sin hora: anclar al inicio del día en CDMX (evita corrimiento -6h vs utcToMx directo)
      fecha = sqlDateColumnToMxStartIso(row.fecha) ?? new Date().toISOString();
    }
    
    // ID único para cada cierre manual basado en su ID de BD
    const cierreId = row.cierre_id ? Number(row.cierre_id) : null;
    const fechaSolo = getDateOnlyMx(fecha) ?? fecha.split('T')[0];
    const idUnico = cierreId ? `cierre-${cierreId}` : `cierre-manual-${fechaSolo}-${row.cajero_id ?? 'sin-cajero'}-${Date.now()}`;
    
    // Buscar si hay un cierre calculado para esta fecha/cajero (solo para completar datos)
    const keyCalculado = `calc-${fechaSolo}-${row.cajero_id ?? 'sin-cajero'}`;
    const cierreCalculado = cierresCalculadosMap.get(keyCalculado);

    // Propinas: usar total del DÍA (propinasPorFechaMap) para cierres manuales, porque el cajero
    // que cierra puede ser distinto al empleado que procesó los pagos (mesero). Así mostramos
    // todas las propinas del día en el detalle del cierre.
    const propinasDelDia = propinasPorFechaMap.get(fechaSolo) ?? { propinasEfectivo: 0, propinasTarjeta: 0 };

    // Los valores manuales SIEMPRE tienen prioridad
    const totalVentasManual = row.total_ventas != null ? Number(row.total_ventas) : 0;
    const esApertura = esAperturaCajaManual(
      row.evento_tipo,
      Number.isFinite(totalVentasManual) ? totalVentasManual : 0,
      row.efectivo_inicial
    );
    const propinasEfectivoManual = esApertura ? 0 : propinasDelDia.propinasEfectivo;
    const propinasTarjetaManual = esApertura ? 0 : propinasDelDia.propinasTarjeta;
    const totalEfectivoManual = row.total_efectivo != null ? Number(row.total_efectivo) : 0;
    const totalTarjetaManual = row.total_tarjeta != null ? Number(row.total_tarjeta) : 0;
    const otrosManual =
      row.otros_ingresos != null && !Number.isNaN(Number(row.otros_ingresos))
        ? Number(row.otros_ingresos)
        : null;

    // Crear cierre manual (siempre independiente, no se combina)
    const cierreManual: CierreCajaItem = {
      id: idUnico,
      fecha,
      cajeroId: row.cajero_id ?? null,
      cajeroNombre: row.cajero_nombre ?? 'Sin asignar',
      cajeroUsername: row.cajero_username ?? null,
      numeroOrdenes: cierreCalculado?.numeroOrdenes ?? 0, // Complementar con datos calculados si existen
      totalVentas: totalVentasManual,
      totalEfectivo: totalEfectivoManual,
      totalTarjeta: totalTarjetaManual,
      totalOtros: otrosManual ?? cierreCalculado?.totalOtros ?? 0,
      totalPropinas: esApertura
        ? 0
        : (cierreCalculado?.totalPropinas ??
            propinasEfectivoManual + propinasTarjetaManual),
      propinasEfectivo: propinasEfectivoManual,
      propinasTarjeta: propinasTarjetaManual,
      status: row.estado || 'pending', // Leer el estado desde la BD
      cierreId: cierreId ?? undefined,
      creadoEn: utcToMxISO(row.creado_en) ?? undefined,
      notas: row.notas ?? null, // Incluir las notas del cajero
      comentarioRevision: row.comentario_revision ?? null, // Comentario del administrador
      efectivoInicial: row.efectivo_inicial != null ? Number(row.efectivo_inicial) : undefined, // Efectivo inicial de la apertura
      eventoTipo: row.evento_tipo === 'apertura'
        ? 'apertura'
        : row.evento_tipo === 'cierre_dia'
          ? 'cierre_dia'
          : row.evento_tipo === 'cierre'
            ? 'cierre'
            : undefined,
      turnoCodigo: row.turno_codigo ?? null,
      turnoLabel: row.turno_label ?? null,
    };
    
    cierresList.push(cierreManual);
    console.log(`📝 CierresRepository: Cierre manual agregado - ID: ${idUnico}, Fecha: ${fecha}, Ventas: ${totalVentasManual}, Efectivo: ${totalEfectivoManual}, Tarjeta: ${totalTarjetaManual}`);
    
    // Marcar que esta fecha/cajero ya tiene un manual (solo el primer manual elimina el calculado)
    if (!fechasConManual.has(keyCalculado)) {
      fechasConManual.add(keyCalculado);
      cierresCalculadosMap.delete(keyCalculado);
    }
  }

  // Agregar los cierres calculados que NO tienen un cierre manual correspondiente
  let cierresCalculadosAgregados = 0;
  for (const [key, cierreCalculado] of cierresCalculadosMap.entries()) {
    cierresList.push(cierreCalculado);
    cierresCalculadosAgregados++;
    console.log(`📊 CierresRepository: Cierre calculado agregado (sin manual) - ID: ${key}`);
  }

  // Ordenar cierres: más recientes primero (por fecha de creación si es manual, sino por fecha)
  // Las fechas ya están en zona CDMX, comparar directamente
  const resultado = cierresList.sort((a, b) => {
    // Si ambos tienen creadoEn, usar esa fecha
    if (a.creadoEn && b.creadoEn) {
      const fechaA = utcToMx(a.creadoEn);
      const fechaB = utcToMx(b.creadoEn);
      if (fechaA && fechaB) {
        return fechaB.toMillis() - fechaA.toMillis(); // Más recientes primero
      }
    }
    // Si solo uno tiene creadoEn, darle prioridad
    if (a.creadoEn && !b.creadoEn) return -1;
    if (!a.creadoEn && b.creadoEn) return 1;
    // Si ninguno tiene creadoEn, ordenar por fecha
    const fechaA = utcToMx(a.fecha);
    const fechaB = utcToMx(b.fecha);
    if (fechaA && fechaB && fechaA.toMillis() !== fechaB.toMillis()) {
      return fechaB.toMillis() - fechaA.toMillis(); // Más recientes primero
    }
    return (a.cajeroNombre || '').localeCompare(b.cajeroNombre || '');
  });
  
  const deduped = dedupeListarCierresResult(resultado);
  console.log(
    `✅ CierresRepository: Total ${deduped.length} cierres (antes dedup ${resultado.length}) — ${rowsManuales.length} manuales + ${cierresCalculadosAgregados} calculados (sin manual)`
  );
  return deduped;
};

export interface CrearCierreCajaInput {
  fecha: Date;
  efectivoInicial: number;
  efectivoFinal: number;
  totalPagos?: number | null;
  totalEfectivo?: number | null;
  totalTarjeta?: number | null;
  notas?: string | null;
  otrosIngresos?: number;
  otrosIngresosTexto?: string | null;
  notaCajero?: string | null;
  efectivoContado?: number | null;
  totalDeclarado?: number | null;
  eventoTipo?: 'apertura' | 'cierre' | 'cierre_dia';
  turnoCodigo?: string | null;
  turnoLabel?: string | null;
}

export const crearCierreCaja = async (
  input: CrearCierreCajaInput,
  usuarioId?: number
): Promise<CierreCajaItem> => {
  // Combinar notas sin duplicados (evitar "Enviando cierre | Enviando cierre | ...")
  const parts = [
    input.notas,
    input.notaCajero,
    input.otrosIngresosTexto ? `Otros ingresos: ${input.otrosIngresosTexto}` : null
  ].filter((p): p is string => p != null && typeof p === 'string' && p.trim().length > 0);
  const uniqueParts = parts.filter((p, i) => parts.indexOf(p) === i);
  const notasCompletas = uniqueParts.length > 0 ? uniqueParts.join(' | ') : null;

  // Día operativo en CDMX (nunca usar toISOString().split('T')[0] sobre un Date: desplaza el día en UTC).
  const fechaStr = getDateOnlyMx(input.fecha) ?? todayMxString();

  // Registrar cada evento por separado (apertura, cierre de turno, cierre general del día).
  const eventoTipo = input.eventoTipo ?? 'cierre';

  const notasTrim = (notasCompletas ?? '').trim();

  // Evitar doble INSERT por doble toque / reintento del cliente en pocos segundos (mismo usuario y mismos montos).
  if (usuarioId != null && usuarioId > 0) {
    const [dupRows] = await pool.execute<RowDataPacket[]>(
      `
      SELECT id FROM caja_cierre
      WHERE creado_por_usuario_id = :usuarioId
        AND fecha = :fecha
        AND evento_tipo = :eventoTipo
        AND ABS(COALESCE(total_efectivo, 0) - :totalEfectivo) < 0.06
        AND ABS(COALESCE(total_tarjeta, 0) - :totalTarjeta) < 0.06
        AND ABS(COALESCE(efectivo_inicial, 0) - :efectivoInicial) < 0.06
        AND TRIM(COALESCE(notas, '')) = :notasTrim
        AND creado_en >= UTC_TIMESTAMP() - INTERVAL 120 SECOND
      ORDER BY id ASC
      LIMIT 1
      `,
      {
        usuarioId,
        fecha: fechaStr,
        eventoTipo,
        totalEfectivo: input.totalEfectivo ?? 0,
        totalTarjeta: input.totalTarjeta ?? 0,
        efectivoInicial: input.efectivoInicial ?? 0,
        notasTrim
      }
    );
    if (Array.isArray(dupRows) && dupRows.length > 0) {
      const existingId = Number((dupRows[0] as RowDataPacket).id);
      if (Number.isFinite(existingId) && existingId > 0) {
        const detalleExistente = await obtenerCierreCajaPorId(existingId);
        if (detalleExistente) {
          console.log(
            `♻️ crearCierreCaja: anti-duplicado — retornando cierre existente id=${existingId}`
          );
          return detalleExistente;
        }
      }
    }
  }

  // creado_en siempre en UTC (sesión pool = +00:00), hora real del registro.
  let result: ResultSetHeader;
  try {
    const [insertResult] = await pool.execute<ResultSetHeader>(
      `
    INSERT INTO caja_cierre (
      fecha,
      efectivo_inicial,
      efectivo_final,
      total_pagos,
      total_efectivo,
      total_tarjeta,
      otros_ingresos,
      otros_ingresos_texto,
      creado_por_usuario_id,
      notas,
      estado,
      creado_en,
      evento_tipo,
      turno_codigo,
      turno_label
    )
    VALUES (
      :fecha,
      :efectivoInicial,
      :efectivoFinal,
      :totalPagos,
      :totalEfectivo,
      :totalTarjeta,
      :otrosIngresos,
      :otrosIngresosTexto,
      :usuarioId,
      :notas,
      'pending',
      UTC_TIMESTAMP(),
      :eventoTipo,
      :turnoCodigo,
      :turnoLabel
    )
    `,
      {
        fecha: fechaStr,
        efectivoInicial: input.efectivoInicial,
        efectivoFinal: input.efectivoFinal,
        totalPagos: input.totalPagos ?? null,
        totalEfectivo: input.totalEfectivo ?? null,
        totalTarjeta: input.totalTarjeta ?? null,
        otrosIngresos: input.otrosIngresos ?? 0,
        otrosIngresosTexto: input.otrosIngresosTexto ?? null,
        usuarioId: usuarioId ?? null,
        notas: notasCompletas,
        eventoTipo,
        turnoCodigo: input.turnoCodigo ?? null,
        turnoLabel: input.turnoLabel ?? null,
      }
    );
    result = insertResult;
  } catch (error: any) {
    if (error?.code === 'ER_DUP_ENTRY') {
      throw new Error(
        'La BD local aún tiene restricción única por fecha en caja_cierre. Ejecuta el script local fix-cierre-caja-unique.sql para habilitar cierres por turno.'
      );
    }
    throw error;
  }

  if (result.insertId <= 0) {
    throw new Error('No se pudo crear el cierre de caja. Verifica índice único por fecha en BD local.');
  }
  const cierreId = result.insertId;

  const detalle = await obtenerCierreCajaPorId(cierreId);
  if (!detalle) {
    throw new Error('Cierre creado pero no se pudo leer');
  }
  return detalle;
};

export const actualizarEstadoCierreCaja = async (
  cierreId: number,
  estado: 'pending' | 'approved' | 'rejected' | 'clarification',
  revisadoPorUsuarioId: number,
  comentarioRevision?: string | null
): Promise<void> => {
  await pool.execute(
    `
    UPDATE caja_cierre
    SET estado = :estado,
        revisado_por_usuario_id = :revisadoPorUsuarioId,
        revisado_en = UTC_TIMESTAMP(),
        comentario_revision = :comentarioRevision
    WHERE id = :cierreId
    `,
    {
      cierreId,
      estado,
      revisadoPorUsuarioId,
      comentarioRevision: comentarioRevision || null
    }
  );
};

export const obtenerCierreCajaPorId = async (cierreId: number): Promise<CierreCajaItem | null> => {
  const [rows] = await pool.execute<RowDataPacket[]>(
    `
    SELECT
              cc.fecha AS fecha,
      cc.creado_por_usuario_id AS cajero_id,
      u_cc.nombre AS cajero_nombre,
      u_cc.username AS cajero_username,
      COALESCE(cc.total_pagos, cc.total_efectivo + cc.total_tarjeta, 0) AS total_ventas,
      COALESCE(cc.total_efectivo, 0) AS total_efectivo,
      COALESCE(cc.total_tarjeta, 0) AS total_tarjeta,
      COALESCE(cc.otros_ingresos, 0) AS otros_ingresos,
      cc.otros_ingresos_texto AS otros_ingresos_texto,
      cc.id AS cierre_id,
      cc.efectivo_inicial AS efectivo_inicial,
      cc.efectivo_final AS efectivo_final,
      cc.notas AS notas,
      cc.creado_en AS creado_en,
      cc.estado AS estado,
      cc.comentario_revision AS comentario_revision,
      cc.evento_tipo AS evento_tipo,
      cc.turno_codigo AS turno_codigo,
      cc.turno_label AS turno_label
    FROM caja_cierre cc
    LEFT JOIN usuario u_cc ON u_cc.id = cc.creado_por_usuario_id
    WHERE cc.id = :cierreId
    `,
    { cierreId }
  );

  if (rows.length === 0) {
    return null;
  }

  const row = rows[0];
  // Momento real del cierre (creado_en); si falta, anclar al día operativo del DATE
  const fecha =
    utcToMxISO(row.creado_en) ?? sqlDateColumnToMxStartIso(row.fecha) ?? new Date().toISOString();

  const totalVentasRow = row.total_ventas != null ? Number(row.total_ventas) : 0;
  const esAperturaDetalle = esAperturaCajaManual(
    row.evento_tipo,
    Number.isFinite(totalVentasRow) ? totalVentasRow : 0,
    row.efectivo_inicial
  );

  let propinasEfectivo = 0;
  let propinasTarjeta = 0;
  if (!esAperturaDetalle) {
    // Obtener propinas por tipo para este cierre - TOTAL del día (sin filtrar por cajero),
    // porque el cierre manual puede ser del cajero pero las propinas vienen de pagos del mesero
    const fechaStr = sqlDateUtcToYmd(row.fecha) ?? '';
    interface PropinasPorIdRow extends RowDataPacket {
      total_propinas_efectivo: number;
      total_propinas_tarjeta: number;
    }
    const [rowsPropinas] = await pool.execute<PropinasPorIdRow[]>(
      `
    SELECT
      COALESCE(SUM(
        pr.propina_monto *
        COALESCE(
          (SELECT SUM(CASE WHEN LOWER(fp2.nombre) = 'efectivo' THEN p2.monto ELSE 0 END) / NULLIF(SUM(p2.monto), 0)
           FROM pago p2 JOIN forma_pago fp2 ON fp2.id = p2.forma_pago_id
           WHERE p2.orden_id = pr.orden_id AND p2.estado = 'aplicado'),
          0.5
        )
      ), 0) AS total_propinas_efectivo,
      COALESCE(SUM(
        pr.propina_monto *
        COALESCE(
          (SELECT SUM(CASE WHEN LOWER(fp2.nombre) LIKE 'tarjeta%' THEN p2.monto ELSE 0 END) / NULLIF(SUM(p2.monto), 0)
           FROM pago p2 JOIN forma_pago fp2 ON fp2.id = p2.forma_pago_id
           WHERE p2.orden_id = pr.orden_id AND p2.estado = 'aplicado'),
          0.5
        )
      ), 0) AS total_propinas_tarjeta
    FROM (SELECT orden_id, SUM(monto) AS propina_monto FROM propina GROUP BY orden_id) pr
    INNER JOIN orden o ON o.id = pr.orden_id
    INNER JOIN (
      SELECT p1.orden_id, p1.empleado_id, DATE(p1.fecha_pago) AS fecha
      FROM pago p1
      WHERE p1.estado = 'aplicado'
        AND NOT EXISTS (
          SELECT 1 FROM pago p2
          WHERE p2.orden_id = p1.orden_id AND p2.estado = 'aplicado'
            AND p2.fecha_pago < p1.fecha_pago
        )
    ) pp ON pp.orden_id = o.id
    WHERE o.estado_orden_id IN (SELECT id FROM estado_orden WHERE nombre IN ('pagada', 'cerrada'))
      AND pp.fecha = :fechaStr
    `,
      { fechaStr }
    );
    const propinasRow = rowsPropinas[0];
    propinasEfectivo = propinasRow ? Number(propinasRow.total_propinas_efectivo) : 0;
    propinasTarjeta = propinasRow ? Number(propinasRow.total_propinas_tarjeta) : 0;
  }

  return {
    id: `cierre-${cierreId}`,
    fecha,
    cajeroId: row.cajero_id ?? null,
    cajeroNombre: row.cajero_nombre ?? 'Sin asignar',
    cajeroUsername: row.cajero_username ?? null,
    numeroOrdenes: 0,
    totalVentas: Number(row.total_ventas),
    totalEfectivo: Number(row.total_efectivo),
    totalTarjeta: Number(row.total_tarjeta),
    totalOtros: Number(row.otros_ingresos ?? 0),
    totalPropinas: propinasEfectivo + propinasTarjeta,
    propinasEfectivo,
    propinasTarjeta,
    status: row.estado || 'pending',
    cierreId: cierreId,
    creadoEn: utcToMxISO(row.creado_en) ?? undefined,
    notas: row.notas ?? null,
    comentarioRevision: row.comentario_revision ?? null,
    efectivoInicial: row.efectivo_inicial != null ? Number(row.efectivo_inicial) : undefined,
    eventoTipo: row.evento_tipo === 'apertura'
      ? 'apertura'
      : row.evento_tipo === 'cierre_dia'
        ? 'cierre_dia'
        : row.evento_tipo === 'cierre'
          ? 'cierre'
          : undefined,
    turnoCodigo: row.turno_codigo ?? null,
    turnoLabel: row.turno_label ?? null,
  };
};

