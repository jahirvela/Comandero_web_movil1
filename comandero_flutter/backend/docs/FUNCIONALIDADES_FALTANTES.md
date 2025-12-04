# 📋 Funcionalidades Faltantes - Análisis Completo

Este documento detalla todas las funcionalidades que **faltan por implementar** o que están **parcialmente implementadas** en el proyecto Comandero.

---

## 🔴 CRÍTICAS (Alta Prioridad)

### 1. **Cierre de Caja - Endpoint de Creación**

**Estado**: ⚠️ **FALTA ENDPOINT EN BACKEND**

**Descripción**: 
- El cajero puede ver cierres de caja (GET `/api/cierres`)
- **NO existe endpoint POST para crear/enviar un cierre de caja**
- El método `sendCashClose()` en `CajeroController` solo guarda localmente

**Ubicación**:
- Frontend: `lib/controllers/cajero_controller.dart` línea 370
- Backend: `backend/src/modules/cierres/cierres.routes.ts` - Solo tiene GET

**Acción Requerida**:
```typescript
// Agregar a cierres.routes.ts
cierresRouter.post(
  '/',
  authenticate,
  authorize(['cajero', 'administrador']),
  crearCierreCajaHandler
);
```

**Impacto**: Los cierres de caja no se guardan en la base de datos, solo localmente.

---

### 2. **Obtener Nombre de Usuario del AuthController**

**Estado**: ⚠️ **TODOs EN MÚLTIPLES LUGARES**

**Descripción**: 
- Múltiples lugares usan `'Mesero'`, `'Cajero'` hardcodeado
- Deberían obtener el nombre real del usuario autenticado

**Ubicaciones con TODO**:
- `lib/controllers/mesero_controller.dart` líneas 1403, 1419
- `lib/views/cajero/cajero_app.dart` líneas 1400, 1681, 1704
- `lib/views/cajero/cash_payment_modal.dart` línea 335
- `lib/views/cajero/card_voucher_modal.dart` línea 498

**Acción Requerida**:
```dart
// Obtener del AuthController
final authController = Provider.of<AuthController>(context, listen: false);
final userName = authController.userName ?? 'Usuario';
```

**Impacto**: Menor - solo afecta la visualización, no la funcionalidad.

---

## 🟡 IMPORTANTES (Media Prioridad)

### 3. **Vistas con Datos Mock - Cocinero**

**Estado**: ⚠️ **DATOS MOCK, NO CONECTADAS AL BACKEND**

#### 3.1. **Gestión de Personal (Staff Management)**
- **Archivo**: `lib/views/cocinero/staff_management_view.dart`
- **Problema**: Usa datos hardcodeados (mock)
- **Backend**: No existe endpoint para gestión de personal
- **Funcionalidad**: Mostrar personal de cocina, turnos, eficiencia

#### 3.2. **Gestión de Estaciones (Station Management)**
- **Archivo**: `lib/views/cocinero/station_management_view.dart`
- **Problema**: Usa datos hardcodeados (mock)
- **Backend**: No existe endpoint para gestión de estaciones
- **Funcionalidad**: Mostrar estaciones de cocina, órdenes por estación

#### 3.3. **Consumo de Ingredientes**
- **Archivo**: `lib/views/cocinero/ingredient_consumption_view.dart`
- **Problema**: Usa datos hardcodeados (mock)
- **Backend**: Existe inventario, pero no hay endpoint específico para consumo diario
- **Funcionalidad**: Mostrar consumo de ingredientes por día

**Acción Requerida**:
- Crear endpoints en backend para estas funcionalidades
- O conectar con datos existentes del inventario/órdenes

---

### 4. **Vistas con Datos Mock - Cajero**

#### 4.1. **Gestión de Efectivo (Cash Management)**
- **Archivo**: `lib/views/cajero/cash_management_view.dart`
- **Problema**: Usa datos mock para operaciones de efectivo
- **Backend**: No existe endpoint para operaciones de efectivo (entradas/salidas)
- **Funcionalidad**: Registrar entradas/salidas de efectivo, historial

