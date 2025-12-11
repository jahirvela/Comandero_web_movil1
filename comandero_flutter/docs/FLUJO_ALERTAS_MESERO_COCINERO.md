# 🔔 Flujo Completo de Alertas Mesero → Cocinero

## 📋 Resumen del Sistema

El sistema de alertas permite que el **mesero** envíe alertas al **cocinero** en tiempo real. Las alertas se guardan en la base de datos para que el cocinero pueda verlas incluso si no estaba conectado cuando se enviaron.

---

## 🔄 Flujo de Trabajo Completo

### 1️⃣ **Creación de Orden (Mesero)**

Cuando el mesero crea una orden:
- ✅ La orden se guarda en BD con estado inicial (ej: "abierta")
- ✅ El cocinero **NO** ve la orden automáticamente en su pantalla
- ⚠️ **IMPORTANTE**: El mesero **NO puede enviar alertas** todavía porque la orden aún no está "enviada a cocina"

### 2️⃣ **Envío de Orden a Cocina (Mesero)**

Cuando el mesero hace clic en **"Enviar a Cocina"**:
- ✅ La orden cambia de estado a "en_preparacion" o similar
- ✅ La orden **aparece en la pantalla del cocinero** automáticamente
- ✅ El cocinero puede ver la orden y comenzar a prepararla
- ✅ **AHORA SÍ**: El mesero puede enviar alertas sobre esta orden

**¿Por qué?** Porque la orden ya está en el sistema del cocinero y tiene un `orderId` válido.

### 3️⃣ **Envío de Alerta (Mesero → Cocinero)**

Cuando el mesero envía una alerta desde el modal "Enviar alerta a cocina":

#### **Paso 1: Mesero crea la alerta**
```
Mesero hace clic en "Enviar alerta" 
  ↓
Se abre modal con:
  - Tipo: Demora, Cancelación, Cambio en orden, Otra
  - Motivo: Mucho tiempo de espera, Cliente se retiró, etc.
  - Detalles adicionales (opcional)
  - Prioridad: Normal o Urgente
```

#### **Paso 2: Frontend envía alerta**
```
Frontend (Flutter) → Socket.IO
  Evento: kitchen:alert:create
  Payload: {
    orderId: 90,
    tableId: 11,
    station: "general" (o se determina automáticamente),
    type: "EXTRA_ITEM" (para Demora),
    message: "Demora: Mucho tiempo de espera"
  }
```

#### **Paso 3: Backend procesa la alerta**
```
Backend recibe kitchen:alert:create
  ↓
1. Valida que el usuario es mesero
2. Obtiene información de la orden
3. Determina la estación (tacos, consomes, bebidas, general)
4. **GUARDA EN BD** (tipo: 'operacion')
5. Emite a Socket.IO rooms:
   - room:kitchen:all (todos los cocineros)
   - room:kitchen:{station} (estación específica si aplica)
6. Envía ACK al mesero (kitchen:alert:created)
```

#### **Paso 4: Cocinero recibe la alerta**

**Si el cocinero está conectado:**
```
Socket.IO → Cocinero
  Evento: kitchen:alert:new
  ↓
CocineroController procesa la alerta
  ↓
Se agrega a la lista de alertas
  ↓
Aparece en tiempo real en la UI del cocinero
```

**Si el cocinero NO está conectado:**
```
La alerta se guarda en BD
  ↓
Cuando el cocinero se conecta:
  1. Se carga automáticamente desde BD
  2. Se agrega a la lista de alertas
  3. Aparece en la UI
```

---

## ⏰ Cuándo Puede el Mesero Enviar Alertas

### ✅ **SÍ puede enviar alertas cuando:**
1. La orden ya fue **enviada a cocina** (estado: "en_preparacion" o similar)
2. La orden existe en el sistema del cocinero
3. El cocinero puede ver la orden en su pantalla

### ❌ **NO puede enviar alertas cuando:**
1. La orden está en estado "abierta" (aún no enviada a cocina)
2. La orden está "pagada" o "cancelada"
3. La orden no existe o fue eliminada

---

## 🔍 Tipos de Alertas

### 1. **Demora** (EXTRA_ITEM)
- **Cuándo**: El cliente está esperando mucho tiempo
- **Motivos comunes**: 
  - Mucho tiempo de espera
  - Cliente impaciente
- **Prioridad**: Normal o Urgente

### 2. **Cancelación** (CANCEL_ORDER)
- **Cuándo**: El cliente canceló el pedido
- **Motivos comunes**:
  - Cliente se retiró
  - Cliente cambió de opinión
- **Prioridad**: Normal o Urgente

### 3. **Cambio en orden** (UPDATE_ORDER)
- **Cuándo**: El cliente quiere modificar algo del pedido
- **Motivos comunes**:
  - Cliente cambió pedido
  - Error en comanda
- **Prioridad**: Normal

### 4. **Otra** (NEW_ORDER)
- **Cuándo**: Cualquier otra situación
- **Motivos**: Varios
- **Prioridad**: Normal

---

## 🏗️ Arquitectura Técnica

### **Eventos Socket.IO**

#### **Cliente → Servidor:**
- `kitchen:alert:create` - Mesero envía alerta

#### **Servidor → Cliente:**
- `kitchen:alert:new` - Nueva alerta para cocineros
- `kitchen:alert:created` - ACK al mesero (confirmación)
- `kitchen:alert:error` - Error al procesar alerta

### **Rooms de Socket.IO**

- `room:kitchen:all` - Todos los cocineros
- `room:kitchen:tacos` - Cocineros de estación tacos
- `room:kitchen:consomes` - Cocineros de estación consomes
- `room:kitchen:bebidas` - Cocineros de estación bebidas

