import type { RowDataPacket } from 'mysql2';
import { pool } from '../../db/pool.js';

export type TipoDocumentoPlantilla =
  | 'ticket_cobro'   // plantilla general (respaldo cuando no hay específica)
  | 'ticket_mesa'    // comer en mesa
  | 'ticket_para_llevar'
  | 'ticket_dividida' // cuenta dividida / agrupada
  | 'comanda';

interface PlantillaImpresionRow extends RowDataPacket {
  id: number;
  tipo_documento: string;
  contenido: string;
  plantilla_linea_item: string | null;
  creado_en: Date;
  actualizado_en: Date;
}

export interface PlantillaImpresion {
  tipoDocumento: TipoDocumentoPlantilla;
  contenido: string;
  plantillaLineaItem: string | null;
  actualizadoEn: Date;
}

function rowToPlantilla(row: PlantillaImpresionRow): PlantillaImpresion {
  return {
    tipoDocumento: row.tipo_documento as TipoDocumentoPlantilla,
    contenido: row.contenido ?? '',
    plantillaLineaItem: row.plantilla_linea_item ?? null,
    actualizadoEn: row.actualizado_en,
  };
}

export async function obtenerPlantilla(tipo: TipoDocumentoPlantilla): Promise<PlantillaImpresion | null> {
  const [rows] = await pool.query<PlantillaImpresionRow[]>(
    'SELECT id, tipo_documento, contenido, plantilla_linea_item, creado_en, actualizado_en FROM plantilla_impresion WHERE tipo_documento = ?',
    [tipo]
  );
  const row = rows[0];
  return row ? rowToPlantilla(row) : null;
}

export async function guardarPlantilla(
  tipo: TipoDocumentoPlantilla,
  contenido: string,
  plantillaLineaItem: string | null
): Promise<void> {
  await pool.query(
    `INSERT INTO plantilla_impresion (tipo_documento, contenido, plantilla_linea_item)
     VALUES (?, ?, ?)
     ON DUPLICATE KEY UPDATE contenido = VALUES(contenido), plantilla_linea_item = VALUES(plantilla_linea_item)`,
    [tipo, contenido, plantillaLineaItem]
  );
}
