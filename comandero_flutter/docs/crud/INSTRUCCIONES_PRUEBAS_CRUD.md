# Instrucciones para Probar el CRUD Completo

## 🎯 Objetivo

Verificar que todas las operaciones CRUD funcionen correctamente desde el frontend y que los datos se reflejen en MySQL Workbench.

---

## 📋 Preparación

1. **Asegúrate de que el backend esté corriendo**:
   ```powershell
   cd comandero_flutter/backend
   npm run dev
   ```

2. **Asegúrate de que MySQL esté corriendo**:
   ```powershell
   # Verificar servicio MySQL81
   Get-Service MySQL81
   ```

3. **Abre MySQL Workbench** y conéctate a la base de datos

4. **Abre el frontend** en Chrome:
   ```powershell
   cd comandero_flutter
   flutter run -d chrome
   ```

---

## ✅ Checklist de Pruebas por Rol

### 👤 ADMINISTRADOR

#### 1. Usuarios
- [ ] **Crear usuario**:
  - Ir a "Usuarios" → "Agregar Usuario"
  - Llenar formulario y crear
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM usuario ORDER BY creado_en DESC LIMIT 1;
    ```

- [ ] **Actualizar usuario**:
  - Seleccionar usuario → "Editar"
  - Modificar datos y guardar
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM usuario WHERE id = ?;
    ```

- [ ] **Eliminar usuario**:
  - Seleccionar usuario → "Eliminar"
  - Confirmar eliminación
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM usuario WHERE activo = 0;
    ```

#### 2. Productos
- [ ] **Crear producto**:
  - Ir a "Menú" → "Agregar Producto"
  - Llenar formulario y crear
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM producto ORDER BY creado_en DESC LIMIT 1;
    ```

- [ ] **Actualizar producto**:
  - Seleccionar producto → "Editar"
  - Modificar datos y guardar
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM producto WHERE id = ?;
    ```

- [ ] **Eliminar producto**:
  - Seleccionar producto → "Eliminar"
  - Confirmar eliminación
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM producto WHERE activo = 0;
    ```

#### 3. Inventario
- [ ] **Crear item de inventario**:
  - Ir a "Inventario" → "Agregar Item"
  - Llenar formulario y crear
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM inventario_item ORDER BY creado_en DESC LIMIT 1;
    ```

- [ ] **Actualizar item de inventario**:
  - Seleccionar item → "Editar"
  - Modificar datos y guardar
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM inventario_item WHERE id = ?;
    ```

- [ ] **Eliminar item de inventario**:
  - Seleccionar item → "Eliminar"
  - Confirmar eliminación
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM inventario_item WHERE activo = 0;
    ```

#### 4. Mesas
- [ ] **Crear mesa**:
  - Ir a "Mesas" → "Agregar Mesa"
  - Llenar formulario y crear
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM mesa ORDER BY creado_en DESC LIMIT 1;
    ```

- [ ] **Actualizar mesa**:
  - Seleccionar mesa → "Editar"
  - Modificar datos y guardar
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM mesa WHERE id = ?;
    ```

- [ ] **Eliminar mesa**:
  - Seleccionar mesa → "Eliminar"
  - Confirmar eliminación
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM mesa WHERE activo = 0;
    ```

#### 5. Categorías
- [ ] **Crear categoría**:
  - Ir a "Menú" → "Agregar Categoría"
  - Ingresar nombre y crear
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM categoria ORDER BY creado_en DESC LIMIT 1;
    ```

- [ ] **Actualizar categoría**:
  - Seleccionar categoría → "Editar" (si está disponible)
  - Modificar nombre y guardar
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM categoria WHERE id = ?;
    ```

- [ ] **Eliminar categoría**:
  - Seleccionar categoría → "Eliminar" (si está disponible)
  - Confirmar eliminación
  - **Verificar en MySQL**:
    ```sql
    SELECT * FROM categoria WHERE activo = 0;
    ```

---

### 🍽️ MESERO

