# Plan de Trabajo: CRUD Completo por Etapas

## 📋 Resumen

Este documento detalla el plan de trabajo para completar todas las operaciones CRUD en todos los roles del proyecto, asegurando que todas las operaciones se reflejen correctamente en la base de datos MySQL.

## ✅ Estado Actual

### Administrador
- ✅ **Usuarios**: CRUD completo funcionando y conectado al backend
- ✅ **Productos**: CRUD completo conectado al backend
- ✅ **Inventario**: CRUD completo conectado al backend
- ✅ **Mesas**: CRUD completo conectado al backend
- ✅ **Categorías**: CRUD completo conectado al backend (RECIÉN COMPLETADO)

### Mesero
- ✅ **Cargar mesas**: Conectado al backend
- ✅ **Cambiar estado de mesa**: Conectado al backend
- ✅ **Crear orden**: Conectado al backend
- ⚠️ **Enviar a cajero**: Parcialmente conectado (necesita verificación)

### Cocinero
- ✅ **Cargar órdenes**: Conectado al backend
- ✅ **Cambiar estado de orden**: Conectado al backend
- ⚠️ **Cancelar orden**: Necesita verificación

### Cajero
- ✅ **Cargar bills**: Conectado al backend
- ⚠️ **Procesar pago**: Parcialmente conectado (necesita verificación)
- ⚠️ **Registrar propina**: Necesita verificación

### Capitán
- ✅ **Cargar mesas**: Conectado al backend
- ✅ **Cambiar estado de mesa**: Conectado al backend
- ⚠️ **Reasignar mesa**: Solo local, no conectado al backend

---

## 🎯 ETAPAS DE TRABAJO

### ETAPA 1: Completar CRUD de Administrador ✅
**Estado**: COMPLETADA

**Tareas realizadas**:
1. ✅ Conectar crear categoría al backend
2. ✅ Conectar actualizar categoría al backend
3. ✅ Conectar eliminar categoría al backend
4. ✅ Actualizar vista para manejar métodos async

**Verificación**:
- [x] Crear categoría desde frontend → Verificar en MySQL
- [x] Actualizar categoría desde frontend → Verificar en MySQL
- [x] Eliminar categoría desde frontend → Verificar en MySQL

---

### ETAPA 2: Completar CRUD de Mesero
**Estado**: EN PROGRESO

**Tareas a realizar**:
1. Verificar que `sendOrderToKitchen` guarde correctamente en BD
2. Verificar que `sendToCashier` cree correctamente el bill en BD
3. Verificar que los cambios de estado de mesa se reflejen en BD
4. Probar todas las operaciones desde el frontend

**Verificación**:
- [ ] Crear orden desde frontend → Verificar en MySQL (tabla `orden` y `orden_item`)
- [ ] Cambiar estado de mesa → Verificar en MySQL (tabla `mesa`)
- [ ] Enviar orden a cajero → Verificar que se cree bill correctamente

---

### ETAPA 3: Completar CRUD de Cocinero
**Estado**: PENDIENTE

**Tareas a realizar**:
1. Verificar que `updateOrderStatus` actualice correctamente en BD
2. Verificar que cancelar orden funcione correctamente
3. Probar todas las operaciones desde el frontend

**Verificación**:
- [ ] Cambiar estado de orden → Verificar en MySQL (tabla `orden`)
- [ ] Cancelar orden → Verificar en MySQL (tabla `orden`)

---

### ETAPA 4: Completar CRUD de Cajero
**Estado**: PENDIENTE

**Tareas a realizar**:
1. Verificar que `processPayment` guarde correctamente en BD
2. Verificar que `registrarPropina` guarde correctamente en BD
3. Verificar que los bills se actualicen correctamente después del pago
4. Probar todas las operaciones desde el frontend

**Verificación**:
- [ ] Procesar pago en efectivo → Verificar en MySQL (tabla `pago`)
- [ ] Procesar pago con tarjeta → Verificar en MySQL (tabla `pago`)
- [ ] Registrar propina → Verificar en MySQL (tabla `propina`)
- [ ] Verificar que la orden se marque como pagada

---

### ETAPA 5: Completar CRUD de Capitán
**Estado**: PENDIENTE

**Tareas a realizar**:
1. Verificar que `updateTableStatus` funcione correctamente
2. Implementar reasignación de mesa al backend (si es necesario)
3. Probar todas las operaciones desde el frontend

**Verificación**:
- [ ] Cambiar estado de mesa → Verificar en MySQL (tabla `mesa`)
- [ ] Reasignar mesa (si aplica) → Verificar en MySQL

---

### ETAPA 6: Pruebas Finales
**Estado**: PENDIENTE

**Tareas a realizar**:
1. Probar todos los CRUD desde cada rol
2. Verificar que todos los datos se reflejen en MySQL
3. Verificar que no haya errores en consola
4. Documentar cualquier problema encontrado

**Checklist de verificación**:
- [ ] Administrador: Usuarios, Productos, Inventario, Mesas, Categorías
- [ ] Mesero: Crear orden, Cambiar estado mesa, Enviar a cajero
- [ ] Cocinero: Cambiar estado orden, Cancelar orden
- [ ] Cajero: Procesar pago, Registrar propina
- [ ] Capitán: Cambiar estado mesa

---

## 🔍 Consultas SQL para Verificación

### Verificar categoría creada:
```sql
SELECT * FROM categoria ORDER BY creado_en DESC LIMIT 1;
```

### Verificar orden creada:
```sql
SELECT o.*, m.codigo AS mesa_codigo 
FROM orden o 
LEFT JOIN mesa m ON m.id = o.mesa_id 
ORDER BY o.creado_en DESC LIMIT 1;
```

### Verificar items de orden:
```sql
SELECT oi.*, p.nombre AS producto_nombre 
FROM orden_item oi 
JOIN producto p ON p.id = oi.producto_id 
WHERE oi.orden_id = ? 
ORDER BY oi.id;
```

### Verificar pago registrado:
```sql
SELECT p.*, fp.nombre AS forma_pago, o.mesa_id 
FROM pago p 
JOIN forma_pago fp ON fp.id = p.forma_pago_id 
JOIN orden o ON o.id = p.orden_id 
ORDER BY p.creado_en DESC LIMIT 1;
```

### Verificar propina registrada:
```sql
SELECT pr.*, o.mesa_id 
FROM propina pr 
JOIN orden o ON o.id = pr.orden_id 
ORDER BY pr.creado_en DESC LIMIT 1;
```

---

## 📝 Notas

- Todas las operaciones CRUD deben guardarse en la base de datos MySQL
- Después de cada operación, se debe recargar la lista desde el backend para asegurar sincronización
- Los errores deben manejarse correctamente y mostrarse al usuario
- Todas las operaciones deben probarse desde el frontend y verificarse en MySQL Workbench

---

**Última actualización**: 2024-01-XX
**Versión**: 1.0.0

