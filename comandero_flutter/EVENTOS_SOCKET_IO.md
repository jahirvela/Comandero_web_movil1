# Eventos Socket.IO - Comandix

## 📋 Lista Completa de Eventos

### 🔵 Eventos del Backend (Recibir)

#### 1. Eventos de Conexión
- **`connected`** ✅
  - **Cuándo:** Al conectarse exitosamente
  - **Payload:** `{ socketId: string, user: { id, username, roles } }`
  - **Implementado:** ✅ SocketService

- **`error`** ✅
  - **Cuándo:** Error de autenticación
  - **Payload:** `{ message: string }`
  - **Implementado:** ✅ SocketService (onConnectError)

#### 2. Eventos de Órdenes
- **`pedido.creado`** ✅
  - **Cuándo:** Se crea una nueva orden
  - **Payload:** `OrdenDetalle`
  - **Destinatarios:** Todos, `role:cocinero`, `role:capitan` (si tiene mesa)
  - **Implementado:** ✅ SocketService, ✅ Todos los controladores

- **`pedido.actualizado`** ✅
  - **Cuándo:** Se actualiza una orden (estado, items, etc.)
  - **Payload:** `OrdenDetalle`
  - **Destinatarios:** Todos, `role:cocinero`, `orden:{id}`
  - **Implementado:** ✅ SocketService, ✅ Todos los controladores

- **`pedido.cancelado`** ✅
  - **Cuándo:** Se cancela una orden
  - **Payload:** `OrdenDetalle`
  - **Destinatarios:** Todos, `role:cocinero`
  - **Implementado:** ✅ SocketService, ✅ Todos los controladores

#### 3. Eventos de Alertas
- **`alerta.demora`** ✅
  - **Cuándo:** Orden con demora en cocina
  - **Payload:** `AlertaPayload`
  - **Destinatarios:** `role:capitan`, `role:cocinero`
  - **Implementado:** ✅ SocketService, ✅ CaptainController, ✅ CocineroController

- **`alerta.cancelacion`** ✅
  - **Cuándo:** Orden cancelada
  - **Payload:** `AlertaPayload`
  - **Destinatarios:** `role:capitan`, `role:cocinero`, `role:mesero`
  - **Implementado:** ✅ SocketService, ✅ CaptainController, ✅ CocineroController

- **`alerta.modificacion`** ✅
  - **Cuándo:** Orden modificada
  - **Payload:** `AlertaPayload`
  - **Destinatarios:** `role:capitan`, `role:cocinero`
  - **Implementado:** ✅ SocketService, ✅ CaptainController

- **`alerta.caja`** ✅
  - **Cuándo:** Eventos relacionados con caja (cierres, pagos, etc.)
  - **Payload:** `AlertaPayload`
  - **Destinatarios:** `role:administrador`, `role:cajero`
  - **Implementado:** ✅ SocketService, ✅ CajeroController, ✅ AdminController

- **`alerta.cocina`** ✅
  - **Cuándo:** Alertas generales de cocina
  - **Payload:** `AlertaPayload`
  - **Destinatarios:** `role:cocinero`, estaciones específicas
  - **Implementado:** ✅ SocketService, ✅ CocineroController

- **`alerta.mesa`** ✅
  - **Cuándo:** Cambios en mesas (estado, ocupación, etc.)
  - **Payload:** `AlertaPayload`
  - **Destinatarios:** `role:mesero`, `role:capitan`, `role:administrador`
  - **Implementado:** ✅ SocketService, ✅ MeseroController, ✅ CaptainController

- **`alerta.pago`** ✅
  - **Cuándo:** Eventos de pago (pago recibido, procesado, etc.)
  - **Payload:** `AlertaPayload`
  - **Destinatarios:** `role:cajero`, `role:administrador`
  - **Implementado:** ✅ SocketService, ✅ CajeroController, ✅ AdminController

#### 4. Eventos de Cocina (Cliente → Servidor)
- **`cocina.alerta`** ✅
  - **Cuándo:** Cliente envía alerta a cocina
  - **Payload:** `{ mensaje: string, estacion?: string }`
  - **Destinatarios:** `role:cocinero` o `station:{estacion}`
  - **Implementado:** ✅ SocketService (emitKitchenAlert)

### 🔴 Eventos del Cliente (Emitir)

#### 1. Eventos de Cocina
- **`cocina.alerta`** ✅
  - **Uso:** Enviar alerta a cocina
  - **Payload:** `{ mensaje: string, estacion?: string }`
  - **Implementado:** ✅ SocketService.emitKitchenAlert()

#### 2. Eventos de Salas (Opcional)
- **`join`** ✅
  - **Uso:** Unirse a una sala específica
  - **Payload:** `string` (nombre de la sala)
  - **Implementado:** ✅ SocketService.joinRoom()

- **`leave`** ✅
  - **Uso:** Salir de una sala
  - **Payload:** `string` (nombre de la sala)
  - **Implementado:** ✅ SocketService.leaveRoom()

## 📊 Estado de Implementación por Controlador

