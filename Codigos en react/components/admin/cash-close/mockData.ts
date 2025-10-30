import type { ClosureRecord } from './ClosureTable';

// Tipo para audit log
export interface AuditLogEntry {
  id: string;
  timestamp: string;
  action: 'enviado' | 'verificado' | 'aclaración_solicitada' | 'aclaración_enviada';
  usuario: string;
  mensaje: string;
  motivo?: string;
}

// Extender el tipo ClosureRecord para incluir campos del cajero y audit log
export interface CashierClosureRecord extends ClosureRecord {
  efectivoContado: number;
  totalTarjeta: number;
  otrosIngresos: number;
  otrosIngresosTexto?: string;
  notaCajero?: string;
  totalDeclarado: number;
  auditLog: AuditLogEntry[];
}

// Mock data para cierres de caja enviados por cajeros
export const mockCashierClosures: CashierClosureRecord[] = [
  {
    id: 'close_2025-09-22_ana',
    fecha: '2025-09-22 22:30',
    periodo: 'Día',
    usuario: 'Ana Rodríguez',
    totalNeto: 3623.05,
    efectivo: 3180.00,
    tarjeta: 850.00,
    propinasTarjeta: 120.00,
    propinasEfectivo: 145.00,
    pedidosParaLlevar: 1100.00,
    estado: 'Pendiente verificación',
    efectivoContado: 3210.00,
    totalTarjeta: 850.00,
    otrosIngresos: 30.00,
    otrosIngresosTexto: 'Sobrante en monedas del día anterior',
    notaCajero: 'Conteo realizado a las 22:30. Todo correcto, solo sobraron $30 en monedas.',
    totalDeclarado: 4090.00,
    auditLog: [
      {
        id: 'log_001',
        timestamp: '2025-09-22 22:35',
        action: 'enviado',
        usuario: 'Ana Rodríguez',
        mensaje: 'Cierre enviado por Ana Rodríguez'
      }
    ]
  },
  {
    id: 'close_2025-09-21_carlos',
    fecha: '2025-09-21 22:15',
    periodo: 'Día',
    usuario: 'Carlos Méndez',
    totalNeto: 4156.80,
    efectivo: 3650.00,
    tarjeta: 950.00,
    propinasTarjeta: 85.00,
    propinasEfectivo: 156.80,
    pedidosParaLlevar: 1200.00,
    estado: 'Verificado',
    efectivoContado: 3650.00,
    totalTarjeta: 950.00,
    otrosIngresos: 0.00,
    otrosIngresosTexto: '',
    notaCajero: 'Conteo normal, todo cuadra perfectamente.',
    totalDeclarado: 4600.00,
    auditLog: [
      {
        id: 'log_002',
        timestamp: '2025-09-21 22:20',
        action: 'enviado',
        usuario: 'Carlos Méndez',
        mensaje: 'Cierre enviado por Carlos Méndez'
      },
      {
        id: 'log_003',
        timestamp: '2025-09-22 08:15',
        action: 'verificado',
        usuario: 'Admin',
        mensaje: 'Verificado por Admin — 2025-09-22 08:15:30'
      }
    ]
  },
  {
    id: 'close_2025-09-20_maria',
    fecha: '2025-09-20 22:45',
    periodo: 'Día',
    usuario: 'María Torres',
    totalNeto: 3890.45,
    efectivo: 3420.00,
    tarjeta: 780.00,
    propinasTarjeta: 95.00,
    propinasEfectivo: 170.45,
    pedidosParaLlevar: 980.00,
    estado: 'Aclaración requerida',
    efectivoContado: 3450.00,
    totalTarjeta: 780.00,
    otrosIngresos: 25.00,
    otrosIngresosTexto: 'Propina extra de cliente especial',
    notaCajero: 'Hubo una diferencia de $30 en efectivo que no pude identificar.',
    totalDeclarado: 4255.00,
    auditLog: [
      {
        id: 'log_004',
        timestamp: '2025-09-20 22:50',
        action: 'enviado',
        usuario: 'María Torres',
        mensaje: 'Cierre enviado por María Torres'
      },
      {
        id: 'log_005',
        timestamp: '2025-09-21 09:30',
        action: 'aclaración_solicitada',
        usuario: 'Admin',
        mensaje: 'Aclaración solicitada por Admin',
        motivo: 'Hay una diferencia de $30 en el efectivo contado vs el total del sistema. Favor de revisar y aclarar.'
      }
    ]
  },
  {
    id: 'close_2025-09-17_roberto',
    fecha: '2025-09-17 22:20',
    periodo: 'Día',
    usuario: 'Roberto Silva',
    totalNeto: 2985.75,
    efectivo: 2650.00,
    tarjeta: 580.00,
    propinasTarjeta: 65.00,
    propinasEfectivo: 115.75,
    pedidosParaLlevar: 720.00,
    estado: 'Pendiente verificación',
    efectivoContado: 2650.00,
    totalTarjeta: 580.00,
    otrosIngresos: 15.00,
    otrosIngresosTexto: 'Cambio que sobró de cliente',
    notaCajero: 'Día normal, sin incidencias.',
    totalDeclarado: 3245.00,
    auditLog: [
      {
        id: 'log_006',
        timestamp: '2025-09-17 22:25',
        action: 'enviado',
        usuario: 'Roberto Silva',
        mensaje: 'Cierre enviado por Roberto Silva'
      }
    ]
  }
];

