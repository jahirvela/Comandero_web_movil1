import type { Request, Response } from 'express';
import {
  obtenerConfiguracion,
  actualizarIvaHabilitado,
  actualizarConfiguracionCajon,
} from './configuracion.repository.js';
import { actualizarConfiguracionSchema } from './configuracion.schemas.js';
import {
  obtenerPlantilla,
  guardarPlantilla,
  type TipoDocumentoPlantilla,
} from './plantilla-impresion.repository.js';

export const getConfiguracionController = async (_req: Request, res: Response) => {
  const config = await obtenerConfiguracion();
  res.json(config);
};

export const patchConfiguracionController = async (req: Request, res: Response) => {
  const parsed = actualizarConfiguracionSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Datos inválidos', details: parsed.error.flatten() });
  }
  const { ivaHabilitado, cajon } = parsed.data;
  if (ivaHabilitado !== undefined) {
    await actualizarIvaHabilitado(ivaHabilitado);
  }
  if (cajon !== undefined && Object.keys(cajon).length > 0) {
    await actualizarConfiguracionCajon(cajon);
  }
  const config = await obtenerConfiguracion();
  res.json(config);
};

const TIPOS_PLANTILLA: TipoDocumentoPlantilla[] = [
  'ticket_cobro',
  'ticket_mesa',
  'ticket_para_llevar',
  'ticket_dividida',
  'comanda',
];

/** Plantilla por defecto para tickets de cobro. {{SEPARADOR}} y {{GUION}} se reemplazan por el ancho de papel. */
const DEFAULT_PLANTILLA_TICKET = `[CENTRAR][NEGRITA]{{NOMBRE_RESTAURANTE}}[/NEGRITA][/CENTRAR]
{{DIRECCION}}
Tel: {{TELEFONO}}
RFC: {{RFC}}

{{SEPARADOR}}
[CENTRAR][NEGRITA]{{TITULO}}[/NEGRITA][/CENTRAR]
{{SEPARADOR}}

Folio: {{FOLIO}}
Fecha: {{FECHA}}
Mesa: {{MESA}}
Cuenta de: {{CLIENTE}}
Impreso por: {{IMPRESO_POR}}
Método de pago: {{METODO_PAGO}}
{{GUION}}
[NEGRITA]CANT DESCRIPCION TOTAL MXN[/NEGRITA]
{{GUION}}
{{ITEMS}}
{{GUION}}
Subtotal:       {{MONEDA}}{{SUBTOTAL}}
Descuento:      {{MONEDA}}{{DESCUENTO}}
{{IVA_LINE}}
[NEGRITA]TOTAL:          {{MONEDA}}{{TOTAL}}[/NEGRITA]
{{SEPARADOR}}
[CENTRAR]{{GRACIAS}}[/CENTRAR]
[CENTRAR]{{VUELVA}}[/CENTRAR]`;

/** Plantilla por defecto para comanda (cocina). Mismos placeholders que ticket donde aplique. */
const DEFAULT_PLANTILLA_COMANDA = `{{SEPARADOR}}
[CENTRAR][NEGRITA]COMANDA[/NEGRITA][/CENTRAR]
{{SEPARADOR}}

Folio: {{FOLIO}}
Fecha: {{FECHA}}
Mesa: {{MESA}}
Cliente: {{CLIENTE}}
{{GUION}}
[NEGRITA]CANT  DESCRIPCION          NOTAS[/NEGRITA]
{{GUION}}
{{ITEMS}}
{{SEPARADOR}}`;

export const getPlantillaImpresionController = async (req: Request, res: Response) => {
  const tipo = req.params.tipo as TipoDocumentoPlantilla;
  if (!TIPOS_PLANTILLA.includes(tipo)) {
    return res.status(400).json({
      error: 'Tipo de plantilla inválido. Use: ticket_cobro, ticket_mesa, ticket_para_llevar, ticket_dividida, comanda',
    });
  }
  const plantilla = await obtenerPlantilla(tipo);
  if (plantilla && plantilla.contenido.trim().length > 0) {
    return res.json(plantilla);
  }
  if (tipo === 'comanda') {
    return res.json({
      tipoDocumento: tipo,
      contenido: DEFAULT_PLANTILLA_COMANDA,
      plantillaLineaItem: null,
      actualizadoEn: null,
    });
  }
  return res.json({
    tipoDocumento: tipo,
    contenido: DEFAULT_PLANTILLA_TICKET,
    plantillaLineaItem: null,
    actualizadoEn: null,
  });
};

export const putPlantillaImpresionController = async (req: Request, res: Response) => {
  const tipo = req.params.tipo as TipoDocumentoPlantilla;
  if (!TIPOS_PLANTILLA.includes(tipo)) {
    return res.status(400).json({
      error: 'Tipo de plantilla inválido. Use: ticket_cobro, ticket_mesa, ticket_para_llevar, ticket_dividida, comanda',
    });
  }
  const contenido = typeof req.body?.contenido === 'string' ? req.body.contenido : '';
  const plantillaLineaItem =
    req.body?.plantillaLineaItem !== undefined && req.body?.plantillaLineaItem !== null
      ? String(req.body.plantillaLineaItem)
      : null;
  await guardarPlantilla(tipo, contenido, plantillaLineaItem);
  const plantilla = await obtenerPlantilla(tipo);
  res.json(plantilla!);
};