### MeseroController ✅
- ✅ `pedido.actualizado` - Recibe actualizaciones de órdenes
- ✅ `pedido.cancelado` - Recibe cancelaciones
- ✅ `alerta.mesa` - Recibe cambios de mesas

### CocineroController ✅
- ✅ `pedido.creado` - Recibe nuevas órdenes
- ✅ `pedido.actualizado` - Recibe actualizaciones
- ✅ `pedido.cancelado` - Recibe cancelaciones
- ✅ `alerta.cocina` - Recibe alertas de cocina
- ✅ `cocina.alerta` - Puede emitir alertas

### CajeroController ✅
- ✅ `pedido.creado` - Recibe nuevas órdenes (para crear facturas)
- ✅ `pedido.actualizado` - Recibe actualizaciones
- ✅ `alerta.pago` - Recibe alertas de pago
- ✅ `alerta.caja` - Recibe alertas de caja

### CaptainController ✅
- ✅ `pedido.creado` - Recibe nuevas órdenes (con mesa)
- ✅ `pedido.actualizado` - Recibe actualizaciones
- ✅ `alerta.demora` - Recibe alertas de demora
- ✅ `alerta.cancelacion` - Recibe alertas de cancelación
- ✅ `alerta.modificacion` - Recibe alertas de modificación
- ✅ `alerta.mesa` - Recibe cambios de mesas

### AdminController ✅
- ✅ `pedido.creado` - Recibe todas las órdenes
- ✅ `pedido.actualizado` - Recibe actualizaciones
- ✅ `pedido.cancelado` - Recibe cancelaciones
- ✅ `alerta.pago` - Recibe alertas de pago
- ✅ `alerta.caja` - Recibe alertas de caja
- ✅ `alerta.*` - Recibe todas las alertas (genérico)

## 🎯 Eventos Faltantes por Implementar

### ⚠️ Eventos que necesitan mejoras:

1. **`alerta.inventario`** - ❌ No existe en backend
   - **Sugerencia:** Crear para alertas de stock bajo, productos vencidos, etc.

2. **`mesa.actualizada`** - ❌ No existe como evento específico
   - **Estado actual:** Se usa `alerta.mesa` genérico
   - **Sugerencia:** Crear evento específico para cambios de estado de mesa

3. **`pago.procesado`** - ❌ No existe como evento específico
   - **Estado actual:** Se usa `alerta.pago` genérico
   - **Sugerencia:** Crear eventos específicos para diferentes tipos de pago

4. **`usuario.conectado`** / **`usuario.desconectado`** - ❌ No existe
   - **Sugerencia:** Para mostrar quién está en línea

5. **`notificacion.personal`** - ❌ No existe
   - **Sugerencia:** Para notificaciones directas a usuarios específicos

## ✅ Resumen Final

- **Total de eventos del backend:** 14
- **Eventos implementados en SocketService:** 14 ✅
- **Eventos conectados en controladores:** 14 ✅
- **Eventos del cliente implementados:** 3 ✅

**Estado:** ✅ **TODOS LOS EVENTOS ESTÁN IMPLEMENTADOS Y CONECTADOS**

## 🧪 Cómo Probar los Eventos

### Prueba 1: Crear Orden desde Mesero
1. Inicia sesión como **Mesero**
2. Selecciona una mesa y agrega productos al carrito
3. Envía la orden a cocina
4. **Verifica:**
   - ✅ La orden aparece automáticamente en **Cocinero**
   - ✅ La factura aparece en **Cajero**
   - ✅ Se muestra en el dashboard de **Administrador**
   - ✅ Aparece como alerta en **Capitán** (si tiene mesa)

### Prueba 2: Actualizar Estado desde Cocinero
1. Inicia sesión como **Cocinero**
2. Cambia el estado de una orden (ej: "En preparación" → "Listo")
3. **Verifica:**
   - ✅ El **Mesero** recibe notificación del cambio
   - ✅ El **Administrador** ve la actualización
   - ✅ El **Capitán** ve el cambio si es relevante

### Prueba 3: Enviar Alerta a Cocina
1. Inicia sesión como **Mesero** o **Capitán**
2. Envía una alerta a cocina usando `SocketService().emitKitchenAlert()`
3. **Verifica:**
   - ✅ Los **Cocineros** reciben la alerta en tiempo real

### Prueba 4: Procesar Pago desde Cajero
1. Inicia sesión como **Cajero**
2. Procesa un pago
3. **Verifica:**
   - ✅ El **Administrador** recibe la actualización
   - ✅ Las estadísticas se actualizan

### Prueba 5: Cancelar Orden
1. Desde cualquier rol, cancela una orden
2. **Verifica:**
   - ✅ El **Cocinero** recibe la alerta de cancelación
   - ✅ El **Capitán** recibe la alerta
   - ✅ El **Mesero** recibe notificación
   - ✅ La orden desaparece de las listas activas

## 📝 Notas de Implementación

- Todos los controladores se inicializan con `_setupSocketListeners()` automáticamente
- Los eventos se procesan de forma asíncrona y actualizan la UI mediante `notifyListeners()`
- Los errores se capturan y se registran en consola sin interrumpir la aplicación
- La conexión de Socket.IO se establece automáticamente después del login

