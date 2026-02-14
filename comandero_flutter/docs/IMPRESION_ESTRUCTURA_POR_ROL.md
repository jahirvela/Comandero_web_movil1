# Impresión por rol – Análisis y estructura de tickets

Este documento define **qué imprime cada rol**, **cuándo** y la **estructura exacta** de cada tipo de documento (comanda vs ticket de cobro), para que la lógica de impresión quede clara y consistente.

---

## Zona horaria (CDMX)

Todas las fechas y horas que aparecen en documentos impresos usan **hora de Ciudad de México (America/Mexico_City)**:

- **Ticket de cobro:** la línea "Fecha" muestra la **hora en que se imprime** (primera impresión o reimpresión), en CDMX.
- **Comanda:** la línea "Fecha" (encabezado y pie) muestra la **hora en que se imprime** (automática al crear la orden o reimpresión), en CDMX.
- **Reportes PDF/CSV:** las fechas de datos se formatean en CDMX; el pie "Generado el" usa la hora actual en CDMX.

Implementación en backend: `config/time.js` (`nowMx`, `formatMxLocale`, `formatMxDate`, `utcToMx`).

---

## 1. Resumen por rol

| Rol | Comanda (cocina) | Ticket de cobro (cliente) | Notas |
|-----|------------------|---------------------------|--------|
| **Administrador** | Sí (reimpresión manual) | Sí (desde lista de tickets) | Puede reimprimir comanda y ticket en cualquier momento. |
| **Mesero** | Sí (reimpresión manual) | No | Solo reimprime comanda cuando lo pide el cliente/cocina. |
| **Cocinero** | No | No | No dispara impresión; recibe comandas impresas automáticamente. |
| **Cajero** | No | Sí (al cobrar) | Imprime ticket al procesar el pago (efectivo, tarjeta, mixto). |
| **Capitán** | Sí (reimpresión manual) | Sí (igual que cajero) | Mismas acciones que mesero + cajero. |
| **Backend** | Sí (automática al crear orden) | No | Primera impresión de comanda al crear la orden. |

---

## 2. Tipos de documento

En el sistema hay **dos tipos de documento** que se imprimen:

1. **Comanda** – Orden de producción para cocina (sin precios).
2. **Ticket de cobro** – Comprobante para el cliente (con precios y totales).

Cada uno tiene una **estructura fija**; lo que cambia por rol es **quién** lo dispara y **en qué momento**, no el contenido del documento.

---

## 3. Estructura de la COMANDA

**Uso:** Que cocina sepa qué preparar (cantidades, productos, tamaños, modificadores, notas).  
**No incluye precios.**

### 3.1 Orden de bloques (de arriba a abajo)

| Orden | Bloque | Contenido | Obligatorio |
|-------|--------|-----------|-------------|
| 1 | Título | `*** COMANDA ***` (centrado, negrita, doble altura) | Sí |
| 2 | Separador | Línea `====` (ancho según papel 58/80 mm) | Sí |
| 3 | Folio | `Folio: ORD-XXXXXX` | Sí |
| 4 | Fecha/hora | Fecha y hora de la orden (zona CDMX) | Sí |
| 5 | Ubicación | `Mesa: X` o `*** PARA LLEVAR ***` + Cliente y Tel. | Sí (uno u otro) |
| 6 | Mesero | `Mesero: [nombre]` | Si existe |
| 7 | Tiempo estimado | `Tiempo estimado: X min` | Si existe |
| 8 | Separador | Línea `----` | Sí |
| 9 | Encabezado ítems | `CANT  PRODUCTO` | Sí |
| 10 | Separador | `----` | Sí |
| 11 | Ítems | Por cada ítem: `cantidad x descripción`; debajo modificadores (`+ nombre`) y `NOTA: texto` si hay | Sí |
| 12 | Separador | `----` | Sí |
| 13 | Notas generales | `NOTAS GENERALES:` + lista de notas de la orden | Si hay notas |
| 14 | Pie | Folio y fecha (centrado) | Sí |
| 15 | Corte | Comando cortar papel | Sí |

### 3.2 Quién dispara la comanda

- **Automática:** al crear la orden (backend). Una sola vez por orden.
- **Reimpresión:** Mesero, Capitán o Administrador desde la app (misma estructura, mismo contenido).

---

## 4. Estructura del TICKET DE COBRO

**Uso:** Comprobante para el cliente (qué consumió, cuánto pagó, quién lo atendió).  
**Incluye precios y totales.**

### 4.1 Orden de bloques (de arriba a abajo)

