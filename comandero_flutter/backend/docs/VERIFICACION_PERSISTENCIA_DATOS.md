# ✅ Verificación Completa de Persistencia de Datos

## 🎯 Objetivo
Asegurar que **TODOS** los datos se guarden correctamente en la base de datos MySQL y que **NO** se pierdan datos.

---

## ✅ 1. Configuración de Base de Datos

### Motor de Base de Datos
- ✅ **ENGINE=InnoDB** en todas las tablas
  - Transaccional (ACID)
  - Soporte para transacciones
  - Integridad referencial
  - Recuperación ante fallos

### Configuración del Pool de Conexiones
```typescript
// backend/src/db/pool.ts
- timezone: 'Z' (UTC) ✅
- namedPlaceholders: true ✅
- dateStrings: false ✅
- connectionLimit: configurado ✅
- enableKeepAlive: true ✅
- withTransaction: disponible ✅
```

### Zona Horaria
- ✅ Base de datos: UTC (`timezone: 'Z'`)
- ✅ Sistema: America/Mexico_City (CDMX)
- ✅ Conversión automática: UTC ↔ CDMX en módulo `time.ts`

---

## ✅ 2. Persistencia de Datos por Módulo

### 2.1 Usuarios y Autenticación
- ✅ **Crear usuario**: `INSERT INTO usuario` + `INSERT INTO usuario_rol`
- ✅ **Actualizar usuario**: `UPDATE usuario` + `UPDATE usuario_rol`
- ✅ **Eliminar usuario**: `DELETE FROM usuario_rol` + `DELETE FROM usuario`
- ✅ **Cambiar contraseña**: `UPDATE usuario` + `INSERT INTO usuario_password_hist`
- ✅ **Activar/Desactivar**: `UPDATE usuario SET activo`

**Archivos:**
- `backend/src/modules/usuarios/usuarios.repository.ts`
- `backend/src/modules/auth/auth.repository.ts`

---

### 2.2 Productos y Menú
- ✅ **Crear producto**: `INSERT INTO producto`
- ✅ **Actualizar producto**: `UPDATE producto`
- ✅ **Eliminar producto**: `UPDATE producto SET activo = 0` (soft delete)
- ✅ **Cambiar disponibilidad**: `UPDATE producto SET disponible`

**Archivos:**
- `backend/src/modules/productos/productos.repository.ts`

---

### 2.3 Inventario
- ✅ **Crear item**: `INSERT INTO inventario_item`
- ✅ **Actualizar item**: `UPDATE inventario_item`
- ✅ **Eliminar item**: `DELETE FROM inventario_item`
- ✅ **Reabastecer**: `INSERT INTO inventario_movimiento` + `UPDATE inventario_item`

**Archivos:**
- `backend/src/modules/inventario/inventario.repository.ts`

---

### 2.4 Mesas
- ✅ **Crear mesa**: `INSERT INTO mesa`
- ✅ **Actualizar mesa**: `UPDATE mesa`
- ✅ **Eliminar mesa**: `DELETE FROM mesa`
- ✅ **Cambiar estado**: `UPDATE mesa SET estado_mesa_id`

**Archivos:**
- `backend/src/modules/mesas/mesas.repository.ts`

---

### 2.5 Órdenes
- ✅ **Crear orden**: `INSERT INTO orden` + `INSERT INTO orden_item` (transaccional)
- ✅ **Actualizar estado**: `UPDATE orden SET estado_orden_id`
- ✅ **Actualizar items**: `DELETE FROM orden_item` + `INSERT INTO orden_item`
- ✅ **Cancelar orden**: `UPDATE orden SET estado_orden_id = 'cancelada'`

**Archivos:**
- `backend/src/modules/ordenes/ordenes.repository.ts`
- ✅ Usa `withTransaction` para operaciones atómicas

---

### 2.6 Pagos
- ✅ **Procesar pago**: `INSERT INTO pago`
  - ✅ Fecha convertida correctamente: ISO → SQL (YYYY-MM-DD HH:mm:ss)
  - ✅ Zona horaria: CDMX → UTC antes de guardar
- ✅ **Registrar propina**: `INSERT INTO propina`
- ✅ **Actualizar orden a pagada**: `UPDATE orden SET estado_orden_id = 'pagada'`

**Archivos:**
- `backend/src/modules/pagos/pagos.repository.ts`
- `backend/src/modules/pagos/pagos.schemas.ts` (conversión de fecha)

---

