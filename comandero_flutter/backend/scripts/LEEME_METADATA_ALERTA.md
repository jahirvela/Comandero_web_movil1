# Script: Agregar columna metadata a tabla alerta

## 📋 Descripción

Este script agrega la columna `metadata` de tipo JSON a la tabla `alerta` para permitir guardar información adicional como:
- Prioridad de la alerta (Normal/Urgente)
- Estación de cocina
- Tipo de alerta
- Y cualquier otra información adicional

## 🚀 Cómo ejecutar

### Opción 1: Desde MySQL Workbench o línea de comandos

```bash
# Conectarse a MySQL
mysql -u tu_usuario -p comandero

# Ejecutar el script
source scripts/agregar-metadata-alerta.sql;
```

O directamente:

```bash
mysql -u tu_usuario -p comandero < scripts/agregar-metadata-alerta.sql
```

### Opción 2: Desde MySQL Workbench

1. Abre MySQL Workbench
2. Conéctate a tu base de datos
3. Abre el archivo `agregar-metadata-alerta.sql`
4. Ejecuta el script (Ctrl+Shift+Enter o botón "Execute")

### Opción 3: Ejecución directa (si prefieres omitir la verificación)

Si quieres ejecutar directamente sin verificar si la columna existe:

```sql
USE comandero;
ALTER TABLE alerta 
ADD COLUMN metadata JSON NULL 
COMMENT 'Metadata adicional de la alerta (prioridad, estación, etc.)' 
AFTER creado_en;
```

**Nota:** Si la columna ya existe, MySQL mostrará un error. Simplemente ignóralo.

## ✅ Verificación

Después de ejecutar el script, verifica que la columna se agregó correctamente:

```sql
DESCRIBE alerta;
```

O más específicamente:

```sql
SELECT 
  COLUMN_NAME, 
  COLUMN_TYPE, 
  IS_NULLABLE, 
  COLUMN_DEFAULT, 
  COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'alerta' 
  AND COLUMN_NAME = 'metadata';
```

Deberías ver:
- **COLUMN_NAME:** metadata
- **COLUMN_TYPE:** json
- **IS_NULLABLE:** YES
- **COLUMN_COMMENT:** Metadata adicional de la alerta (prioridad, estación, etc.)

## 📝 Notas Importantes

1. **MySQL 5.7+ requerido:** El tipo JSON está disponible desde MySQL 5.7. Si tienes una versión anterior, usa `TEXT` o `LONGTEXT` en su lugar.

2. **Sin pérdida de datos:** Este script solo agrega una nueva columna. No modifica ni elimina datos existentes.

3. **Valores existentes:** Las alertas existentes tendrán `metadata = NULL` hasta que se actualicen con nuevos datos.

4. **Idempotencia:** El script verifica si la columna ya existe antes de intentar agregarla, por lo que es seguro ejecutarlo múltiples veces.

## 🔄 Rollback (si es necesario)

Si necesitas eliminar la columna (no recomendado si ya hay datos):

```sql
ALTER TABLE alerta DROP COLUMN metadata;
```

## 📊 Ejemplo de uso

Una vez agregada la columna, el backend guardará datos como:

```json
{
  "priority": "Urgente",
  "station": "tacos",
  "type": "CANCEL_ORDER"
}
```