| Orden | Bloque | Contenido | Obligatorio |
|-------|--------|-----------|-------------|
| 1 | Restaurante | Nombre (centrado, negrita, doble altura) | Sí |
| 2 | Datos legales | Dirección, Tel, RFC (si existen) | Si existen |
| 3 | Separador | `====` | Sí |
| 4 | Folio | `Folio: ORD-XXXXXX` o texto de cuenta agrupada | Sí |
| 5 | Fecha/hora | Fecha y hora (CDMX) | Sí |
| 6 | Ubicación | `Mesa: X` o `*** PARA LLEVAR ***` + Cliente y Tel. | Sí (uno u otro) |
| 7 | Impreso por | `Impreso por: [nombre del usuario que imprime]` (cajero, admin o capitán) | Sí |
| 8 | Separador | `----` | Sí |
| 9 | Encabezado detalle | `CANT  DESCRIPCION ... TOTAL` | Sí |
| 10 | Separador | `----` | Sí |
| 11 | Ítems | Cantidad, descripción (producto + tamaño), total por línea; modificadores con precio; nota por ítem si hay | Sí |
| 12 | Separador | `----` | Sí |
| 13 | Totales | Subtotal, Descuento, Impuesto, Propina sugerida (si aplica), **TOTAL** | Sí |
| 14 | Separador | `====` | Sí |
| 15 | Código de barras | Code128 del folio (opcional, según `incluirCodigoBarras`) | Opcional |
| 16 | Cierre | “¡Gracias por su preferencia!”, “Vuelva pronto” (centrado) | Sí |
| 17 | Corte | Comando cortar papel | Sí |

### 4.2 Quién dispara el ticket

- **Cajero:** al procesar el pago (una cuenta = un ticket; cuenta agrupada = un ticket con todas las órdenes).
- **Capitán:** mismo flujo que cajero (puede cobrar e imprimir).
- **Administrador:** desde la lista de tickets, opción “Imprimir” (reimpresión). Misma estructura; en “Impreso por” sale el nombre del admin.

En todos los casos el documento es el **mismo tipo** (ticket de cobro); solo cambia quién aparece en “Impreso por”.

---

## 5. Flujos por rol (resumido)

### 5.1 Administrador

- **Comanda:** Reimpresión manual desde la app (si tiene la acción “Reimprimir comanda” en una orden). API: `POST /api/comandas/reimprimir` con `{ ordenId }`. Contenido: estructura de comanda (sección 3).
- **Ticket:** Reimpresión desde la sección Tickets. API: `POST /api/tickets/imprimir` con `{ ordenId, ordenIds?, incluirCodigoBarras }`. Contenido: estructura de ticket (sección 4). En el ticket figura “Impreso por: [nombre del admin]”.

### 5.2 Mesero

- **Comanda:** Reimpresión manual desde vista de mesa o cuenta dividida. Misma API y misma estructura que administrador.
- **Ticket:** No imprime ticket de cobro (solo cajero/capitán/admin).

### 5.3 Cocinero

- No dispara ninguna impresión. Las comandas le llegan por impresión automática (backend) o por reimpresión (mesero/capitán/admin).

### 5.4 Cajero

- **Comanda:** No imprime comanda.
- **Ticket:** Al cobrar (efectivo, tarjeta, mixto o desde “Imprimir comprobante” en voucher). API: `POST /api/tickets/imprimir`. Contenido: estructura de ticket. “Impreso por” = nombre del cajero.

### 5.5 Capitán

- **Comanda:** Igual que mesero (reimpresión manual).
- **Ticket:** Igual que cajero (al cobrar o cuando corresponda). “Impreso por” = nombre del capitán.

---

## 6. APIs y permisos

| Método | Ruta | Roles | Uso |
|--------|------|--------|-----|
| POST | `/api/comandas/reimprimir` | mesero, administrador, capitan | Reimprimir comanda (orden ya creada). |
| POST | `/api/tickets/imprimir` | administrador, cajero, capitan | Imprimir ticket de cobro (cobro o reimpresión). |
| GET | `/api/tickets` | administrador, cajero, capitan, mesero | Listar tickets (para consulta y reimpresión en admin). |

---

## 7. Lógica de impresoras

- **Comanda** → se envía a las impresoras configuradas con `documents: ["comanda"]` (o la impresora por defecto si no hay config).
- **Ticket de cobro** → se envía a las impresoras con `documents: ["ticket"]` (o la impresora por defecto).
- Una misma impresora puede tener `documents: ["comanda", "ticket"]` y recibir ambos.
- El **contenido** del documento (comanda o ticket) es único; no hay “variantes por rol”, salvo que en el ticket siempre se muestra “Impreso por” con el nombre del usuario que dispara la impresión (cajero, capitán o administrador).

---

*Documento de referencia para impresión por rol. Revisión: febrero 2026.*
