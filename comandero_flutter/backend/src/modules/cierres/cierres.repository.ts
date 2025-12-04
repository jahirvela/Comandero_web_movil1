import type { RowDataPacket, ResultSetHeader } from 'mysql2';
import { pool } from '../../db/pool.js';
import { utcToMx, utcToMxISO, getDateOnlyMx, nowMxISO } from '../../config/time.js';

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
  status: string; // 'pending', 'approved', 'rejected', 'clarification'
  cierreId?: number; // ID real del cierre manual en la BD (opcional, solo para manuales)
  creadoEn?: string; // Fecha de creación del cierre manual (opcional)
  notas?: string | null; // Notas/comentarios del cajero (opcional)
  comentarioRevision?: string | null; // Comentario del administrador al revisar (opcional)
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
    conditionsPago.push('DATE(p.fecha_pago) BETWEEN DATE(:fechaInicio) AND DATE(:fechaFin)');
    conditionsCierre.push('DATE(cc.fecha) BETWEEN DATE(:fechaInicio) AND DATE(:fechaFin)');
    params.fechaInicio = fechaInicioStr;
    params.fechaFin = fechaFinStr;
  } else if (fechaInicio) {
    const fechaInicioStr = getDateOnlyMx(fechaInicio) ?? (fechaInicio instanceof Date ? fechaInicio.toISOString().split('T')[0] : fechaInicio);
    conditionsPago.push('DATE(p.fecha_pago) >= DATE(:fechaInicio)');
    conditionsCierre.push('DATE(cc.fecha) >= DATE(:fechaInicio)');
    params.fechaInicio = fechaInicioStr;
  } else if (fechaFin) {
    const fechaFinStr = getDateOnlyMx(fechaFin) ?? (fechaFin instanceof Date ? fechaFin.toISOString().split('T')[0] : fechaFin);
    conditionsPago.push('DATE(p.fecha_pago) <= DATE(:fechaFin)');
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
      DATE(p.fecha_pago) AS fecha,
      p.empleado_id AS cajero_id,
      u.nombre AS cajero_nombre,
      u.username AS cajero_username,
      COUNT(DISTINCT o.id) AS numero_ordenes,
      COALESCE(SUM(o.total), 0) AS total_ventas,
      COALESCE(SUM(CASE WHEN LOWER(fp.nombre) = 'efectivo' THEN p.monto ELSE 0 END), 0) AS total_efectivo,
      COALESCE(SUM(CASE WHEN LOWER(fp.nombre) LIKE 'tarjeta%' THEN p.monto ELSE 0 END), 0) AS total_tarjeta,
      COALESCE(SUM(CASE WHEN LOWER(fp.nombre) NOT IN ('efectivo') AND LOWER(fp.nombre) NOT LIKE 'tarjeta%' THEN p.monto ELSE 0 END), 0) AS total_otros,
      COALESCE(SUM(prop.monto), 0) AS total_propinas
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
    GROUP BY DATE(p.fecha_pago), p.empleado_id, u.id, u.nombre, u.username
    `,
    params
  );
  console.log(`✅ CierresRepository: ${rowsCalculados.length} cierres calculados encontrados`);

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
              cc.id AS cierre_id,
              cc.efectivo_inicial AS efectivo_inicial,
              cc.efectivo_final AS efectivo_final,
              cc.notas AS notas,
              cc.creado_en AS creado_en,
              COALESCE(cc.estado, 'pending') AS estado,
              cc.comentario_revision AS comentario_revision
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
    // Para cierres calculados, convertir fecha UTC a zona CDMX
    const fechaMx = utcToMx(row.fecha);
    const fecha = fechaMx?.toISO() ?? new Date().toISOString();
    const fechaSoloStr = fechaMx?.toFormat('yyyy-MM-dd') ?? new Date().toISOString().split('T')[0];
    
    const key = `calc-${fechaSoloStr}-${row.cajero_id ?? 'sin-cajero'}`;

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
      // Si no hay fecha de creación, usar la fecha del cierre convertida a CDMX
      const fechaMx = utcToMx(row.fecha);
      fecha = fechaMx?.startOf('day').toISO() ?? new Date().toISOString();
    }
    
    // ID único para cada cierre manual basado en su ID de BD
    const cierreId = row.cierre_id ? Number(row.cierre_id) : null;
    const fechaSolo = getDateOnlyMx(fecha) ?? fecha.split('T')[0];
    const idUnico = cierreId ? `cierre-${cierreId}` : `cierre-manual-${fechaSolo}-${row.cajero_id ?? 'sin-cajero'}-${Date.now()}`;
    
    // Buscar si hay un cierre calculado para esta fecha/cajero (solo para completar datos)
    const keyCalculado = `calc-${fechaSolo}-${row.cajero_id ?? 'sin-cajero'}`;
    const cierreCalculado = cierresCalculadosMap.get(keyCalculado);

    // Los valores manuales SIEMPRE tienen prioridad
    const totalVentasManual = row.total_ventas != null ? Number(row.total_ventas) : 0;
    const totalEfectivoManual = row.total_efectivo != null ? Number(row.total_efectivo) : 0;
    const totalTarjetaManual = row.total_tarjeta != null ? Number(row.total_tarjeta) : 0;
    
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
      totalOtros: cierreCalculado?.totalOtros ?? 0,
      totalPropinas: cierreCalculado?.totalPropinas ?? 0,
      status: row.estado || 'pending', // Leer el estado desde la BD
      cierreId: cierreId ?? undefined,
      creadoEn: utcToMxISO(row.creado_en) ?? undefined,
      notas: row.notas ?? null, // Incluir las notas del cajero
      comentarioRevision: row.comentario_revision ?? null // Comentario del administrador
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
  
  console.log(`✅ CierresRepository: Total de ${resultado.length} cierres - ${rowsManuales.length} manuales + ${cierresCalculadosAgregados} calculados (sin manual)`);
  return resultado;
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
}

export interface CierreCajaCreado {
  id: number;
  fecha: Date;
  efectivoInicial: number;
  efectivoFinal: number;
  totalPagos: number | null;
  totalEfectivo: number | null;
  totalTarjeta: number | null;
  creadoPorUsuarioId: number | null;
  creadoEn: Date;
  notas: string | null;
}

export const crearCierreCaja = async (
  input: CrearCierreCajaInput,
  usuarioId?: number
): Promise<CierreCajaCreado> => {
  // Combinar notas si hay notaCajero
  const notasCompletas = [
    input.notas,
    input.notaCajero,
    input.otrosIngresosTexto ? `Otros ingresos: ${input.otrosIngresosTexto}` : null
  ].filter(Boolean).join(' | ') || null;

  // Convertir fecha a string usando zona CDMX
  const fechaStr = getDateOnlyMx(input.fecha) ?? (input.fecha instanceof Date ? input.fecha.toISOString().split('T')[0] : String(input.fecha).split('T')[0]);

  // IMPORTANTE: Usar INSERT ... ON DUPLICATE KEY UPDATE para manejar cierres duplicados
  // Si ya existe un cierre para esa fecha, actualizarlo en lugar de fallar
  const [result] = await pool.execute<ResultSetHeader>(
    `
    INSERT INTO caja_cierre (
      fecha,
      efectivo_inicial,
      efectivo_final,
      total_pagos,
      total_efectivo,
      total_tarjeta,
      creado_por_usuario_id,
      notas,
      estado
    )
    VALUES (
      :fecha,
      :efectivoInicial,
      :efectivoFinal,
      :totalPagos,
      :totalEfectivo,
      :totalTarjeta,
      :usuarioId,
      :notas,
      'pending'
    )
    ON DUPLICATE KEY UPDATE
      efectivo_final = VALUES(efectivo_final),
      total_pagos = VALUES(total_pagos),
      total_efectivo = VALUES(total_efectivo),
      total_tarjeta = VALUES(total_tarjeta),
      notas = VALUES(notas),
      estado = 'pending',
      creado_por_usuario_id = VALUES(creado_por_usuario_id)
    `,
    {
      fecha: fechaStr,
      efectivoInicial: input.efectivoInicial,
      efectivoFinal: input.efectivoFinal,
      totalPagos: input.totalPagos ?? null,
      totalEfectivo: input.totalEfectivo ?? null,
      totalTarjeta: input.totalTarjeta ?? null,
      usuarioId: usuarioId ?? null,
      notas: notasCompletas
    }
  );

  // Obtener el ID del cierre (puede ser insertId si es nuevo, o el ID existente si se actualizó)
  let cierreId: number;
  if (result.insertId > 0) {
    // Es un nuevo registro
    cierreId = result.insertId;
  } else {
    // Es una actualización, obtener el ID del cierre existente por fecha
    const [existingRows] = await pool.query<RowDataPacket[]>(
      `SELECT id FROM caja_cierre WHERE fecha = :fecha`,
      { fecha: fechaStr }
    );
    if (existingRows.length > 0) {
      cierreId = existingRows[0].id;
    } else {
      throw new Error('No se pudo obtener el ID del cierre');
    }
  }

  // Obtener el cierre creado/actualizado
  const [rows] = await pool.query<RowDataPacket[]>(
    `
    SELECT 
      id,
      fecha,
      efectivo_inicial AS efectivoInicial,
      efectivo_final AS efectivoFinal,
      total_pagos AS totalPagos,
      total_efectivo AS totalEfectivo,
      total_tarjeta AS totalTarjeta,
      creado_por_usuario_id AS creadoPorUsuarioId,
      creado_en AS creadoEn,
      notas
    FROM caja_cierre
    WHERE id = :id
    `,
    { id: cierreId }
  );

  const row = rows[0];
  // Convertir fechas UTC de BD a objetos Date (el consumidor decidirá cómo mostrarlas)
  const fechaMx = utcToMx(row.fecha);
  const creadoEnMx = utcToMx(row.creadoEn);
  return {
    id: row.id,
    fecha: fechaMx?.toJSDate() ?? new Date(row.fecha),
    efectivoInicial: Number(row.efectivoInicial),
    efectivoFinal: Number(row.efectivoFinal),
    totalPagos: row.totalPagos ? Number(row.totalPagos) : null,
    totalEfectivo: row.totalEfectivo ? Number(row.totalEfectivo) : null,
    totalTarjeta: row.totalTarjeta ? Number(row.totalTarjeta) : null,
    creadoPorUsuarioId: row.creadoPorUsuarioId,
    creadoEn: creadoEnMx?.toJSDate() ?? new Date(row.creadoEn),
    notas: row.notas
  };
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
        revisado_en = NOW(),
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
      cc.id AS cierre_id,
      cc.efectivo_inicial AS efectivo_inicial,
      cc.efectivo_final AS efectivo_final,
      cc.notas AS notas,
      cc.creado_en AS creado_en,
      cc.estado AS estado,
      cc.comentario_revision AS comentario_revision
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
  // Convertir fecha UTC a zona CDMX para mostrar
  const fecha = getDateOnlyMx(row.fecha) ?? (row.fecha instanceof Date
    ? row.fecha.toISOString().split('T')[0]
    : new Date(row.fecha).toISOString().split('T')[0]);

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
    totalOtros: 0,
    totalPropinas: 0,
    status: row.estado || 'pending',
    cierreId: cierreId,
    creadoEn: utcToMxISO(row.creado_en) ?? undefined,
    notas: row.notas ?? null,
    comentarioRevision: row.comentario_revision ?? null
  };
};

