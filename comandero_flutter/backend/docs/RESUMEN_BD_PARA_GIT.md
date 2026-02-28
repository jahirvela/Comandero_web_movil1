# Resumen BD del proyecto – listo para subir a git

## 1. Estado actual (qué falta por subir)

Cuando quieras subir a git, incluye estos archivos:

| Archivo | Estado | Descripción |
|---------|--------|-------------|
| `scripts/agregar-configuracion-cajon.sql` | Modificado | Script simplificado: añade columnas del cajón a `configuracion`. |
| `scripts/agregar-orden-item-producto-nombre.sql` | Nuevo | Añade `producto_nombre` y `producto_tamano_etiqueta` en `orden_item` y rellena datos. |
| `docs/migraciones/20250213_configuracion_cajon.sql` | Nuevo | Copia de la migración del cajón en la carpeta de migraciones fechadas. |
| `src/modules/configuracion/configuracion.repository.ts` | Modificado | Backend que no exige columnas `cajon_*`: consulta base + try/catch para cajón. |

No subas: `.env`, `node_modules`, `tickets/*.txt`, `.env.local.simulation`, `ZKTECO`.

---

## 2. Scripts de BD que ya están en git

- **Configuración:** `agregar-tabla-configuracion.sql`, `agregar-configuracion-cajon.sql` (versión anterior; al subir la modificada la reemplazarás).
- **Órdenes / ítems:** `docs/migraciones/20250213_orden_item_producto_nombre.sql` (migración completa con FK). El nuevo `scripts/agregar-orden-item-producto-nombre.sql` es la versión mínima solo columnas + UPDATE.
- **Impresoras:** `agregar-tabla-impresora.sql`.
- **Comandas:** `create-comanda-impresion-table.sql`, `docs/migraciones/20250213_comanda_impresion_columnas.sql`.
- **Alertas:** `create-alertas-table.sql`, `agregar-metadata-alerta.sql`, `corregir-tabla-alerta.sql`.
- **Otros:** `agregar-estados-orden.sql`, `add-password-column.sql`, `agregar-tamano-ingrediente.sql`, `agregar-columna-categoria-inventario.sql`, `agregar-tiempo-estimado-preparacion.sql`, `add-tiempo-estimado-column.sql`, `agregar-codigo-barras-inventario.sql`, `fix-cierre-caja-unique.sql`, `migracion-completa-bd.sql`, `migracion-segura-bd.sql`, etc.

---

## 3. Para producción (orden sugerido de ejecución)

Si en producción aún no existen las columnas, el ingeniero puede ejecutar **una sola vez** en la BD (ej. `comandix`):

1. **`scripts/agregar-configuracion-cajon.sql`** – evita el error `Unknown column 'cajon_habilitado'`.
2. **`scripts/agregar-orden-item-producto-nombre.sql`** – evita el error `Unknown column 'producto_nombre'`.

El backend actual ya está preparado para funcionar sin esas columnas (configuración con try/catch, órdenes con `p.nombre`/`pt.etiqueta`). Ejecutar estos scripts deja la BD alineada y evita 500 por columnas faltantes.

---

## 4. Comandos para subir a git (cuando lo indiques)

```bash
git add comandero_flutter/backend/scripts/agregar-configuracion-cajon.sql
git add comandero_flutter/backend/scripts/agregar-orden-item-producto-nombre.sql
git add comandero_flutter/backend/docs/migraciones/20250213_configuracion_cajon.sql
git add comandero_flutter/backend/docs/RESUMEN_BD_PARA_GIT.md
git add comandero_flutter/backend/src/modules/configuracion/configuracion.repository.ts
git commit -m "BD: script cajon simplificado, script orden_item producto_nombre, migración cajon en docs, backend configuracion resiliente"
git push origin <rama>
```

(Reemplaza `<rama>` por la rama que uses, ej. `Comandix-Cafecito-Caliente`.)
