# 📋 AUDITORÍA INICIAL — Comandero Flutter
**Fecha:** ${new Date().toLocaleDateString('es-ES')}  
**Versión Flutter:** Analizando proyecto actual  
**Objetivo:** Mapear estado actual vs. requerimientos por PNG

---

## 🔍 RESUMEN EJECUTIVO

### Estado General
- ✅ **Estructura base:** Organización por roles correcta
- ⚠️ **Guards de acceso:** Implementación parcial (falta guard web admin)
- ❌ **Deprecations:** 29 warnings detectados
- ❌ **Assets PNG:** Carpeta `assets/ui_reference/` vacía (sin referencia visual)
- ⚠️ **Responsivo:** Implementado pero requiere validación vs. PNG

### Porcentaje de Completitud Estimado
- **Splash/Login:** 85% (completo, requiere ajustes visuales)
- **Mesero:** 70% (estructura OK, faltan detalles funcionales)
- **Cocinero:** 65% (vistas principales OK, falta refinamiento)
- **Cajero:** 70% (funcionalidades OK, faltan detalles)
- **Capitán:** 60% (estructura básica, falta completitud)
- **Admin App:** 75% (dashboard OK, vistas web completas)
- **Admin Web:** 80% (vistas web OK, falta guard de acceso)

---

## 📱 MAPA DE PANTALLAS POR ROL

### 1. MESERO (`lib/views/mesero/`)

#### ✅ HECHO:
- `mesero_app.dart` - App principal con navegación
- `floor_view.dart` - Plano de mesas con estados y ocupación
- `table_view.dart` - Detalle de mesa con historial
- `menu_view.dart` - Catálogo de productos con categorías
- `cart_view.dart` - Carrito con división de cuentas
- `order_history_view.dart` - Historial de pedidos
- `alert_to_kitchen_modal.dart` - Modal para alertas a cocina

#### ⚠️ PARCIAL:
- **División/junción de cuentas:** Implementado básicamente, requiere validación funcional
- **Modificadores y notas:** Presente pero falta validación de alergias
- **Filtros de productos:** Implementado, requiere ajustes visuales
- **Enviar a cocina:** Implementado, falta integración con KDS real

#### ❌ FALTANTE:
- Vista de "Para llevar" dedicada (actualmente en cart_view)
- Modal de confirmación de envío a cocina
- Vista de estados de pedidos en tiempo real
- Alertas visuales de pedidos pendientes

---

### 2. COCINERO (`lib/views/cocinero/`)

#### ✅ HECHO:
- `cocinero_app.dart` - App principal con filtros
- Lista de pedidos en tiempo real
- Estados de pedidos (pendiente, en preparación, listo)
- Filtros por estación, estado, para llevar

#### ⚠️ PARCIAL:
- `ingredient_consumption_view.dart` - Vista creada pero funcionalidad básica
- `critical_notes_view.dart` - Vista creada, falta integración
- `station_management_view.dart` - Vista creada, funcionalidad básica
- `staff_management_view.dart` - Vista creada, funcionalidad básica
- **Streams simulados:** Implementado, requiere validación de actualización en tiempo real

#### ❌ FALTANTE:
- Sonidos/notificaciones de nuevos pedidos
- Timer visual por pedido
- Vista detallada de notas críticas destacadas
- Integración con consumo real de ingredientes

---

### 3. CAJERO (`lib/views/cajero/`)

#### ✅ HECHO:
- `cajero_app.dart` - App principal
- `payment_processing_view.dart` - Procesamiento de pagos (efectivo/tarjeta)
- `cash_closure_view.dart` - Cierre de caja
- `cash_management_view.dart` - Gestión de efectivo
- `sales_reports_view.dart` - Reportes de ventas
- Modal de pago con captura de voucher (tarjeta)
- Propinas y notas

#### ⚠️ PARCIAL:
- **Ticket/impresión:** Implementado básicamente con printing, falta validación
- **Cierre de caja:** Funcionalidad presente, falta validación de totales
- **Reportes:** Vista creada, falta completar gráficas

#### ❌ FALTANTE:
- Vista de impresión previa de ticket
- Generación de PDF de tickets
- Validación de voucher administrativo completo
- Historial de cierres anteriores

---

### 4. CAPITÁN (`lib/views/captain/`)