// Mock data para cierres de caja (mantener compatibilidad)
export const mockClosureRecords: ClosureRecord[] = [
  {
    id: 'close_2025-09-21',
    fecha: '2025-09-21',
    periodo: 'Día',
    usuario: 'Carlos Méndez',
    totalNeto: 4156.80,
    efectivo: 3650.00,
    tarjeta: 950.00,
    propinasTarjeta: 85.00,
    propinasEfectivo: 156.80,
    pedidosParaLlevar: 1200.00,
    estado: 'Verificado'
  },
  {
    id: 'close_2025-09-20',
    fecha: '2025-09-20',
    periodo: 'Día',
    usuario: 'María Torres',
    totalNeto: 3890.45,
    efectivo: 3420.00,
    tarjeta: 780.00,
    propinasTarjeta: 95.00,
    propinasEfectivo: 170.45,
    pedidosParaLlevar: 980.00,
    estado: 'Verificado'
  },
  {
    id: 'close_week_38_2025',
    fecha: '2025-09-15 → 2025-09-21',
    periodo: 'Semana',
    usuario: 'Admin Sistema',
    totalNeto: 25847.30,
    efectivo: 22150.00,
    tarjeta: 5680.00,
    propinasTarjeta: 645.00,
    propinasEfectivo: 1015.30,
    pedidosParaLlevar: 7200.00,
    estado: 'Verificado'
  },
  {
    id: 'close_2025-09-19',
    fecha: '2025-09-19',
    periodo: 'Día',
    usuario: 'Luis García',
    totalNeto: 3245.60,
    efectivo: 2890.00,
    tarjeta: 690.00,
    propinasTarjeta: 75.00,
    propinasEfectivo: 135.60,
    pedidosParaLlevar: 850.00,
    estado: 'Verificado'
  },
  {
    id: 'close_2025-09-18',
    fecha: '2025-09-18',
    periodo: 'Día',
    usuario: 'Carmen López',
    totalNeto: 4567.20,
    efectivo: 4020.00,
    tarjeta: 1150.00,
    propinasTarjeta: 156.00,
    propinasEfectivo: 187.20,
    pedidosParaLlevar: 1350.00,
    estado: 'Verificado'
  },
  {
    id: 'close_2025-09-17',
    fecha: '2025-09-17',
    periodo: 'Día',
    usuario: 'Roberto Silva',
    totalNeto: 2985.75,
    efectivo: 2650.00,
    tarjeta: 580.00,
    propinasTarjeta: 65.00,
    propinasEfectivo: 115.75,
    pedidosParaLlevar: 720.00,
    estado: 'Pendiente verificación'
  },
  {
    id: 'close_2025-09-16',
    fecha: '2025-09-16',
    periodo: 'Día',
    usuario: 'Patricia Ruiz',
    totalNeto: 3834.90,
    efectivo: 3380.00,
    tarjeta: 820.00,
    propinasTarjeta: 98.00,
    propinasEfectivo: 154.90,
    pedidosParaLlevar: 1020.00,
    estado: 'Verificado'
  },
  {
    id: 'close_month_09_2025',
    fecha: 'Septiembre 2025',
    periodo: 'Mes',
    usuario: 'Admin Sistema',
    totalNeto: 89567.45,
    efectivo: 78950.00,
    tarjeta: 19850.00,
    propinasTarjeta: 2145.00,
    propinasEfectivo: 3567.45,
    pedidosParaLlevar: 28450.00,
    estado: 'Verificado'
  },
  {
    id: 'close_2025-09-15',
    fecha: '2025-09-15',
    periodo: 'Día',
    usuario: 'Diego Morales',
    totalNeto: 3456.30,
    efectivo: 3050.00,
    tarjeta: 750.00,
    propinasTarjeta: 89.00,
    propinasEfectivo: 156.30,
    pedidosParaLlevar: 950.00,
    estado: 'Verificado'
  }
];

