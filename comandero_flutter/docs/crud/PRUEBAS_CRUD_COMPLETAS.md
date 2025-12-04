# Guía de Pruebas CRUD Completas

Este documento describe cómo probar todas las funcionalidades CRUD del proyecto por rol.

## Configuración Previa

1. **Backend corriendo**: Asegúrate de que el backend esté corriendo en `http://localhost:3000`
2. **Base de datos**: Verifica que MySQL esté corriendo y la base de datos esté configurada
3. **Frontend**: Ejecuta la aplicación Flutter

## ROL: ADMINISTRADOR

### CRUD de Usuarios ✅
1. **Crear Usuario**:
   - Ir a "Usuarios" → "Agregar Usuario"
   - Llenar formulario: nombre, email, contraseña, rol
   - Verificar en MySQL: `SELECT * FROM usuario WHERE email = '...'`

2. **Leer Usuarios**:
   - Ver lista de usuarios en la pantalla
   - Verificar que se carguen desde el backend

3. **Actualizar Usuario**:
   - Seleccionar usuario → "Editar"
   - Modificar datos
   - Verificar en MySQL: `SELECT * FROM usuario WHERE id = ...`

4. **Eliminar Usuario**:
   - Seleccionar usuario → "Eliminar"
   - Confirmar eliminación
   - Verificar en MySQL que el usuario ya no existe

### CRUD de Productos ✅
1. **Crear Producto**:
   - Ir a "Menú" → "Agregar Producto"
   - Llenar formulario completo
   - Verificar en MySQL: `SELECT * FROM producto WHERE nombre = '...'`

2. **Leer Productos**:
   - Ver lista de productos
   - Filtrar por categoría

3. **Actualizar Producto**:
   - Seleccionar producto → "Editar"
   - Modificar datos
   - Verificar en MySQL

4. **Eliminar Producto**:
   - Seleccionar producto → "Eliminar"
   - Verificar en MySQL

### CRUD de Inventario ✅
1. **Crear Item de Inventario**:
   - Ir a "Inventario" → "Agregar Item"
   - Llenar formulario
   - Verificar en MySQL: `SELECT * FROM inventario WHERE nombre = '...'`

2. **Leer Inventario**:
   - Ver lista de items
   - Filtrar por categoría

3. **Actualizar Item**:
   - Seleccionar item → "Editar"
   - Modificar datos
   - Verificar en MySQL

4. **Eliminar Item**:
   - Seleccionar item → "Eliminar"
   - Verificar en MySQL

### CRUD de Categorías ✅
1. **Crear Categoría**:
   - Ir a "Menú" → "Agregar Categoría"
   - Ingresar nombre
   - Verificar en MySQL: `SELECT * FROM categoria WHERE nombre = '...'`

2. **Leer Categorías**:
   - Ver lista de categorías en el menú

3. **Actualizar Categoría**:
   - Seleccionar categoría → "Editar"
   - Modificar nombre
   - Verificar en MySQL

4. **Eliminar Categoría**:
   - Seleccionar categoría → "Eliminar"
   - Solo si no tiene productos asociados
   - Verificar en MySQL

### CRUD de Mesas ✅
1. **Crear Mesa**:
   - Ir a "Mesas" → "Agregar Mesa"
   - Llenar formulario
   - Verificar en MySQL: `SELECT * FROM mesa WHERE codigo = '...'`

2. **Leer Mesas**:
   - Ver lista de mesas
   - Ver estados

3. **Actualizar Mesa**:
   - Seleccionar mesa → "Editar"
   - Modificar datos
   - Verificar en MySQL

4. **Eliminar Mesa**:
   - Seleccionar mesa → "Eliminar"
   - Verificar en MySQL

## ROL: MESERO

### CRUD de Órdenes ✅
1. **Crear Orden**:
   - Seleccionar mesa
   - Agregar productos al carrito
   - "Enviar a Cocina"
   - Verificar en MySQL: `SELECT * FROM orden WHERE mesa_id = ...`
   - Verificar items: `SELECT * FROM orden_item WHERE orden_id = ...`

