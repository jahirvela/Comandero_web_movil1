image.png# 📦 Guía Rápida de Respaldos

## 🚀 Comandos Principales

### 1. Crear un Backup Manual

```bash
npm run backup:database
```

**¿Cuándo usarlo?**
- Antes de hacer cambios importantes en la base de datos
- Antes de ejecutar migraciones
- Cuando quieras guardar el estado actual de tus datos
- Después de crear usuarios, productos, o datos importantes

**Resultado:**
- Se crea un archivo `.sql.gz` en la carpeta `backups/`
- El archivo incluye todas las tablas y datos
- Se genera automáticamente un archivo `.meta.json` con información del backup

**Ejemplo de salida:**
```
✅ BACKUP COMPLETADO EXITOSAMENTE
📄 Archivo: backup_comandero_2025-11-19T03-37-47.sql.gz
📊 Tamaño: 0.01 MB
📁 Ubicación: backend/backups/
```

---

### 2. Restaurar un Backup

```bash
npm run restore:backup -- "backups/backup_comandero_2025-11-19T03-37-47.sql.gz"
```

**⚠️ IMPORTANTE:**
- La restauración **sobrescribe** toda la base de datos actual
- Se crea automáticamente un backup de seguridad antes de restaurar
- Asegúrate de tener el nombre exacto del archivo

**Pasos:**
1. Lista los backups disponibles:
   ```powershell
   Get-ChildItem backups\*.sql.gz
   ```

2. Copia el nombre completo del backup que quieres restaurar

3. Ejecuta el comando de restauración:
   ```bash
   npm run restore:backup -- "backups/NOMBRE_DEL_BACKUP.sql.gz"
   ```

**Ejemplo:**
```bash
npm run restore:backup -- "backups/backup_comandero_2025-11-19T03-37-47.sql.gz"
```

---

### 3. Crear Backup Periódico (con limpieza automática)

```bash
npm run backup:periodico
```

**¿Cuándo usarlo?**
- Para crear backups diarios
- Limpia automáticamente backups más antiguos de 30 días
- Útil para programar ejecuciones automáticas

**Resultado:**
- Crea un backup con nombre basado en la fecha: `backup_diario_2025-11-19.sql.gz`
- Elimina automáticamente backups más antiguos de 30 días
- Muestra estadísticas de limpieza

---

### 4. Programar Backups Automáticos (Windows)

```bash
npm run backup:programar
```

**¿Qué hace?**
- Crea una tarea programada en Windows
- Ejecuta backups automáticos **diarios a las 2:00 AM**
- No requiere intervención manual

**⚠️ Requisitos:**
- Ejecutar PowerShell como Administrador (recomendado)
- Windows con Task Scheduler habilitado

**Después de programar:**
- Los backups se crearán automáticamente cada día
- Puedes verificar la tarea con:
  ```powershell
  Get-ScheduledTask -TaskName "Comandero_Backup_Diario"
  ```

**Para eliminar la tarea programada:**
```powershell
Unregister-ScheduledTask -TaskName "Comandero_Backup_Diario" -Confirm:$false
```

---

## 📋 Flujo de Trabajo Recomendado

### Antes de Hacer Cambios Importantes

```bash
# 1. Crear backup manual
npm run backup:database

# 2. Verificar que se creó
Get-ChildItem backups\*.sql.gz | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# 3. Hacer tus cambios en la base de datos

# 4. Si algo sale mal, restaurar:
npm run restore:backup -- "backups/backup_antes_de_cambio.sql.gz"
```

### Antes de Ejecutar Migraciones

Las migraciones ahora crean backups automáticamente, pero es recomendable:

```bash
# 1. Crear backup manual adicional (por seguridad)
npm run backup:database

# 2. Ejecutar migración (creará su propio backup automático)
npm run migrate

# 3. Verificar que todo funciona correctamente
```

### Mantenimiento Regular

```bash
# Crear backup periódico (se limpia automáticamente)
npm run backup:periodico

# O programar backups automáticos (una sola vez)
npm run backup:programar
```

---

## 📁 Ubicación de los Backups

Todos los backups se guardan en:
```
backend/backups/
```