// Función para obtener cierres de cajeros según filtros
export const getCashierClosuresByPreset = (preset: string, statusFilter: string = 'all') => {
  let filtered = [...mockCashierClosures];

  // Filtrar por estado
  if (statusFilter !== 'all') {
    filtered = filtered.filter(closure => closure.estado === statusFilter);
  }

  // Filtrar por preset de fecha
  switch (preset) {
    case 'today':
      filtered = filtered.filter(closure => 
        closure.fecha.startsWith('2025-09-22')
      );
      break;
    case 'yesterday':
      filtered = filtered.filter(closure => 
        closure.fecha.startsWith('2025-09-21')
      );
      break;
    case 'last-week':
      filtered = filtered.filter(closure => 
        closure.fecha.startsWith('2025-09-15') ||
        closure.fecha.startsWith('2025-09-16') ||
        closure.fecha.startsWith('2025-09-17') ||
        closure.fecha.startsWith('2025-09-18') ||
        closure.fecha.startsWith('2025-09-19') ||
        closure.fecha.startsWith('2025-09-20') ||
        closure.fecha.startsWith('2025-09-21')
      );
      break;
    case 'current-month':
      filtered = filtered.filter(closure => 
        closure.fecha.startsWith('2025-09')
      );
      break;
    default:
      // Para 'custom' o 'all', devolver todo
      break;
  }

  return filtered;
};

// Función para filtrar datos según el preset seleccionado (mantener compatibilidad)
export const getClosuresByPreset = (preset: string, showVerifiedOnly: boolean = false) => {
  let filtered = [...mockClosureRecords];

  // Filtrar por estado si se solicita
  if (showVerifiedOnly) {
    filtered = filtered.filter(closure => closure.estado === 'Verificado');
  }

  // Filtrar por preset de fecha
  const today = new Date('2025-09-22'); // Fecha mock actual
  
  switch (preset) {
    case 'today':
      filtered = filtered.filter(closure => 
        closure.fecha === '2025-09-22' && closure.periodo === 'Día'
      );
      break;
    case 'yesterday':
      filtered = filtered.filter(closure => 
        closure.fecha === '2025-09-21' && closure.periodo === 'Día'
      );
      break;
    case 'last-week':
      filtered = filtered.filter(closure => 
        closure.periodo === 'Semana' || (
          closure.periodo === 'Día' && 
          ['2025-09-15', '2025-09-16', '2025-09-17', '2025-09-18', '2025-09-19', '2025-09-20', '2025-09-21'].includes(closure.fecha)
        )
      );
      break;
    case 'current-month':
      filtered = filtered.filter(closure => 
        closure.periodo === 'Mes' || closure.fecha.startsWith('2025-09')
      );
      break;
    default:
      // Para 'custom' o 'all', devolver todo
      break;
  }

  return filtered;
};

// Función para calcular totales del resumen de cierres de cajeros
export const calculateCashierSummaryTotals = (closures: CashierClosureRecord[]) => {
  return closures.reduce((totals, closure) => ({
    totalDeclarado: totals.totalDeclarado + closure.totalDeclarado,
    efectivoContado: totals.efectivoContado + closure.efectivoContado,
    totalTarjeta: totals.totalTarjeta + closure.totalTarjeta,
    otrosIngresos: totals.otrosIngresos + closure.otrosIngresos,
    cantidadCierres: totals.cantidadCierres + 1,
    pendientes: totals.pendientes + (closure.estado === 'Pendiente verificación' ? 1 : 0),
    verificados: totals.verificados + (closure.estado === 'Verificado' ? 1 : 0),
    aclaraciones: totals.aclaraciones + (closure.estado === 'Aclaración requerida' ? 1 : 0)
  }), {
    totalDeclarado: 0,
    efectivoContado: 0,
    totalTarjeta: 0,
    otrosIngresos: 0,
    cantidadCierres: 0,
    pendientes: 0,
    verificados: 0,
    aclaraciones: 0
  });
};

// Función para calcular totales del resumen (mantener compatibilidad)
export const calculateSummaryTotals = (closures: ClosureRecord[]) => {
  return closures.reduce((totals, closure) => ({
    totalNeto: totals.totalNeto + closure.totalNeto,
    efectivo: totals.efectivo + closure.efectivo,
    tarjeta: totals.tarjeta + closure.tarjeta,
    propinasTarjeta: totals.propinasTarjeta + closure.propinasTarjeta,
    propinasEfectivo: totals.propinasEfectivo + closure.propinasEfectivo,
    pedidosParaLlevar: totals.pedidosParaLlevar + closure.pedidosParaLlevar
  }), {
    totalNeto: 0,
    efectivo: 0,
    tarjeta: 0,
    propinasTarjeta: 0,
    propinasEfectivo: 0,
    pedidosParaLlevar: 0
  });
};