#### ✅ HECHO:
- `captain_app.dart` - App principal
- Vista de alertas con prioridades
- Estadísticas del día
- Filtros de mesas y órdenes
- Tabs para mesas y órdenes

#### ⚠️ PARCIAL:
- **Reasignación de mesas:** Estructura presente, falta implementación completa
- **Envío de alertas:** Funcionalidad básica, falta integración con módulos destino
- **Logs de auditoría:** Simulados localmente, falta persistencia

#### ❌ FALTANTE:
- Modal de reasignación de mesa a mesero
- Vista de alertas enviadas
- Integración real con módulos de mesero/cocina
- Dashboard de supervisión con gráficas

---

### 5. ADMINISTRADOR — App Móvil/Tablet (`lib/views/admin/`)

#### ✅ HECHO:
- `admin_app.dart` - App principal con bottom nav
- Dashboard con estadísticas
- Acciones rápidas (usuarios, inventario, menú, mesas)
- Alertas de sistema (stock bajo/sin stock)
- Gráficos básicos de ventas

#### ⚠️ PARCIAL:
- **Gestión de Mesas:** Botón presente, falta vista dedicada
- **Gestión de Menú:** Botón presente, falta vista dedicada
- **Inventario:** Botón presente, funcionalidad básica
- **Usuarios:** Botón presente, falta vista dedicada
- **Filtros de Cocina:** Botón presente, falta navegación
- **Gestión de Tickets:** No implementado
- **Revisión de Cierres:** No implementado

#### ❌ FALTANTE:
- Vistas completas de gestión por sección:
  - Gestión de Mesas (CRUD)
  - Gestión de Menú (CRUD)
  - Gestión de Usuarios (alta/edición/bloqueo)
  - Gestión de Tickets
  - Revisión de Cierres de Cajeros
- Navegación completa entre secciones

---

### 6. ADMINISTRADOR — Web (`lib/views/admin/web/`)

#### ✅ HECHO:
- `admin_web_app.dart` - App web con sidebar
- `inventory_web_view.dart` - Vista completa de inventario con CRUD
- `cash_closures_web_view.dart` - Vista de cortes de caja con gráficas
- `real_time_sales_web_view.dart` - Ventas en tiempo real con gráficas
- `users_reports_web_view.dart` - Usuarios y reportes con gráficas
- Dashboard web con estadísticas

#### ⚠️ PARCIAL:
- **Guard de acceso web:** ❌ **CRÍTICO** - No existe verificación `kIsWeb && userRole == 'admin'`
- **Acceso denegado:** No implementado para roles no-admin en web
- **Navegación web:** Completa pero falta guard en ruta `/admin-web`

#### ❌ FALTANTE:
- Guard de acceso en `main.dart` para ruta `/admin-web`
- Vista de "Acceso Denegado" para usuarios no-admin en web
- Redirección automática si usuario no-admin intenta acceder a `/admin-web`

---

## 🎨 GAP VISUAL (vs. PNG)

### Problemas Detectados:

1. **Assets PNG Vacías:**
   - ❌ Carpeta `assets/ui_reference/` existe pero está vacía
   - **Impacto:** No hay referencia visual para comparar diseño
   - **Acción requerida:** Agregar PNGs de referencia o documentar diseño esperado

2. **Colores y Tipografías:**
   - ✅ `app_colors.dart` define esquema de colores
   - ✅ Google Fonts (Roboto) configurada
   - ⚠️ Requiere validación contra PNG para ajustes finos

3. **Espaciados y Paddings:**
   - ✅ Responsivo implementado con `LayoutBuilder`
   - ⚠️ Valores específicos pueden requerir ajuste según PNG

4. **Estados Visuales:**
   - ✅ Estados de mesas implementados (colores)
   - ✅ Badges y etiquetas de estado presentes
   - ⚠️ Requiere validación visual contra PNG

---

## 🛡️ NAVEGACIÓN/GUARDS ACTUALES

### ✅ Implementado:
- **Login guard:** Redirige a `/login` si no está autenticado
- **Splash redirect:** Redirige a `/home` si ya está logueado
- **Routing por rol:** `/home` redirige según `userRole` a:
  - `MeseroApp` para `mesero`
  - `CocineroApp` para `cocinero`
  - `CajeroApp` para `cajero`
  - `CaptainApp` para `capitan`
  - `AdminApp` para `admin`

### ❌ Faltante (CRÍTICO):