### 2.7 Cierres de Caja
- ✅ **Crear cierre**: `INSERT INTO caja_cierre`
- ✅ **Actualizar cierre**: `UPDATE caja_cierre`
- ✅ **Fechas**: Convertidas de CDMX a UTC

**Archivos:**
- `backend/src/modules/cierres/cierres.repository.ts`

---

### 2.8 Alertas y Notificaciones
- ✅ **Crear alerta**: `INSERT INTO alerta`
  - ✅ Se guarda **ANTES** de emitir por Socket.IO
  - ✅ Persistencia garantizada incluso si Socket.IO falla
- ✅ **Marcar como leída**: `UPDATE alerta SET leida = 1`
- ✅ **Marcar todas como leídas**: `UPDATE alerta SET leida = 1 WHERE ...`

**Archivos:**
- `backend/src/modules/alertas/alertas.repository.ts`
- `backend/src/modules/alertas/alertas.service.ts`

**Flujo:**
1. Se crea la alerta en BD (`crearAlerta`)
2. Se emite por Socket.IO para tiempo real
3. Si Socket.IO falla, la alerta ya está guardada en BD
4. Al reconectar, se cargan alertas no leídas desde BD

---

### 2.9 Tickets
- ✅ **Crear ticket**: `INSERT INTO ticket`
- ✅ **Marcar como impreso**: `UPDATE ticket SET impreso_en = NOW()`
- ✅ **Fechas**: Convertidas de CDMX a UTC

**Archivos:**
- `backend/src/modules/tickets/tickets.repository.ts`
- `backend/src/modules/tickets/tickets.service.ts`

---

### 2.10 Reservas
- ✅ **Crear reserva**: `INSERT INTO reserva`
- ✅ **Actualizar reserva**: `UPDATE reserva`
- ✅ **Cancelar reserva**: `UPDATE reserva SET estado = 'cancelada'`
- ✅ **Fechas**: Convertidas de CDMX a UTC

**Archivos:**
- `backend/src/modules/reservas/reservas.repository.ts`

---

## ✅ 3. Eventos Socket.IO y Persistencia

### 3.1 Eventos que se Guardan en BD
- ✅ **`pedido.creado`**: Se guarda en `orden` + `orden_item`
- ✅ **`pedido.actualizado`**: Se actualiza en `orden`
- ✅ **`alerta.*`**: Se guarda en `alerta` **ANTES** de emitir
- ✅ **`pago.creado`**: Se guarda en `pago`
- ✅ **`ticket.creado`**: Se guarda en `ticket`

### 3.2 Flujo de Persistencia
```
1. Operación en Frontend
   ↓
2. Llamada API al Backend
   ↓
3. Guardar en BD (transaccional)
   ↓
4. Emitir evento Socket.IO (opcional, para tiempo real)
   ↓
5. Respuesta al Frontend
```

**Importante:** Los datos se guardan en BD **ANTES** de emitir eventos Socket.IO.

---

## ✅ 4. Manejo de Fechas y Zona Horaria

### 4.1 Configuración
- ✅ Base de datos: UTC (`timezone: 'Z'`)
- ✅ Sistema: America/Mexico_City (CDMX)
- ✅ Módulo central: `backend/src/config/time.ts`

### 4.2 Funciones de Conversión
- ✅ `nowMx()`: Hora actual en CDMX
- ✅ `utcToMx()`: UTC → CDMX
- ✅ `mxToUtc()`: CDMX → UTC
- ✅ `parseMxToUtc()`: Parsear string → UTC
- ✅ `utcToMxISO()`: UTC → ISO string en CDMX
- ✅ `formatMx()`: Formatear para mostrar en CDMX

### 4.3 Aplicación en Módulos
- ✅ **Órdenes**: `creado_en`, `actualizado_en` → CDMX al leer
- ✅ **Pagos**: `fecha_pago` → SQL format (YYYY-MM-DD HH:mm:ss) al guardar
- ✅ **Tickets**: `fecha_impresion` → CDMX al mostrar
- ✅ **Cierres**: `fecha` → CDMX al mostrar
- ✅ **Alertas**: `creado_en` → CDMX al mostrar

---

## ✅ 5. Transacciones y Atomicidad

### 5.1 Operaciones Transaccionales
- ✅ **Crear orden**: `orden` + `orden_item` (una transacción)
- ✅ **Actualizar inventario**: `inventario_movimiento` + `inventario_item` (una transacción)
- ✅ **Procesar pago**: `pago` + `orden` (actualizar estado)

