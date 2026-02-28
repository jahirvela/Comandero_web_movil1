import type { RowDataPacket } from 'mysql2';
import { pool } from '../../db/pool.js';

export type CajonTipoConexion = 'via_impresora' | 'red' | 'usb';

interface ConfiguracionRow extends RowDataPacket {
  id: number;
  iva_habilitado: number;
  actualizado_en: Date;
  cajon_habilitado?: number;
  cajon_impresora_id?: number | null;
  cajon_abrir_efectivo?: number;
  cajon_abrir_tarjeta?: number;
  cajon_tipo_conexion?: string | null;
  cajon_marca?: string | null;
  cajon_modelo?: string | null;
  cajon_host?: string | null;
  cajon_puerto?: number | null;
  cajon_device?: string | null;
}

export interface ConfiguracionCajon {
  habilitado: boolean;
  impresoraId: number | null;
  abrirEnEfectivo: boolean;
  abrirEnTarjeta: boolean;
  tipoConexion: CajonTipoConexion;
  marca: string | null;
  modelo: string | null;
  host: string | null;
  port: number | null;
  device: string | null;
}

export interface Configuracion {
  ivaHabilitado: boolean;
  cajon: ConfiguracionCajon;
}

const ROW_ID = 1;
const CAJON_DEFAULT: ConfiguracionCajon = {
  habilitado: false,
  impresoraId: null,
  abrirEnEfectivo: true,
  abrirEnTarjeta: false,
  tipoConexion: 'via_impresora',
  marca: null,
  modelo: null,
  host: null,
  port: null,
  device: null,
};

function normalizeTipoConexion(v: string | null | undefined): CajonTipoConexion {
  if (v === 'red' || v === 'usb') return v;
  return 'via_impresora';
}

/** Columnas base que siempre existen (creadas con agregar-tabla-configuracion.sql). */
const BASE_COLUMNS = 'id, iva_habilitado, actualizado_en';

/** Columnas del cajón; solo existen si se aplicó agregar-configuracion-cajon.sql. */
const CAJON_COLUMNS =
  'cajon_habilitado, cajon_impresora_id, cajon_abrir_efectivo, cajon_abrir_tarjeta, cajon_tipo_conexion, cajon_marca, cajon_modelo, cajon_host, cajon_puerto, cajon_device';

export const obtenerConfiguracion = async (): Promise<Configuracion> => {
  const [rows] = await pool.query<ConfiguracionRow[]>(
    `SELECT ${BASE_COLUMNS} FROM configuracion WHERE id = ?`,
    [ROW_ID]
  );
  const row = rows[0];
  if (!row) {
    return { ivaHabilitado: false, cajon: CAJON_DEFAULT };
  }

  let cajon: ConfiguracionCajon = CAJON_DEFAULT;
  try {
    const [cajonRows] = await pool.query<ConfiguracionRow[]>(
      `SELECT ${CAJON_COLUMNS} FROM configuracion WHERE id = ?`,
      [ROW_ID]
    );
    const cajonRow = cajonRows[0];
    if (cajonRow && cajonRow.cajon_habilitado !== undefined) {
      cajon = {
        habilitado: Boolean(cajonRow.cajon_habilitado),
        impresoraId: cajonRow.cajon_impresora_id ?? null,
        abrirEnEfectivo: cajonRow.cajon_abrir_efectivo !== undefined ? Boolean(cajonRow.cajon_abrir_efectivo) : true,
        abrirEnTarjeta: Boolean(cajonRow.cajon_abrir_tarjeta ?? 0),
        tipoConexion: normalizeTipoConexion(cajonRow.cajon_tipo_conexion),
        marca: cajonRow.cajon_marca ?? null,
        modelo: cajonRow.cajon_modelo ?? null,
        host: cajonRow.cajon_host ?? null,
        port: cajonRow.cajon_puerto ?? null,
        device: cajonRow.cajon_device ?? null,
      };
    }
  } catch {
    // Columnas cajon_* no existen: no se aplicó la migración; usar valores por defecto.
  }

  return {
    ivaHabilitado: Boolean(row.iva_habilitado),
    cajon,
  };
};

export const actualizarIvaHabilitado = async (ivaHabilitado: boolean): Promise<void> => {
  await pool.execute(
    `INSERT INTO configuracion (id, iva_habilitado) VALUES (?, ?)
     ON DUPLICATE KEY UPDATE iva_habilitado = VALUES(iva_habilitado)`,
    [ROW_ID, ivaHabilitado ? 1 : 0]
  );
};

export const actualizarConfiguracionCajon = async (cajon: Partial<ConfiguracionCajon>): Promise<void> => {
  const cols: string[] = [];
  const vals: (string | number | null)[] = [];
  if (cajon.habilitado !== undefined) {
    cols.push('cajon_habilitado = ?');
    vals.push(cajon.habilitado ? 1 : 0);
  }
  if (cajon.impresoraId !== undefined) {
    cols.push('cajon_impresora_id = ?');
    vals.push(cajon.impresoraId);
  }
  if (cajon.abrirEnEfectivo !== undefined) {
    cols.push('cajon_abrir_efectivo = ?');
    vals.push(cajon.abrirEnEfectivo ? 1 : 0);
  }
  if (cajon.abrirEnTarjeta !== undefined) {
    cols.push('cajon_abrir_tarjeta = ?');
    vals.push(cajon.abrirEnTarjeta ? 1 : 0);
  }
  if (cajon.tipoConexion !== undefined) {
    cols.push('cajon_tipo_conexion = ?');
    vals.push(cajon.tipoConexion);
  }
  if (cajon.marca !== undefined) {
    cols.push('cajon_marca = ?');
    vals.push(cajon.marca || null);
  }
  if (cajon.modelo !== undefined) {
    cols.push('cajon_modelo = ?');
    vals.push(cajon.modelo || null);
  }
  if (cajon.host !== undefined) {
    cols.push('cajon_host = ?');
    vals.push(cajon.host || null);
  }
  if (cajon.port !== undefined) {
    cols.push('cajon_puerto = ?');
    vals.push(cajon.port);
  }
  if (cajon.device !== undefined) {
    cols.push('cajon_device = ?');
    vals.push(cajon.device || null);
  }
  if (cols.length === 0) return;
  vals.push(ROW_ID);
  await pool.execute(
    `UPDATE configuracion SET ${cols.join(', ')} WHERE id = ?`,
    vals
  );
};