**Estructura típica:**
```
backups/
├── backup_comandero_2025-11-19T03-37-47.sql.gz
├── backup_comandero_2025-11-19T03-37-47.meta.json
├── backup_diario_2025-11-19.sql.gz
├── backup_diario_2025-11-19.meta.json
└── ...
```

---

## 🔍 Verificar Backups Disponibles

### Windows PowerShell

```powershell
# Ver todos los backups
Get-ChildItem backups\*.sql.gz

# Ver el más reciente
Get-ChildItem backups\*.sql.gz | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Ver con detalles (nombre, tamaño, fecha)
Get-ChildItem backups\*.sql.gz | Select-Object Name, @{Name="Size (MB)";Expression={[math]::Round($_.Length/1MB, 2)}}, LastWriteTime | Format-Table -AutoSize
```

### Ver Metadata de un Backup

Cada backup incluye un archivo `.meta.json` con información:

```json
{
  "timestamp": "2025-11-19T03:37:47.000Z",
  "database": "comandero",
  "filename": "backup_comandero_2025-11-19T03-37-47.sql.gz",
  "size": 1048576,
  "sizeMB": 1.0,
  "compressed": true,
  "tables": 45,
  "includesData": true,
  "includesStructure": true
}
```

---

## ⚠️ Situaciones Importantes

### 1. Antes de Restaurar un Backup

**SIEMPRE** crea un backup del estado actual antes de restaurar:

```bash
# El script de restauración lo hace automáticamente, pero puedes hacerlo manual:
npm run backup:database
npm run restore:backup -- "backups/backup_antiguo.sql.gz"
```

### 2. Si el Backup es Muy Grande

Si el backup es muy grande (>100MB), considera:
- Comprimir manualmente (ya viene comprimido por defecto)
- Guardar en ubicación externa (nube, USB)
- Limpiar backups antiguos manualmente

### 3. Verificar que los Backups Funcionan

Periódicamente, verifica que puedes restaurar un backup:

```bash
# 1. Crear backup de prueba
npm run backup:database

# 2. Anotar el nombre del archivo

# 3. (Opcional) Probar restauración en base de datos de prueba
```

---

## 🆘 Solución de Problemas

### Error: "No se puede crear el backup"

**Posibles causas:**
- Base de datos no está corriendo
- Credenciales incorrectas en `.env`
- Permisos insuficientes

**Solución:**
1. Verifica que MySQL está corriendo
2. Revisa las credenciales en `backend/.env`
3. Verifica permisos del usuario MySQL

### Error: "No se puede restaurar el backup"

**Posibles causas:**
- Archivo corrupto
- Base de datos en uso
- Permisos insuficientes

**Solución:**
1. Verifica que el archivo existe y no está corrupto
2. Cierra conexiones activas a la BD
3. Verifica permisos del usuario MySQL

### El Backup no se está creando

**Verificar:**
1. Que el directorio `backups/` existe o se puede crear
2. Que hay espacio en disco
3. Que Node.js y las dependencias están instaladas

---

## 📊 Resumen de Comandos

| Comando | Descripción | Uso |
|---------|-------------|-----|
| `npm run backup:database` | Crear backup manual | Antes de cambios importantes |
| `npm run restore:backup -- "ruta"` | Restaurar backup | Cuando necesites recuperar datos |
| `npm run backup:periodico` | Backup periódico con limpieza | Para backups diarios |
| `npm run backup:programar` | Programar backups automáticos | Configurar una vez |

---

## 💡 Consejos Finales

1. **Crea backups regularmente** - No esperes a tener problemas
2. **Guarda backups en múltiples lugares** - Local + Nube + USB
3. **Verifica los backups periódicamente** - Asegúrate de que funcionan
4. **Documenta cambios importantes** - Anota qué backup corresponde a qué estado
5. **Mantén backups organizados** - Usa nombres descriptivos si creas backups manuales

---

## 📞 Comandos de Referencia Rápida

```bash
# Crear backup ahora
npm run backup:database

# Ver backups disponibles
Get-ChildItem backups\*.sql.gz

# Restaurar backup más reciente
npm run restore:backup -- "backups/$(Get-ChildItem backups\*.sql.gz | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty Name)"

# Programar backups automáticos
npm run backup:programar
```

---

**Última actualización:** 2025-11-19