### 5.2 Función de Transacciones
```typescript
// backend/src/db/pool.ts
export const withTransaction = async <T>(
  fn: (connection: mysql.PoolConnection) => Promise<T>
): Promise<T>
```

**Uso:**
- ✅ Garantiza atomicidad
- ✅ Rollback automático en caso de error
- ✅ Commit automático si todo es exitoso

---

## ✅ 6. Verificación de Integridad

### 6.1 Foreign Keys
- ✅ Todas las tablas tienen FOREIGN KEY constraints
- ✅ `ON DELETE CASCADE` o `ON DELETE SET NULL` según corresponda
- ✅ `ON UPDATE CASCADE` para mantener integridad

### 6.2 Índices
- ✅ PRIMARY KEY en todas las tablas
- ✅ Índices en campos de búsqueda frecuente
- ✅ Índices en foreign keys

### 6.3 Constraints
- ✅ UNIQUE en campos únicos (username, email, etc.)
- ✅ NOT NULL en campos requeridos
- ✅ CHECK constraints donde aplica

---

## ✅ 7. Recuperación de Datos

### 7.1 Carga Inicial
- ✅ Todos los controladores cargan datos desde BD al iniciar
- ✅ No hay datos hardcodeados en producción
- ✅ Datos de ejemplo solo para desarrollo

### 7.2 Recarga después de Operaciones
- ✅ Después de CRUD, se recargan datos desde BD
- ✅ Sincronización garantizada entre frontend y backend
- ✅ Socket.IO actualiza en tiempo real

### 7.3 Persistencia de Estado
- ✅ Alertas no leídas se cargan desde BD al iniciar
- ✅ Órdenes activas se cargan desde BD al iniciar
- ✅ Bills pendientes se cargan desde BD al iniciar

---

## ✅ 8. Backups y Recuperación

### 8.1 Recomendaciones
- ⚠️ **Configurar backups automáticos** de MySQL
- ⚠️ **Backups diarios** recomendados
- ⚠️ **Backups antes de migraciones** importantes

### 8.2 Scripts de Migración
- ✅ `migracion-completa-bd.sql`: Script completo de creación
- ✅ `migracion-segura-bd.sql`: Script con verificaciones
- ✅ Todos los scripts usan `CREATE TABLE IF NOT EXISTS`

---

## ✅ 9. Checklist Final

### Backend
- ✅ Todas las tablas usan `ENGINE=InnoDB`
- ✅ Todas las operaciones CRUD guardan en BD
- ✅ Fechas se convierten correctamente (CDMX ↔ UTC)
- ✅ Alertas se guardan en BD antes de emitir
- ✅ Transacciones para operaciones atómicas
- ✅ Foreign keys y constraints configurados

### Frontend
- ✅ Datos se cargan desde BD al iniciar
- ✅ Datos se recargan después de CRUD
- ✅ Socket.IO para actualizaciones en tiempo real
- ✅ Persistencia local solo para cache (no fuente de verdad)

### Base de Datos
- ✅ Pool de conexiones configurado correctamente
- ✅ Timezone configurado como UTC
- ✅ Keep-alive habilitado
- ✅ Timeout configurado

---

## 🎯 Resultado Final

**✅ TODOS los datos se guardan en MySQL**
**✅ NO hay datos temporales que se puedan perder**
**✅ Persistencia garantizada incluso si Socket.IO falla**
**✅ Recuperación de datos desde BD al reiniciar**
**✅ Transacciones para operaciones críticas**
**✅ Fechas manejadas correctamente (CDMX ↔ UTC)**

---

## 📝 Notas Importantes

1. **Socket.IO es complementario**: Los eventos Socket.IO son para tiempo real, pero los datos se guardan en BD primero.

2. **BD es la fuente de verdad**: Si Socket.IO falla, los datos ya están guardados en BD y se pueden recuperar.

3. **Fechas siempre en UTC en BD**: Todas las fechas se guardan en UTC y se convierten a CDMX al mostrar.

4. **Transacciones para operaciones críticas**: Operaciones que involucran múltiples tablas usan transacciones.

5. **Recarga después de CRUD**: Después de cada operación CRUD, se recargan los datos desde BD para mantener sincronización.

---

## 🚀 Próximos Pasos Recomendados

1. **Configurar backups automáticos** de MySQL
2. **Monitorear logs** de errores de BD
3. **Verificar integridad** periódicamente
4. **Documentar procedimientos** de recuperación

---

**Última actualización:** 2025-12-03
**Estado:** ✅ Verificación Completa

