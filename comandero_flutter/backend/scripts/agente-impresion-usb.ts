/**
 * Agente de impresión USB para PC local.
 * Consulta la cola del servidor y envía los trabajos a la impresora USB.
 * Ejecutar en el PC donde está conectada la impresora (Windows).
 *
 * Variables de entorno:
 *   API_BASE_URL   - ej. https://api.comancleth.com/api
 *   AGENT_API_KEY  - Clave generada en Admin > Configuración > Impresoras > "Generar clave para agente" (recomendado; no caduca)
 *   AUTH_TOKEN     - Alternativa: JWT (Bearer) de un usuario (caduca; usar solo si no tiene AGENT_API_KEY)
 *   IMPRESORA_ID   - ID de la impresora en el backend (ej. 1)
 *   PRINTER_DEVICE - Nombre exacto de la impresora en Windows (ej. ZKTECO)
 *   SCRIPT_PS      - (opcional) Ruta a print-raw-windows.ps1
 *
 * Debe definir AGENT_API_KEY o AUTH_TOKEN (no ambos es necesario; AGENT_API_KEY tiene prioridad).
 */

import { execFile } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import path from 'path';
import os from 'os';

const execFileAsync = promisify(execFile);

const API_BASE = process.env.API_BASE_URL?.replace(/\/$/, '') || '';
const AGENT_API_KEY = process.env.AGENT_API_KEY?.trim() || '';
const AUTH_TOKEN = process.env.AUTH_TOKEN?.trim() || '';
const IMPRESORA_ID = process.env.IMPRESORA_ID || '';
const PRINTER_DEVICE = process.env.PRINTER_DEVICE || '';
const SCRIPT_PS = process.env.SCRIPT_PS || path.join(process.cwd(), 'scripts', 'print-raw-windows.ps1');

/** Cabeceras para las peticiones: clave de agente (recomendada) o JWT. */
function authHeaders(): Record<string, string> {
  if (AGENT_API_KEY) {
    return { 'X-Agent-Api-Key': AGENT_API_KEY };
  }
  if (AUTH_TOKEN) {
    return { Authorization: `Bearer ${AUTH_TOKEN}` };
  }
  return {};
}

const INTERVAL_MS = 2500;

/** Convierte string UTF-8 a buffer CP850 para impresoras térmicas (acentos, ñ). */
function stringToCp850(s: string): Buffer {
  const map: Record<number, number> = {
    0xa1: 0xad, 0xbf: 0xa8, 0xc1: 0xb5, 0xc9: 0x90, 0xcd: 0xd6, 0xd1: 0xa5, 0xd3: 0xe0, 0xda: 0xe9, 0xdc: 0x9a,
    0xe1: 0xa0, 0xe9: 0x82, 0xed: 0xa1, 0xf1: 0xa4, 0xf3: 0xa2, 0xfa: 0xa3, 0xfc: 0x81,
  };
  const out = Buffer.allocUnsafe(s.length);
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    if (c <= 0x7f) out[i] = c;
    else if (c in map) out[i] = map[c] as number;
    else if (c <= 0xff) out[i] = c;
    else out[i] = 0x3f;
  }
  return out;
}

async function fetchPendientes(): Promise<{ id: number; contenido: string }[]> {
  const url = `${API_BASE}/impresoras/cola/pendientes?impresora_id=${IMPRESORA_ID}`;
  const res = await fetch(url, {
    headers: { ...authHeaders(), 'Content-Type': 'application/json' },
  });
  if (!res.ok) throw new Error(`API ${res.status}: ${await res.text()}`);
  const json = (await res.json()) as { data?: { id: number; contenido: string }[] };
  return json.data || [];
}

async function marcarImpreso(jobId: number): Promise<void> {
  const url = `${API_BASE}/impresoras/cola/job/${jobId}/impreso`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { ...authHeaders(), 'Content-Type': 'application/json' },
  });
  if (!res.ok) throw new Error(`API ${res.status}: ${await res.text()}`);
}

async function marcarError(jobId: number, mensaje: string): Promise<void> {
  const url = `${API_BASE}/impresoras/cola/job/${jobId}/error`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { ...authHeaders(), 'Content-Type': 'application/json' },
    body: JSON.stringify({ mensaje }),
  });
  if (!res.ok) throw new Error(`API ${res.status}: ${await res.text()}`);
}

async function imprimirEnWindows(contenido: string): Promise<void> {
  const tempFile = path.join(os.tmpdir(), `cola-${Date.now()}.bin`);
  const buffer = stringToCp850(contenido);
  await fs.writeFile(tempFile, buffer);
  try {
    await execFileAsync(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', SCRIPT_PS, '-PrinterName', PRINTER_DEVICE, '-FilePath', tempFile],
      { timeout: 15000, windowsHide: true }
    );
  } finally {
    await fs.unlink(tempFile).catch(() => {});
  }
}

async function run(): Promise<void> {
  if (process.platform !== 'win32') {
    console.error('Este agente está pensado para Windows (impresora USB). En Linux/Mac se puede adaptar.');
    process.exit(1);
  }
  if (!API_BASE || (!AGENT_API_KEY && !AUTH_TOKEN) || !IMPRESORA_ID || !PRINTER_DEVICE) {
    console.error('Faltan variables: API_BASE_URL, (AGENT_API_KEY o AUTH_TOKEN), IMPRESORA_ID, PRINTER_DEVICE');
    process.exit(1);
  }
  try {
    await fs.access(SCRIPT_PS);
  } catch {
    console.error('No se encuentra el script PowerShell:', SCRIPT_PS);
    process.exit(1);
  }

  console.log(`Agente USB: impresora_id=${IMPRESORA_ID}, device="${PRINTER_DEVICE}". Consultando cada ${INTERVAL_MS}ms.`);

  const loop = async (): Promise<void> => {
    try {
      const jobs = await fetchPendientes();
      for (const job of jobs) {
        try {
          await imprimirEnWindows(job.contenido);
          await marcarImpreso(job.id);
          console.log(`[${new Date().toISOString()}] Impreso job ${job.id}`);
        } catch (err: unknown) {
          const msg = err instanceof Error ? err.message : String(err);
          await marcarError(job.id, msg).catch(() => {});
          console.error(`[${new Date().toISOString()}] Error job ${job.id}:`, msg);
        }
      }
    } catch (err: unknown) {
      console.error('Error al consultar cola:', err);
    }
    setTimeout(loop, INTERVAL_MS);
  };

  loop();
}

run();
