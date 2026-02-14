# Impresión de tickets y comandas por rol

Este documento describe **qué se imprime** en el sistema Comandero, **quién** puede disparar cada impresión y **qué contenido** tiene cada tipo de documento (comanda vs ticket de cobro).

> **Estructura detallada:** La definición exacta de bloques y campos de cada documento (comanda y ticket de cobro) está en [IMPRESION_ESTRUCTURA_POR_ROL.md](./IMPRESION_ESTRUCTURA_POR_ROL.md).

---

## Resumen rápido

| Rol            | Comanda (cocina)     | Ticket de cobro (cliente) |
|----------------|----------------------|----------------------------|
| **Mesero**     | Reimpresión manual   | No                         |
| **Cajero**     | No                   | Sí (al cobrar)             |
| **Cocinero**   | No                   | No                         |
| **Administrador** | Reimpresión manual | Sí (desde lista de tickets) |
| **Capitán**    | Reimpresión manual   | Sí (misma API que cajero)  |
| **Backend**    | Automática al crear orden | No                    |

---

## 1. Mesero

### Qué imprime

- **Comanda** (solo **reimpresión manual**).

### Cuándo

- Cuando el mesero elige **"Reimprimir comanda"** en una orden desde:
  - Vista de mesa (`table_view.dart`).
  - Vista de cuenta dividida (`divided_account_view.dart`).

### Flujo técnico

1. **Flutter:** `_reimprimirComanda(context, ordenId)` → `ComandasService.reimprimirComanda(ordenId)`.
2. **API:** `POST /api/comandas/reimprimir` con body `{ "ordenId": number }`.
3. **Backend:** `comandas.controller.ts` → `reimprimirComanda` (service) → `comandas.printer.ts` → `generarContenidoComanda` + envío a impresora configurada.

### Permisos backend

- `requireRoles('mesero', 'administrador', 'capitan')` en `comandas.routes.ts`.

### Contenido de la comanda (formato cocina)

- Encabezado: `*** COMANDA ***`.
- Folio: `ORD-XXXXXX`, fecha y hora.
- Mesa o `*** PARA LLEVAR ***` con cliente y teléfono.
- Mesero, tiempo estimado de preparación.
- Lista de ítems: cantidad, producto (con tamaño), modificadores, notas por ítem.
- Notas generales de la orden (si existen).
- Pie: folio y fecha.

**Archivos relevantes**

- Flutter: `lib/views/mesero/table_view.dart`, `lib/views/mesero/divided_account_view.dart`, `lib/services/comandas_service.dart`.
- Backend: `src/modules/comandas/comandas.controller.ts`, `comandas.service.ts`, `comandas.printer.ts`, `comandas.routes.ts`.

---

## 2. Cajero

### Qué imprime

- **Ticket de cobro (factura para el cliente)**.

### Cuándo

- Al **procesar el pago** de una cuenta: el flujo marca la factura como impresa y envía la impresión al backend.
- Opcionalmente desde el **modal de comprobante de tarjeta** (“Imprimir comprobante”), que usa el mismo flujo de impresión de ticket.

### Flujo técnico

1. **Flutter:** `CajeroController.markBillAsPrinted(billId, printedBy, paymentId?, ordenId?)` → `TicketsService.imprimirTicket(ordenId, ordenIds?, incluirCodigoBarras)`.
2. **API:** `POST /api/tickets/imprimir` con body `{ ordenId, ordenIds? (cuentas agrupadas), incluirCodigoBarras }`.
3. **Backend:** `tickets.controller.ts` → `imprimirTicket` (service) → `tickets.printer.ts` → `generarContenidoTicket` + envío a impresora.

### Permisos backend

- `requireRoles('administrador', 'cajero', 'capitan')` en `tickets.routes.ts` para `POST /api/tickets/imprimir`.

### Contenido del ticket (factura)

- Nombre del restaurante, dirección, teléfono, RFC.
- Folio, fecha/hora.
- Mesa o `*** PARA LLEVAR ***`, cliente, teléfono.
- Impreso por: nombre del usuario que imprime (cajero, capitán o administrador).
- Detalle: cantidad, descripción (producto + tamaño), total por línea; modificadores y notas si aplican.
- Subtotal, descuento, impuesto, propina sugerida, **TOTAL**.
- Código de barras Code128 del folio (opcional, `incluirCodigoBarras`).
- Mensajes: “¡Gracias por su preferencia!”, “Vuelva pronto”.

### Nota sobre la UI

- El diálogo “Imprimir Ticket” desde la lista de cuentas del cajero está **simulado** (solo muestra SnackBar “Ticket impreso (simulado)”).
- La impresión real se hace al **cobrar** (efectivo, tarjeta, mixto, etc.) vía `markBillAsPrinted`; en pago con tarjeta, el botón “Imprimir comprobante” del modal de voucher también llama a `markBillAsPrinted` y por tanto imprime el mismo ticket.

**Archivos relevantes**

- Flutter: `lib/controllers/cajero_controller.dart` (`markBillAsPrinted`), `lib/services/tickets_service.dart`, `lib/views/cajero/cajero_app.dart`, `lib/views/cajero/card_voucher_modal.dart`.
- Backend: `src/modules/tickets/tickets.controller.ts`, `tickets.service.ts`, `tickets.printer.ts`, `tickets.repository.ts`, `tickets.routes.ts`.

---

## 3. Cocinero

### Qué imprime

- **Nada.** El rol cocinero no dispara ninguna impresión desde la app.

Las comandas se imprimen en backend cuando se **crea** la orden (ver sección “Backend – impresión automática”).