#### 4.2. **Reportes de Ventas**
- **Archivo**: `lib/views/cajero/sales_reports_view.dart`
- **Problema**: Usa datos mock para gráficos y estadísticas
- **Backend**: Existe módulo de reportes, pero no está conectado en esta vista
- **Funcionalidad**: Mostrar gráficos de ventas, estadísticas

**Acción Requerida**:
- Conectar `sales_reports_view.dart` con `ReportesService`
- Crear endpoint para operaciones de efectivo si se requiere

---

### 5. **Vistas con Datos Mock - Administrador**

#### 5.1. **Ventas en Tiempo Real (Web)**
- **Archivo**: `lib/views/admin/web/real_time_sales_web_view.dart`
- **Problema**: Usa datos simulados/calculados localmente
- **Backend**: Existe datos, pero la vista no está completamente conectada
- **Funcionalidad**: Mostrar ventas en tiempo real con gráficos

#### 5.2. **Reportes de Usuarios (Web)**
- **Archivo**: `lib/views/admin/web/users_reports_web_view.dart`
- **Problema**: Usa datos mock para estadísticas de usuarios
- **Backend**: Existe datos de usuarios, pero no hay endpoint de estadísticas
- **Funcionalidad**: Mostrar estadísticas de actividad de usuarios

**Acción Requerida**:
- Conectar con datos reales del backend
- Crear endpoints de estadísticas si se requieren

---

## 🟢 MENORES (Baja Prioridad)

### 6. **Datos Faltantes en Órdenes**

**Estado**: ⚠️ **TODOs EN CÓDIGO**

**Ubicaciones**:
- `lib/controllers/cocinero_controller.dart`:
  - Línea 796: `estimatedTime: 15, // TODO: Calcular o obtener del backend`
  - Línea 804: `customerPhone: null, // TODO: Obtener del backend`
  - Línea 805: `pickupTime: null, // TODO: Obtener del backend`

**Acción Requerida**:
- Agregar estos campos al backend si se requieren
- O calcular `estimatedTime` basado en items de la orden

---

### 7. **Impresión de Tickets - Conectar con Backend**

**Estado**: ⚠️ **NO CONECTADO CON BACKEND**

**Descripción**:
- Backend: ✅ Endpoint `/api/tickets/imprimir` existe y funciona
- Frontend: ✅ `TicketsService.imprimirTicket()` existe
- UI: ✅ Botones de impresión existen en `cajero_app.dart` y `admin_app.dart`
- **Problema CRÍTICO**: 
  - `AdminController.printTicket()` (línea 1109): Solo marca como impreso localmente, **NO llama a `TicketsService.imprimirTicket()`**
  - `CajeroController.markBillAsPrinted()` (línea 336): Solo marca localmente, **NO llama a `TicketsService.imprimirTicket()`**
  - En `cajero_app.dart` línea 1401: `// TODO: Implementar impresión real con impresora térmica`

**Ubicación**: 
- `lib/controllers/admin_controller.dart` línea 1109
- `lib/controllers/cajero_controller.dart` línea 336
- `lib/views/cajero/cajero_app.dart` línea 1397-1401

**Acción Requerida**:
- Modificar `AdminController.printTicket()` para llamar a `_ticketsService.imprimirTicket()`
- Modificar `CajeroController.markBillAsPrinted()` o crear `printTicket()` que llame a `TicketsService.imprimirTicket()`
- Conectar el botón en `cajero_app.dart` con el método correcto

---

### 8. **Reportes - Integración en UI**

**Estado**: ⚠️ **SERVICIO EXISTE, PERO NO ESTÁ COMPLETAMENTE CONECTADO**

**Descripción**:
- Backend: ✅ Módulo de reportes completo (PDF/CSV)
- Frontend: ✅ `ReportesService` existe con todos los métodos
- **Problema**: 
  - `sales_reports_view.dart` no usa `ReportesService`
  - No hay botones claros para generar reportes en algunas vistas

**Acción Requerida**:
- Conectar `sales_reports_view.dart` con `ReportesService`
- Agregar botones de "Generar PDF/CSV" en vistas de reportes

---