#### 1. Crear Orden
- [ ] **Crear orden para mesa**:
  - Seleccionar mesa
  - Agregar productos al carrito
  - Enviar a cocina
  - **Verificar en MySQL**:
    ```sql
    SELECT o.*, m.codigo AS mesa_codigo 
    FROM orden o 
    LEFT JOIN mesa m ON m.id = o.mesa_id 
    ORDER BY o.creado_en DESC LIMIT 1;
    ```
  - **Verificar items**:
    ```sql
    SELECT oi.*, p.nombre AS producto_nombre 
    FROM orden_item oi 
    JOIN producto p ON p.id = oi.producto_id 
    WHERE oi.orden_id = ? 
    ORDER BY oi.id;
    ```

#### 2. Cambiar Estado de Mesa
- [ ] **Cambiar estado de mesa**:
  - Seleccionar mesa
  - Cambiar estado (Libre, Ocupada, En Limpieza, Reservada)
  - **Verificar en MySQL**:
    ```sql
    SELECT m.*, em.nombre AS estado_nombre 
    FROM mesa m 
    JOIN estado_mesa em ON em.id = m.estado_mesa_id 
    WHERE m.id = ?;
    ```

#### 3. Enviar Cuenta a Cajero
- [ ] **Enviar cuenta a cajero**:
  - Seleccionar mesa con orden
  - Enviar cuenta al cajero
  - **Verificar que el bill se cree correctamente** (se guarda en `BillRepository`)

---

### 👨‍🍳 COCINERO

#### 1. Cambiar Estado de Orden
- [ ] **Iniciar preparación**:
  - Seleccionar orden pendiente
  - Clic en "Iniciar"
  - **Verificar en MySQL**:
    ```sql
    SELECT o.*, eo.nombre AS estado_nombre 
    FROM orden o 
    JOIN estado_orden eo ON eo.id = o.estado_orden_id 
    WHERE o.id = ?;
    ```

- [ ] **Marcar como listo**:
  - Seleccionar orden en preparación
  - Clic en "Listo"
  - **Verificar en MySQL**:
    ```sql
    SELECT o.*, eo.nombre AS estado_nombre 
    FROM orden o 
    JOIN estado_orden eo ON eo.id = o.estado_orden_id 
    WHERE o.id = ?;
    ```

#### 2. Cancelar Orden
- [ ] **Cancelar orden**:
  - Seleccionar orden
  - Cancelar orden (si está disponible en la UI)
  - **Verificar en MySQL**:
    ```sql
    SELECT o.*, eo.nombre AS estado_nombre 
    FROM orden o 
    JOIN estado_orden eo ON eo.id = o.estado_orden_id 
    WHERE eo.nombre LIKE '%cancel%' 
    ORDER BY o.actualizado_en DESC LIMIT 1;
    ```

---

### 💰 CAJERO

#### 1. Procesar Pago en Efectivo
- [ ] **Procesar pago en efectivo**:
  - Seleccionar bill pendiente
  - Clic en "Cobrar" → "Efectivo"
  - Ingresar monto recibido
  - Procesar pago
  - **Verificar en MySQL**:
    ```sql
    SELECT p.*, fp.nombre AS forma_pago, o.mesa_id 
    FROM pago p 
    JOIN forma_pago fp ON fp.id = p.forma_pago_id 
    JOIN orden o ON o.id = p.orden_id 
    ORDER BY p.creado_en DESC LIMIT 1;
    ```

#### 2. Procesar Pago con Tarjeta
- [ ] **Procesar pago con tarjeta**:
  - Seleccionar bill pendiente
  - Clic en "Cobrar" → "Tarjeta"
  - Ingresar datos de tarjeta
  - Procesar pago
  - **Verificar en MySQL**:
    ```sql
    SELECT p.*, fp.nombre AS forma_pago, o.mesa_id 
    FROM pago p 
    JOIN forma_pago fp ON fp.id = p.forma_pago_id 
    JOIN orden o ON o.id = p.orden_id 
    WHERE fp.nombre LIKE '%tarjeta%' 
    ORDER BY p.creado_en DESC LIMIT 1;
    ```

#### 3. Registrar Propina
- [ ] **Registrar propina**:
  - Al procesar pago, agregar propina
  - Procesar pago con propina
  - **Verificar en MySQL**:
    ```sql
    SELECT pr.*, o.mesa_id 
    FROM propina pr 
    JOIN orden o ON o.id = pr.orden_id 
    ORDER BY pr.creado_en DESC LIMIT 1;
    ```

---

### 👔 CAPITÁN