---

## 4. Administrador

### Qué imprime

- **Ticket de cobro:** mismo documento que imprime el cajero.
- **Comanda:** puede reimprimir vía la misma API que el mesero (si en la app admin tiene acceso a esa acción).

### Cuándo (ticket)

- Desde la sección de **Tickets**: el administrador elige “Imprimir” en un ticket listado.

### Flujo técnico (ticket)

1. **Flutter:** `AdminController.printTicket(ticketId, printedBy)` → `TicketsService.imprimirTicket(ordenId, …)`.
2. **API:** mismo `POST /api/tickets/imprimir`.
3. **Backend:** mismo flujo que para el cajero.

### Permisos backend

- Listar tickets: `GET /api/tickets` — `requireRoles('administrador', 'cajero', 'capitan', 'mesero')`.
- Imprimir ticket: `POST /api/tickets/imprimir` — `requireRoles('administrador', 'cajero', 'capitan')`.

**Archivos relevantes**

- Flutter: `lib/controllers/admin_controller.dart` (`printTicket`), `lib/views/admin/admin_app.dart`, `lib/views/admin/admin_web_app.dart`.

---

## 5. Capitán

### Qué imprime

- **Comanda:** reimpresión manual (misma API que mesero).
- **Ticket de cobro:** misma API que cajero/administrador.

### Permisos backend

- Comanda: `POST /api/comandas/reimprimir` — `requireRoles('mesero', 'administrador', 'capitan')`.
- Ticket: `POST /api/tickets/imprimir` — `requireRoles('administrador', 'cajero', 'capitan')`.

---

## 6. Backend – impresión automática (sin rol en front)

### Qué imprime

- **Comanda** (primera vez, impresión automática).

### Cuándo

- Al **crear una orden** y que su estado se considere “relevante para cocina” (no pagada, cancelada, cerrada, listo, ready, completada, finalizada).

### Flujo técnico

1. **Backend:** `realtime/events.ts` → `emitOrderCreated(orden)`.
2. Se evalúa el estado; si es relevante para cocina se llama en forma asíncrona (`setImmediate`) a `imprimirComandaAutomatica(orden.id)`.
3. **Comandas:** `comandas.service.ts` → verifica si la comanda ya fue impresa; si no, obtiene detalle de la orden, llama a `imprimirComanda(orden, false)` en `comandas.printer.ts` y marca como impresa.

### Contenido

- El mismo que la comanda de reimpresión: formato cocina (folio, mesa/para llevar, mesero, tiempo estimado, ítems con cantidades, modificadores, notas).

**Archivos relevantes**

- Backend: `src/realtime/events.ts` (`emitOrderCreated`), `src/modules/comandas/comandas.service.ts` (`imprimirComandaAutomatica`), `comandas.printer.ts`, `comandas.repository.ts` (verificación/marca de impresa).

---

## Tipos de documento

### Comanda (para cocina)

| Campo        | Descripción |
|-------------|-------------|
| **Uso**     | Orden de producción para cocina (sin precios para el cliente). |
| **Disparado por** | Backend al crear orden; Mesero/Capitán/Admin (reimpresión). |
| **Contenido** | Folio, mesa/para llevar, mesero, tiempo estimado, ítems (cantidad, producto, tamaño, modificadores, notas), notas generales. |
| **Impresora** | La configurada en backend (simulación, archivo, red TCP, USB). |

### Ticket de cobro (factura cliente)

| Campo        | Descripción |
|-------------|-------------|
| **Uso**     | Comprobante para el cliente (con totales y opcional código de barras). |
| **Disparado por** | Cajero al cobrar; Admin/Capitán desde lista de tickets. |
| **Contenido** | Datos restaurante, folio, mesa/cliente, impreso por, ítems con precios, subtotal/descuento/impuesto/propina/total, código de barras (opcional), mensaje de cierre. |
| **Impresora** | Misma configuración backend (módulo `tickets`). |

---

## APIs de impresión

| Método | Ruta | Roles | Descripción |
|--------|------|--------|-------------|
| POST   | `/api/comandas/reimprimir` | mesero, administrador, capitan | Reimprime comanda de una orden. |
| POST   | `/api/tickets/imprimir`    | administrador, cajero, capitan | Imprime ticket de cobro (una o varias órdenes agrupadas). |
| GET    | `/api/tickets`             | administrador, cajero, capitan, mesero | Lista tickets (órdenes pagadas) para consulta/reimpresión. |

---

## Configuración de impresora(s) (backend)

El backend soporta **una o varias impresoras térmicas** (58mm o 80mm, USB o red):

- **Una impresora:** se configura por `.env` (misma para comanda y ticket).
- **Varias impresoras:** archivo `backend/config/printers.json` donde cada impresora tiene `documents: ["comanda"]`, `["ticket"]` o ambos.

Cada impresora puede ser:
- **Simulación:** guarda en archivos (ej. `backend/tickets/*.txt`).
- **Archivo:** escribe en una ruta fija.
- **Red (TCP):** host y puerto.
- **USB:** nombre de la impresora en Windows (ej. `Thermal Receipt Printer`) o puerto.

Para impresoras **58mm** (ej. ZKP5803) se debe indicar `PRINTER_PAPER_WIDTH=58` en `.env` o `paperWidth: 58` en cada impresora del JSON.

Documentación detallada: `backend/docs/IMPRESORAS_TERMICAS.md` y `backend/docs/CONFIGURAR_IMPRESORA_USB.md`.

---

*Documento generado a partir del análisis del código del proyecto Comandero. Última revisión: febrero 2026.*