### **Base de Datos**

Tabla: `alerta`
- `tipo`: 'operacion' (para alertas de cocina)
- `mensaje`: Texto de la alerta
- `orden_id`: ID de la orden relacionada
- `mesa_id`: ID de la mesa (null si es para llevar)
- `usuario_origen_id`: ID del mesero que creó la alerta
- `leida`: 0 = no leída, 1 = leída

---

## 🔧 Solución Implementada

### **Problema Original:**
- Las alertas solo se emitían por Socket.IO
- Si el cocinero no estaba conectado, se perdían
- No había forma de recuperar alertas perdidas

### **Solución:**
1. ✅ **Guardar en BD**: Todas las alertas se guardan en BD antes de emitirse
2. ✅ **Carga al conectar**: Cuando el cocinero se conecta, carga alertas pendientes desde BD
3. ✅ **Tiempo real**: Si el cocinero está conectado, recibe la alerta inmediatamente
4. ✅ **Persistencia**: Si el cocinero no está conectado, ve la alerta cuando se conecta

---

## 📊 Flujo de Datos

```
┌─────────┐
│ Mesero  │
└────┬────┘
     │
     │ 1. Crea orden
     ▼
┌─────────────┐
│ Base Datos  │ (Orden guardada)
└────┬────────┘
     │
     │ 2. Envía a cocina
     ▼
┌─────────────┐
│ Cocinero    │ (Ve la orden)
└────┬────────┘
     │
     │ 3. Mesero envía alerta
     ▼
┌─────────────┐
│ Socket.IO   │ ───► Emite a cocineros conectados
└────┬────────┘
     │
     │ 4. Guarda en BD
     ▼
┌─────────────┐
│ Base Datos  │ (Alerta guardada)
└────┬────────┘
     │
     │ 5. Cocinero se conecta
     ▼
┌─────────────┐
│ Cocinero    │ (Carga alertas pendientes)
└─────────────┘
```

---

## 🎯 Respuestas a tus Preguntas

### **¿Desde cuándo puede el mesero enviar alertas?**

**Respuesta**: Desde que la orden está **"enviada a cocina"** (estado "en_preparacion" o similar).

**Flujo:**
1. Mesero crea orden → Estado: "abierta" → **NO puede enviar alertas**
2. Mesero envía orden a cocina → Estado: "en_preparacion" → **SÍ puede enviar alertas**
3. Cocinero ve la orden en su pantalla
4. Mesero puede enviar alertas sobre esa orden

### **¿Puede enviar alertas antes de que el cocinero marque "iniciar"?**

**Respuesta**: **SÍ**, puede enviar alertas desde que la orden está "enviada a cocina", incluso si el cocinero no ha marcado "iniciar" todavía.

**Ejemplo:**
- Mesero envía orden #90 a cocina
- Orden aparece en pantalla del cocinero
- Cocinero aún no ha marcado "iniciar"
- Cliente pregunta: "¿Cuánto falta?"
- Mesero puede enviar alerta: "Demora: Cliente pregunta por orden #90"

### **¿Qué pasa si el cocinero no está conectado?**

**Respuesta**: La alerta se guarda en BD y el cocinero la verá cuando se conecte.

**Flujo:**
1. Mesero envía alerta
2. Backend guarda en BD
3. Backend intenta emitir por Socket.IO
4. Si no hay cocineros conectados → Solo se guarda en BD
5. Cuando el cocinero se conecta → Carga alertas pendientes desde BD
6. Alerta aparece en la UI del cocinero

---

## ✅ Estado Actual del Sistema

### **Funcionalidades Implementadas:**
- ✅ Mesero puede enviar alertas a cocina
- ✅ Alertas se guardan en BD
- ✅ Alertas se emiten en tiempo real a cocineros conectados
- ✅ Cocinero carga alertas pendientes al conectarse
- ✅ Cocinero ve alertas en tiempo real si está conectado
- ✅ Sistema de rooms por estación (tacos, consomes, bebidas)
- ✅ ACK de confirmación al mesero

### **Mejoras Futuras (Opcionales):**
- 🔔 Notificaciones push cuando el cocinero está desconectado
- 📊 Historial de alertas enviadas
- 🔍 Filtros por tipo de alerta en cocinero
- ⏰ Alertas automáticas por tiempo de espera

---

## 🐛 Debugging

### **Logs Importantes:**

**Backend:**
- `KitchenAlerts: Alerta recibida desde mesero`
- `KitchenAlerts: Alerta guardada en BD`
- `KitchenAlerts: Sockets en room:kitchen:all antes de emitir`
- `KitchenAlerts: Alerta emitida a room:kitchen:all`

**Frontend (Cocinero):**
- `📥 Cocinero: Cargando alertas pendientes desde la BD...`
- `🔔 Cocinero: Nueva alerta recibida (kitchen:alert:new)`
- `✅ Cocinero: Alerta agregada (nuevo sistema)`

**Frontend (Mesero):**
- `📤 KitchenAlertsService: Enviando alerta`
- `✅ Alerta confirmada por el backend`

---

## 📝 Resumen Ejecutivo

**El sistema funciona así:**

1. **Mesero crea orden** → No puede enviar alertas todavía
2. **Mesero envía orden a cocina** → Orden aparece en cocinero → **AHORA SÍ puede enviar alertas**
3. **Mesero envía alerta** → Se guarda en BD + Se emite en tiempo real
4. **Si cocinero está conectado** → Recibe alerta inmediatamente
5. **Si cocinero NO está conectado** → Alerta se guarda y se carga cuando se conecta

**Las alertas funcionan desde que la orden está "enviada a cocina", no desde que el cocinero marca "iniciar".**