#### 1. Cambiar Estado de Mesa
- [ ] **Cambiar estado de mesa**:
  - Seleccionar mesa
  - Cambiar estado
  - **Verificar en MySQL**:
    ```sql
    SELECT m.*, em.nombre AS estado_nombre 
    FROM mesa m 
    JOIN estado_mesa em ON em.id = m.estado_mesa_id 
    WHERE m.id = ?;
    ```

---

## 🔍 Consultas SQL de Verificación Rápida

### Ver todos los registros recientes:
```sql
-- Último usuario creado
SELECT * FROM usuario ORDER BY creado_en DESC LIMIT 1;

-- Último producto creado
SELECT * FROM producto ORDER BY creado_en DESC LIMIT 1;

-- Último item de inventario creado
SELECT * FROM inventario_item ORDER BY creado_en DESC LIMIT 1;

-- Última mesa creada
SELECT * FROM mesa ORDER BY creado_en DESC LIMIT 1;

-- Última categoría creada
SELECT * FROM categoria ORDER BY creado_en DESC LIMIT 1;

-- Última orden creada
SELECT o.*, m.codigo AS mesa_codigo 
FROM orden o 
LEFT JOIN mesa m ON m.id = o.mesa_id 
ORDER BY o.creado_en DESC LIMIT 1;

-- Último pago registrado
SELECT p.*, fp.nombre AS forma_pago 
FROM pago p 
JOIN forma_pago fp ON fp.id = p.forma_pago_id 
ORDER BY p.creado_en DESC LIMIT 1;

-- Última propina registrada
SELECT * FROM propina ORDER BY creado_en DESC LIMIT 1;
```

### Ver conteo de registros:
```sql
SELECT 
    'usuario' AS tabla, COUNT(*) AS total FROM usuario
UNION ALL
SELECT 'producto' AS tabla, COUNT(*) AS total FROM producto
UNION ALL
SELECT 'inventario_item' AS tabla, COUNT(*) AS total FROM inventario_item
UNION ALL
SELECT 'mesa' AS tabla, COUNT(*) AS total FROM mesa
UNION ALL
SELECT 'categoria' AS tabla, COUNT(*) AS total FROM categoria
UNION ALL
SELECT 'orden' AS tabla, COUNT(*) AS total FROM orden
UNION ALL
SELECT 'orden_item' AS tabla, COUNT(*) AS total FROM orden_item
UNION ALL
SELECT 'pago' AS tabla, COUNT(*) AS total FROM pago
UNION ALL
SELECT 'propina' AS tabla, COUNT(*) AS total FROM propina;
```

---

## ⚠️ Errores Comunes y Soluciones

### Error: "No se pudo conectar al servidor"
**Solución**: Verificar que el backend esté corriendo en `http://localhost:3000`

### Error: "El backend no retornó el campo 'data'"
**Solución**: Verificar que el backend esté respondiendo correctamente. Revisar logs del backend.

### Error: "ID de orden inválido"
**Solución**: Verificar que el formato del ID sea correcto (número entero)

### Error: "Estado no encontrado"
**Solución**: Verificar que los estados existan en la base de datos:
```sql
SELECT * FROM estado_orden;
SELECT * FROM estado_mesa;
```

### Error: "Mesa no encontrada"
**Solución**: Verificar que la mesa exista en la base de datos:
```sql
SELECT * FROM mesa WHERE codigo = ?;
```

---

## 📝 Notas

1. **Después de cada operación CRUD**, verifica inmediatamente en MySQL Workbench
2. **Si encuentras un error**, anótalo y verifica los logs del backend
3. **Asegúrate de refrescar MySQL Workbench** después de cada operación (F5 o clic derecho → Refresh)
4. **Verifica que los timestamps** (`creado_en`, `actualizado_en`) se actualicen correctamente

---

## ✅ Criterios de Éxito

Una operación CRUD se considera exitosa si:
1. ✅ No hay errores en la consola del frontend
2. ✅ No hay errores en los logs del backend
3. ✅ El dato aparece en MySQL Workbench después de crear
4. ✅ El dato se actualiza en MySQL Workbench después de actualizar
5. ✅ El dato se marca como inactivo o se elimina en MySQL Workbench después de eliminar
6. ✅ Los timestamps se actualizan correctamente

---

**Última actualización**: 2024-01-XX
**Versión**: 1.0.0