### 9. **Cambio de Estado del Puesto (Mesero)**

**Estado**: ⚠️ **TODOs EN CÓDIGO**

**Ubicaciones**:
- `lib/views/mesero/mesero_app.dart` línea 364
- `lib/views/mesero/cart_view.dart` línea 908
- `lib/views/mesero/order_history_view.dart` línea 568

**Descripción**: 
- Hay comentarios `// TODO: Implementar cambio de estado del puesto`
- No está claro qué funcionalidad se refiere

**Acción Requerida**: 
- Aclarar qué es "cambio de estado del puesto"
- Implementar si es necesario

---

## 📊 RESUMEN POR PRIORIDAD

### 🔴 CRÍTICAS (Deben implementarse)
1. ✅ Endpoint POST para crear cierre de caja
2. ⚠️ Obtener nombre de usuario del AuthController (múltiples lugares)

### 🟡 IMPORTANTES (Recomendadas)
3. ✅ Conectar vistas de Cocinero con backend (staff, stations, ingredients)
4. ✅ Conectar vistas de Cajero con backend (cash management, sales reports)
5. ✅ Conectar vistas de Admin con backend (real-time sales, user reports)

### 🟢 MENORES (Opcionales)
6. ⚠️ Agregar campos faltantes en órdenes (estimatedTime, customerPhone, pickupTime)
7. ⚠️ Agregar botón de impresión de tickets en UI
8. ⚠️ Conectar reportes completamente en UI
9. ⚠️ Implementar "cambio de estado del puesto" (si es necesario)

---

## 📈 ESTADO GENERAL

### ✅ Funcionalidades Completas
- ✅ Autenticación y autorización
- ✅ CRUD de usuarios, productos, categorías, inventario, mesas
- ✅ Gestión de órdenes (crear, actualizar, cancelar)
- ✅ Procesamiento de pagos (efectivo y tarjeta)
- ✅ Sistema de alertas en tiempo real
- ✅ Socket.IO para comunicación en tiempo real
- ✅ Tickets (listar - backend completo)
- ✅ Reportes (generación PDF/CSV - backend completo)
- ✅ Impresión de tickets (backend completo, conectado en Admin, falta en Cajero)

### ⚠️ Funcionalidades Parciales
- ⚠️ Cierres de caja (solo lectura, falta crear)
- ⚠️ Impresión de tickets (conectado en Admin, falta conectar en Cajero)
- ⚠️ Reportes (backend completo, falta conectar algunas vistas)
- ⚠️ Vistas de Cocinero (staff, stations, ingredients - datos mock)
- ⚠️ Vistas de Cajero (cash management, sales reports - datos mock)
- ⚠️ Vistas de Admin (algunas con datos mock)

### ❌ Funcionalidades Faltantes
- ❌ Endpoint POST para crear cierre de caja
- ❌ Módulo completo de reservas (backend + frontend)
- ❌ Envío de modificadores al backend al crear órdenes
- ❌ Endpoints para gestión de personal de cocina
- ❌ Endpoints para gestión de estaciones de cocina
- ❌ Endpoint para consumo diario de ingredientes
- ❌ Endpoint para operaciones de efectivo (entradas/salidas)
- ❌ Endpoints de estadísticas de usuarios

---

## 🎯 RECOMENDACIONES

### Prioridad 1 (Inmediata)
1. **Crear endpoint POST `/api/cierres`** para que el cajero pueda enviar cierres de caja
2. **Obtener nombre de usuario** del AuthController en todos los lugares con TODO

### Prioridad 2 (Corto Plazo)
3. **Conectar vistas con datos reales**:
   - `sales_reports_view.dart` → `ReportesService`
   - `real_time_sales_web_view.dart` → Datos reales del backend
4. **Agregar botón de impresión** de tickets en la UI del cajero

### Prioridad 3 (Mediano Plazo)
5. **Implementar endpoints faltantes**:
   - Gestión de personal de cocina
   - Gestión de estaciones
   - Consumo de ingredientes
   - Operaciones de efectivo
6. **Conectar todas las vistas mock** con datos reales del backend

---