2. **Leer Órdenes**:
   - Ver historial de órdenes por mesa
   - Ver estado de órdenes

3. **Actualizar Orden**:
   - Agregar más items a una orden existente
   - Modificar estado
   - Verificar en MySQL

4. **Enviar al Cajero**:
   - Desde el carrito o desde historial
   - Crear bill para el cajero
   - Verificar que se cree el bill con `ordenId` correcto

### Gestión de Mesas ✅
1. **Cambiar Estado de Mesa**:
   - Seleccionar mesa
   - Cambiar estado (Libre, Ocupada, Limpieza, Reservada)
   - Verificar en MySQL: `SELECT * FROM mesa WHERE id = ...`

## ROL: COCINERO

### CRUD de Órdenes ✅
1. **Leer Órdenes**:
   - Ver órdenes pendientes
   - Filtrar por estación
   - Verificar que se carguen desde el backend

2. **Actualizar Estado de Orden**:
   - Cambiar estado: Pendiente → En Preparación → Listo
   - Verificar en MySQL: `SELECT * FROM orden WHERE id = ...`
   - Verificar estado: `SELECT * FROM estado_orden WHERE id = ...`

3. **Marcar Orden como Lista**:
   - Cambiar estado a "Listo"
   - Verificar en MySQL

## ROL: CAJERO

### CRUD de Pagos ✅
1. **Leer Bills**:
   - Ver bills pendientes
   - Verificar que se carguen desde el backend (órdenes pendientes)

2. **Crear Pago**:
   - Seleccionar bill
   - Procesar pago (Efectivo, Tarjeta, Mixto)
   - Verificar en MySQL: `SELECT * FROM pago WHERE orden_id = ...`
   - Verificar que el bill se marque como pagado

3. **Registrar Propina**:
   - Agregar propina al pago
   - Verificar en MySQL: `SELECT * FROM propina WHERE orden_id = ...`

## ROL: CAPITÁN

### Gestión de Mesas ✅
1. **Leer Mesas**:
   - Ver todas las mesas
   - Ver estados
   - Verificar que se carguen desde el backend

2. **Cambiar Estado de Mesa**:
   - Seleccionar mesa
   - Cambiar estado
   - Verificar en MySQL

## Verificaciones Generales

### En MySQL Workbench:

```sql
-- Verificar usuarios creados
SELECT * FROM usuario ORDER BY creado_en DESC;

-- Verificar productos creados
SELECT * FROM producto ORDER BY creado_en DESC;

-- Verificar inventario
SELECT * FROM inventario ORDER BY creado_en DESC;

-- Verificar categorías
SELECT * FROM categoria ORDER BY creado_en DESC;

-- Verificar mesas
SELECT * FROM mesa ORDER BY creado_en DESC;

-- Verificar órdenes
SELECT * FROM orden ORDER BY creado_en DESC;

-- Verificar items de orden
SELECT * FROM orden_item ORDER BY creado_en DESC;

-- Verificar pagos
SELECT * FROM pago ORDER BY fecha_pago DESC;

-- Verificar propinas
SELECT * FROM propina ORDER BY fecha_pago DESC;
```

## Problemas Corregidos

1. ✅ **BillRepository.loadBills()**: Ahora carga órdenes pendientes desde el backend
2. ✅ **Duplicación de Bills**: Corregido para evitar bills duplicados usando `ordenId`
3. ✅ **sendToCashier**: Mejorado para obtener órdenes del backend si no hay carrito
4. ✅ **Categorías CRUD**: Conectado completamente al backend
5. ✅ **Errores de Linter**: Corregidos todos los errores de compilación
6. ✅ **Async/Await**: Todas las operaciones CRUD ahora son asíncronas correctamente

## Notas Importantes

- Todas las operaciones CRUD ahora están conectadas al backend
- Los datos se sincronizan automáticamente después de cada operación
- Los errores se muestran al usuario mediante SnackBars
- Se muestran indicadores de carga durante las operaciones asíncronas

