# Impresoras térmicas – Configuración flexible

El sistema soporta **una o varias impresoras térmicas** (58mm o 80mm, USB o red), con asignación por tipo de documento: **comanda** (cocina) y **ticket** (cobro/cliente).

---

## Casos de uso

| Escenario | Configuración |
|-----------|----------------|
| **1 impresora para todo** | Una sola impresora imprime comandas y tickets. |
| **1 para cocina, 1 para caja** | Impresora A solo `comanda`, impresora B solo `ticket`. |
| **Varias impresoras para lo mismo** | Varias impresoras con el mismo `documents` (ej. dos para cocina). |
| **Simulación / pruebas** | `type: "simulation"` guarda en archivos `.txt`. |

---

## Configuración rápida (.env) – Una sola impresora

Si no creas `config/printers.json`, se usa una única impresora desde el `.env`:

```env
# Tipo: simulation (archivos) o pos80 (impresora real)
PRINTER_TYPE=pos80
# Interfaz: usb | tcp | file
PRINTER_INTERFACE=usb
# Nombre de la impresora en Windows (como aparece en "Impresoras y escáneres")
PRINTER_DEVICE=Thermal Receipt Printer
# Ancho de papel: 58 (ZKP5803, 58mm) o 80 (80mm). Por defecto 80
PRINTER_PAPER_WIDTH=58
# Para simulación: carpeta donde guardar tickets
PRINTER_SIMULATION_PATH=./tickets
```

### Ejemplo para tu impresora ZKP5803 (58mm, USB)

- **Modelo:** ZKP5803  
- **Papel:** 58mm  
- **Interfaz:** USB  
- **Cutter:** No (no afecta el driver)

En Windows, después de instalar el driver, el nombre suele ser algo como **"Thermal Receipt Printer"** o el modelo. Úsalo en `PRINTER_DEVICE`:

```env
PRINTER_TYPE=pos80
PRINTER_INTERFACE=usb
PRINTER_DEVICE=Thermal Receipt Printer
PRINTER_PAPER_WIDTH=58
```

---

## Configuración avanzada – Varias impresoras (JSON)

Copia el ejemplo y edita `config/printers.json` en la raíz del backend:

```bash
cp config/printers.json.example config/printers.json
```

Estructura:

```json
{
  "printers": [
    {
      "id": "cocina",
      "name": "Cocina - comandas",
      "type": "usb",
      "documents": ["comanda"],
      "paperWidth": 58,
      "device": "Thermal Receipt Printer"
    },
    {
      "id": "caja",
      "name": "Caja - tickets",
      "type": "usb",
      "documents": ["ticket"],
      "paperWidth": 58,
      "device": "ZKP5803"
    }
  ]
}
```

### Campos por impresora

| Campo | Obligatorio | Descripción |
|-------|-------------|-------------|
| **id** | Sí | Identificador único (para logs). |
| **name** | No | Nombre legible. |
| **type** | Sí | `simulation` \| `usb` \| `tcp` \| `file` |
| **documents** | Sí | Array: `["comanda"]`, `["ticket"]` o `["comanda","ticket"]` |
| **paperWidth** | No | `58` o `80`. Por defecto 80. |
| **device** | Según type | USB: nombre o puerto. Simulation: carpeta. File: ruta del archivo. |
| **host** | Para tcp | IP de la impresora de red. |
| **port** | Para tcp | Puerto (ej. 9100). |

### Una sola impresora para todo (JSON)

```json
{
  "printers": [
    {
      "id": "principal",
      "name": "Única impresora",
      "type": "usb",
      "documents": ["comanda", "ticket"],
      "paperWidth": 58,
      "device": "Thermal Receipt Printer"
    }
  ]
}
```

---

## Compatibilidad

- **Protocolo:** ESC/POS (estándar en impresoras térmicas).  
- **Papel:** 58mm (~32 caracteres) u 80mm (~48 caracteres).  
- **Interfaces:** USB (nombre o puerto en Windows), TCP/IP, archivo, simulación.  

Funciona con impresoras como ZKP5803, POS-80, Epson TM-T20, etc., siempre que usen ESC/POS.

---

## Ruta del archivo de configuración

Por defecto se usa `config/printers.json` (respecto al directorio de trabajo del backend). Para otra ruta:

```env
PRINTERS_CONFIG_PATH=C:\mi_ruta\printers.json
```

---

## Pruebas sin impresora

```env
PRINTER_TYPE=simulation
PRINTER_INTERFACE=file
PRINTER_SIMULATION_PATH=./tickets
```

O en `printers.json` una impresora con `"type": "simulation"` y `"documents": ["comanda", "ticket"]`. Los tickets y comandas se guardan como `.txt` en la carpeta indicada.