---

## 🔵 FUNCIONALIDADES ADICIONALES (No Críticas)

### 10. **Reservas de Mesas**

**Estado**: ⚠️ **TABLA EXISTE, PERO NO HAY MÓDULO**

**Descripción**:
- ✅ Tabla `reserva` existe en la base de datos
- ✅ Las órdenes tienen campo `reservaId` (se puede asociar orden a reserva)
- ✅ Las mesas tienen campo `reservation` en `TableModel` (solo para mostrar)
- ❌ **NO existe módulo de reservas en el backend** (`backend/src/modules/reservas/`)
- ❌ **NO hay endpoints** para crear/editar/cancelar reservas
- ❌ **NO hay UI** para gestionar reservas

**Ubicación**:
- Base de datos: Tabla `reserva` definida en migraciones
- Frontend: Campo `reservation` en `TableModel` (solo lectura)

**Acción Requerida**:
- Crear módulo completo de reservas en backend:
  - `reservas.controller.ts`
  - `reservas.service.ts`
  - `reservas.repository.ts`
  - `reservas.routes.ts`
  - `reservas.schemas.ts`
- Crear servicio en frontend: `reservas_service.dart`
- Crear UI para gestionar reservas (crear, editar, cancelar, confirmar)
- Conectar con mesas para mostrar reservas

**Impacto**: Las reservas no se pueden crear ni gestionar desde la aplicación.

---

### 11. **Modificadores de Productos - No Se Envían al Backend**

**Estado**: ⚠️ **UI EXISTE, PERO NO SE ENVÍAN**

**Descripción**:
- ✅ Tablas de modificadores existen en la base de datos (`modificador_categoria`, `modificador_opcion`, `producto_modificador`, `orden_item_modificador`)
- ✅ Backend soporta modificadores (se pueden guardar en `orden_item_modificador`)
- ✅ Frontend tiene UI para seleccionar modificadores (`product_modifier_modal.dart`)
- ❌ **Los modificadores NO se envían al backend** cuando se crea la orden
- En `mesero_controller.dart` línea 1279-1280: `// Extraer modificadores si existen (por ahora vacío, se puede expandir)`

**Ubicación**:
- `lib/controllers/mesero_controller.dart` línea 1279-1291
- `lib/views/mesero/product_modifier_modal.dart` - UI completa

**Acción Requerida**:
- Extraer modificadores seleccionados de `cartItem.customizations['extras']`
- Mapear a formato del backend: `{ modificadorOpcionId: number, precioUnitario: number }`
- Enviar en el array `modificadores` al crear la orden

**Impacto**: Los modificadores seleccionados por el mesero no se guardan en la base de datos.

---

## 📊 RESUMEN EJECUTIVO

### Estado del Proyecto: **~85% Completo**

#### ✅ Funcionalidades Core (100% Completas)
- Autenticación y autorización
- CRUD completo de todas las entidades principales
- Gestión de órdenes y pagos
- Comunicación en tiempo real (Socket.IO)
- Sistema de alertas

#### ⚠️ Funcionalidades Parciales (Necesitan Completarse)
- Cierres de caja (falta crear)
- Impresión de tickets (falta conectar con backend)
- Reportes (algunas vistas no conectadas)
- Vistas con datos mock (staff, stations, ingredients, cash management)

#### ❌ Funcionalidades Faltantes (No Críticas)
- Endpoints adicionales para funcionalidades avanzadas
- Gestión de personal de cocina
- Gestión de estaciones
- Operaciones de efectivo

---

**Última actualización**: 2024-01-XX
**Estado del Proyecto**: ~85% Completo

**Funcionalidades Críticas Faltantes**: 3
1. Endpoint POST para crear cierre de caja
2. Conectar impresión de tickets con backend
3. Enviar modificadores al backend al crear órdenes

**Funcionalidades Importantes Faltantes**: 2
1. Módulo completo de reservas
2. Obtener nombre de usuario del AuthController

**Total de Funcionalidades Identificadas**: 11
- 🔴 Críticas: 3
- 🟡 Importantes: 5
- 🟢 Menores: 3

