# Agente de impresión USB (impresión remota)

Cuando el backend está en un **servidor remoto** y la impresora térmica está **conectada por USB a un PC local**, el servidor no puede imprimir directamente. La solución es usar **impresión remota**: el servidor encola los trabajos y un **agente** ejecutado en el PC con la impresora consulta la cola e imprime por USB.

## Requisitos

- **Backend:** migración aplicada (tabla `cola_impresion`, columna `impresora.impresion_remota`).
- **Impresora:** en Admin → Impresoras, crear/editar la impresora y marcar **Impresión remota: Sí**.
- **PC local:** Windows, Node.js (v18+), impresora instalada y visible en "Impresoras y escáneres".

## Pasos

### 1. En el servidor / Admin

- Aplicar la migración `docs/migraciones/20250213_impresion_remota_cola.sql` si no está aplicada.
- En la app Admin, crear o editar la impresora USB y activar **Impresión remota** (y Comanda/Ticket según corresponda).

### 2. En el PC donde está la impresora USB

1. **Copiar al PC** (o clonar el repo) al menos:
   - `backend/scripts/agente-impresion-usb.ts`
   - `backend/scripts/print-raw-windows.ps1`
2. **Instalar Node.js** (v18 o superior).
3. **Obtener un token JWT** de un usuario (por ejemplo admin): iniciar sesión en la app y usar el token que guarda la app, o generar uno desde el backend (login API).
4. **Configurar variables de entorno** y ejecutar el agente.

### 3. Variables de entorno

| Variable        | Descripción |
|----------------|-------------|
| `API_BASE_URL` | URL base del API, p. ej. `https://api.comancleth.com/api` (sin barra final). |
| `AUTH_TOKEN`   | JWT (Bearer) de un usuario con acceso al API. |
| `IMPRESORA_ID` | ID de la impresora en el backend (el mismo que en Admin). |
| `PRINTER_DEVICE` | Nombre **exacto** de la impresora en Windows (como en "Impresoras y escáneres"), p. ej. `ZKTECO` o `Thermal Receipt Printer`. |
| `SCRIPT_PS`    | (Opcional) Ruta completa a `print-raw-windows.ps1`. Por defecto: `./scripts/print-raw-windows.ps1` respecto al directorio de trabajo. |

### 4. Ejecutar el agente

Desde la carpeta del backend (o la carpeta donde copiaste los scripts), en PowerShell:

```powershell
$env:API_BASE_URL = "https://api.comancleth.com/api"
$env:AUTH_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
$env:IMPRESORA_ID = "1"
$env:PRINTER_DEVICE = "ZKTECO"
npx tsx scripts/agente-impresion-usb.ts
```

O en CMD:

```cmd
set API_BASE_URL=https://api.comancleth.com/api
set AUTH_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
set IMPRESORA_ID=1
set PRINTER_DEVICE=ZKTECO
npx tsx scripts/agente-impresion-usb.ts
```

El agente consulta la cola cada ~2,5 s. Por cada trabajo pendiente escribe el contenido en un archivo temporal (CP850), lo envía a la impresora con `print-raw-windows.ps1` y marca el trabajo como impreso o error en el servidor.

### 5. Dejar el agente corriendo

- Puedes ejecutarlo en una ventana de consola y dejarla abierta.
- Para producción, se puede instalar como servicio de Windows (p. ej. con `node-windows` o NSSM) o programar una tarea que se ejecute al iniciar sesión.

## Resolución de problemas

- **"No se encuentra el script PowerShell"**: Ajusta `SCRIPT_PS` a la ruta absoluta de `print-raw-windows.ps1`.
- **"API 401"**: El token ha caducado o es inválido. Genera uno nuevo (login).
- **"API 404"**: Comprueba que `API_BASE_URL` incluya `/api` (ej. `https://dominio.com/api`).
- **No imprime pero no da error**: Verifica que `PRINTER_DEVICE` coincida exactamente con el nombre en Windows (mayúsculas/minúsculas, espacios).
- **Caracteres raros (acentos, ñ)**: El agente ya convierte a CP850; si persiste, revisa que el contenido que envía el backend sea UTF-8 correcto.