#### **GUARD WEB ADMIN:**
```dart
// PROBLEMA: En main.dart, ruta /admin-web NO tiene guard
GoRoute(
  path: '/admin-web',
  builder: (context, state) {
    // ⚠️ FALTA: Verificación kIsWeb && userRole == 'admin'
    return const AdminWebApp();
  },
),
```

**Acción requerida:**
- Agregar verificación `kIsWeb && userRole == 'admin'` en ruta `/admin-web`
- Redirigir a vista "Acceso Denegado" si no cumple condiciones
- Bloquear acceso de roles no-admin a rutas web admin

---

## 🔧 PROBLEMAS TÉCNICOS DETECTADOS

### 1. Deprecations (29 issues)

#### `value` → `initialValue` en TextFormField (24 casos)
**Archivos afectados:**
- `cash_closures_web_view.dart` (4)
- `inventory_web_view.dart` (4)
- `users_reports_web_view.dart` (2)
- `cash_closure_view.dart` (2)
- `cash_management_view.dart` (2)
- `payment_processing_view.dart` (2)
- `sales_reports_view.dart` (2)
- `staff_management_view.dart` (2)
- `alert_to_kitchen_modal.dart` (2)

**Corrección:**
```dart
// ANTES:
TextFormField(value: someValue, ...)

// DESPUÉS:
TextFormField(initialValue: someValue, ...)
```

#### `groupValue` y `onChanged` en Radio (4 casos)
**Archivo:** `alert_to_kitchen_modal.dart`

**Corrección:**
```dart
// ANTES:
Radio(
  groupValue: selectedValue,
  onChanged: (value) => ...,
)

// DESPUÉS:
// Usar RadioGroup (nuevo API de Flutter 3.32+)
```

#### `activeColor` → `activeThumbColor` en Switch (1 caso)
**Archivo:** `cart_view.dart`

**Corrección:**
```dart
// ANTES:
Switch(activeColor: color, ...)

// DESPUÉS:
Switch(activeThumbColor: color, ...)
```

#### `avoid_print` (1 caso)
**Archivo:** `alert_to_kitchen_modal.dart:322`

**Corrección:** Eliminar `print()` o usar logging apropiado

#### `prefer_is_empty` (1 caso)
**Archivo:** `sales_reports_view.dart:194`

**Corrección:**
```dart
// ANTES:
if (list.length > 0)

// DESPUÉS:
if (list.isNotEmpty)
```

---

### 2. Accesibilidad
- ⚠️ No se detectaron problemas específicos de accesibilidad en análisis rápido
- **Recomendación:** Revisar con herramientas de accesibilidad (semantic labels, contrast ratios)

### 3. Responsivo
- ✅ `LayoutBuilder` implementado en todas las vistas principales
- ✅ Breakpoints consistentes: `> 600` (tablet), `> 900` (desktop)
- ⚠️ Requiere validación en dispositivos reales

---

## 📋 LISTA PRIORIZADA DE CORRECCIONES

### 🔴 CRÍTICO (Bloquea Etapa 1)
1. **Agregar guard web admin** en `main.dart` ruta `/admin-web`
   - Verificar `kIsWeb && userRole == 'admin'`
   - Redirigir a "Acceso Denegado" si no cumple
   - Archivo: `lib/main.dart`

2. **Corregir deprecations críticos**
   - `value` → `initialValue` en TextFormField (24 casos)
   - `groupValue` → RadioGroup en Radio (4 casos)
   - `activeColor` → `activeThumbColor` en Switch (1 caso)

### 🟠 ALTO (Requiere antes de Etapa 6)
3. **Completar vistas faltantes de Admin App móvil/tablet:**
   - Gestión de Mesas (CRUD)
   - Gestión de Menú (CRUD)
   - Gestión de Usuarios (alta/edición/bloqueo)
   - Gestión de Tickets
   - Revisión de Cierres de Cajeros

4. **Implementar funcionalidades faltantes:**
   - Modal de confirmación de envío a cocina (Mesero)
   - Vista de "Para llevar" dedicada (Mesero)
   - Timer visual por pedido (Cocinero)
   - Vista de impresión previa de ticket (Cajero)
   - Modal de reasignación de mesa (Capitán)

### 🟡 MEDIO (Mejoras funcionales)
5. **Refinar funcionalidades parciales:**
   - Validación de alergias en modificadores
   - Integración real con KDS (simulada actualmente)
   - Persistencia de logs de auditoría (Capitán)
   - Validación de totales en cierre de caja

6. **Validación visual:**
   - Comparar diseño contra PNG (cuando estén disponibles)
   - Ajustar espaciados, tipografías, colores según PNG
   - Validar estados visuales (badges, colores, iconos)

### 🟢 BAJO (Limpieza y optimización)
7. **Limpieza de código:**
   - Eliminar `print()` statements
   - Agregar comentarios donde falten
   - Optimizar imports no usados

8. **Documentación:**
   - Agregar README con instrucciones de uso
   - Documentar estructura de archivos
   - Documentar flujos principales

---

## 📊 ARCHIVOS POR ROL (Resumen)

### Mesero:
- ✅ `mesero_app.dart`
- ✅ `floor_view.dart`
- ✅ `table_view.dart`
- ✅ `menu_view.dart`
- ✅ `cart_view.dart`
- ✅ `order_history_view.dart`
- ✅ `alert_to_kitchen_modal.dart`

### Cocinero:
- ✅ `cocinero_app.dart`
- ⚠️ `ingredient_consumption_view.dart` (parcial)
- ⚠️ `critical_notes_view.dart` (parcial)
- ⚠️ `station_management_view.dart` (parcial)
- ⚠️ `staff_management_view.dart` (parcial)

### Cajero:
- ✅ `cajero_app.dart`
- ✅ `payment_processing_view.dart`
- ✅ `cash_closure_view.dart`
- ✅ `cash_management_view.dart`
- ✅ `sales_reports_view.dart`

### Capitán:
- ✅ `captain_app.dart`

### Admin App:
- ✅ `admin_app.dart`
- ❌ Gestión de Mesas (falta)
- ❌ Gestión de Menú (falta)
- ❌ Gestión de Usuarios (falta)
- ❌ Gestión de Tickets (falta)
- ❌ Revisión de Cierres (falta)

### Admin Web:
- ✅ `admin_web_app.dart`
- ✅ `inventory_web_view.dart`
- ✅ `cash_closures_web_view.dart`
- ✅ `real_time_sales_web_view.dart`
- ✅ `users_reports_web_view.dart`

---

## ✅ CRITERIOS DE ACEPTACIÓN PARA ETAPA 1

### Antes de pasar a Etapa 1, se requiere:

1. ✅ **Guard web admin implementado:**
   - `kIsWeb && userRole == 'admin'` verificado
   - Vista "Acceso Denegado" para no-admin
   - Redirección automática

2. ✅ **Deprecations corregidos:**
   - Todos los `value` → `initialValue`
   - Todos los `groupValue` → RadioGroup
   - `activeColor` → `activeThumbColor`
   - `print()` eliminados

3. ✅ **Splash/Login funcional:**
   - Redirección por rol funciona
   - Guards básicos funcionando

4. ⚠️ **Validación visual:**
   - Requiere PNGs de referencia para validar

---

## 🚨 BLOQUEADORES IDENTIFICADOS

1. **Sin PNGs de referencia:**
   - No se pueden validar ajustes visuales
   - **Acción:** Solicitar PNGs o documentar diseño esperado

2. **Guard web admin faltante:**
   - Riesgo de seguridad (acceso no autorizado)
   - **Acción:** Implementar inmediatamente

3. **Vistas admin móvil faltantes:**
   - Bloquea Etapa 6 (Admin App móvil/tablet)
   - **Acción:** Crear vistas antes de Etapa 6

---

## 📝 OBSERVACIONES FINALES

1. **Estructura del proyecto:** ✅ Excelente organización por roles y módulos
2. **Código base:** ✅ Limpio y bien estructurado
3. **Responsivo:** ✅ Implementado consistentemente
4. **Estado:** ⚠️ Requiere correcciones técnicas antes de continuar
5. **Funcionalidad:** ⚠️ Completa en web admin, parcial en móvil/tablet

---

## 🎯 SIGUIENTE PASO

**Esperando tu OK para:**
1. Corregir guard web admin
2. Corregir deprecations
3. Continuar con Etapa 1 (Tema global + Navegación + Guards)

**¿Puedo continuar con Etapa 1?**
- ❌ **NO** hasta que se corrija guard web admin y deprecations críticos

---

**Generado por:** Auditoría automática  
**Última actualización:** ${new Date().toISOString()}
