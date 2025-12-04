# Sistema de Respaldos Automáticos de Base de Datos

## 📋 Descripción

Este sistema proporciona respaldos automáticos de la base de datos MySQL para prevenir pérdida de datos. Incluye:

- ✅ **Backups manuales** bajo demanda
- ✅ **Backups automáticos** antes de migraciones
- ✅ **Backups periódicos** programados (diarios)
- ✅ **Restauración** de backups
- ✅ **Limpieza automática** de backups antiguos

---

## 🚀 Uso Rápido

### Crear un Backup Manual

```bash
npm run backup:database
```

Esto creará un backup comprimido en la carpeta `backups/` con un nombre único basado en la fecha y hora.

### Restaurar un Backup

```bash
npm run restore:backup -- "backups/backup_comandero_2025-11-18T21-30-00.sql.gz"
```

### Crear Backup Periódico (Diario)

```bash
npm run backup:periodico
```

### Programar Backups Automáticos (Windows)

```bash
npm run backup:programar
```

Esto creará una tarea programada en Windows que ejecutará backups diarios a las 2:00 AM.

---

## 📁 Estructura de Archivos

```
backend/
├── backups/                    # Directorio de backups (se crea automáticamente)
│   ├── backup_comandero_2025-11-18T21-30-00.sql.gz
│   ├── backup_comandero_2025-11-18T21-30-00.meta.json
│   └── ...
├── scripts/
│   ├── backup-database.ts      # Script principal de backup
│   ├── restore-backup.ts       # Script de restauración
│   ├── backup-periodico.ts    # Script para backups periódicos
│   └── programar-backups.ps1   # Script para programar en Windows
└── docs/
    └── BACKUPS_AUTOMATICOS.md  # Esta documentación
```

---

## 🔧 Funcionalidades Detalladas

### 1. Backup Manual (`backup-database.ts`)

Crea un backup completo de la base de datos usando `mysqldump`.

**Características:**
- ✅ Backup completo (estructura + datos)
- ✅ Comprimido con gzip (por defecto)
- ✅ Incluye stored procedures, triggers y events
- ✅ Transaccional (consistencia garantizada)
- ✅ Genera metadata del backup

**Opciones disponibles:**
```typescript
{
  outputDir?: string;        // Directorio de salida (default: ./backups)
  filename?: string;         // Nombre personalizado (default: auto-generado)
  compress?: boolean;        // Comprimir con gzip (default: true)
  includeData?: boolean;     // Incluir datos (default: true)
  includeStructure?: boolean; // Incluir estructura (default: true)
}
```

**Ejemplo de uso programático:**
```typescript
import { crearBackup } from './scripts/backup-database.js';

const backupPath = await crearBackup({
  filename: 'backup_antes_de_cambio',
  compress: true
});
```

### 2. Restauración (`restore-backup.ts`)

Restaura un backup previamente creado.

**Características:**
- ✅ Restaura backups comprimidos (.gz) y sin comprimir (.sql)
- ✅ Crea backup de seguridad antes de restaurar
- ✅ Verifica que el archivo existe antes de restaurar

**Uso:**
```bash
npm run restore:backup -- "ruta/al/backup.sql"
npm run restore:backup -- "ruta/al/backup.sql.gz"
```

### 3. Backup Periódico (`backup-periodico.ts`)

Crea backups diarios y limpia automáticamente los antiguos.

**Características:**
- ✅ Crea backup con nombre basado en fecha
- ✅ Limpia backups más antiguos de 30 días (configurable)
- ✅ Muestra estadísticas de limpieza

**Uso:**
```bash
npm run backup:periodico
```

### 4. Backup Automático en Migraciones

El script `ejecutar-migracion-completa.ts` ahora crea automáticamente un backup antes de ejecutar cualquier migración.

**Características:**
- ✅ Backup automático antes de migrar
- ✅ Si falla el backup, pregunta si continuar
- ✅ Timeout de 10 segundos en modo no interactivo

---

## 📅 Programación de Backups (Windows)

### Configurar Backups Diarios Automáticos

1. **Ejecutar el script de programación:**
   ```bash
   npm run backup:programar
   ```

2. **Verificar la tarea creada:**
   ```powershell
   Get-ScheduledTask -TaskName "Comandero_Backup_Diario"
   ```

3. **Eliminar la tarea (si es necesario):**
   ```powershell
   Unregister-ScheduledTask -TaskName "Comandero_Backup_Diario" -Confirm:$false
   ```

**Configuración por defecto:**
- **Frecuencia:** Diario
- **Hora:** 2:00 AM
- **Usuario:** SYSTEM (ejecuta con privilegios elevados)
- **Retención:** 30 días (configurado en el script)

### Programar en Linux/Mac (Cron)

Para programar backups en Linux o Mac, edita el crontab:

```bash
crontab -e
```

Agrega la siguiente línea para backups diarios a las 2:00 AM:

```cron
0 2 * * * cd /ruta/al/proyecto/backend && npm run backup:periodico >> logs/backup.log 2>&1
```

---

## 🔍 Verificación de Backups

### Listar Backups Disponibles

```bash
# Windows PowerShell
Get-ChildItem backups\*.sql.gz | Sort-Object LastWriteTime -Descending

# Linux/Mac
ls -lh backups/*.sql.gz | sort -k6,7
```

### Verificar Metadata de un Backup

Cada backup incluye un archivo `.meta.json` con información:

```json
{
  "timestamp": "2025-11-18T21:30:00.000Z",
  "database": "comandero",
  "filename": "backup_comandero_2025-11-18T21-30-00.sql.gz",
  "size": 1048576,
  "sizeMB": 1.0,
  "compressed": true,
  "includesData": true,
  "includesStructure": true
}
```

---

## ⚠️ Requisitos

### Herramientas Necesarias

1. **mysqldump** - Viene con MySQL Server
   - Windows: Incluido en la instalación de MySQL
   - Linux: `sudo apt-get install mysql-client` (Ubuntu/Debian)
   - Mac: Incluido con MySQL Server

2. **gzip/gunzip** - Para compresión
   - Windows: Incluido en Git Bash o WSL
   - Linux/Mac: Incluido por defecto

### Verificar Instalación

```bash
# Verificar mysqldump
mysqldump --version

# Verificar gzip
gzip --version
```

---

## 🛡️ Mejores Prácticas

### 1. Backups Regulares
- ✅ Ejecuta backups diarios automáticos
- ✅ Crea backups manuales antes de cambios importantes
- ✅ Verifica que los backups se están creando correctamente

### 2. Almacenamiento
- ✅ Guarda backups en ubicación externa (nube, servidor remoto)
- ✅ Mantén múltiples copias (local + remoto)
- ✅ Verifica periódicamente que puedes restaurar los backups

### 3. Retención
- ✅ Mantén backups diarios por 30 días
- ✅ Mantén backups semanales por 3 meses
- ✅ Mantén backups mensuales por 1 año

### 4. Seguridad
- ✅ Protege los backups con contraseñas
- ✅ No almacenes backups en el mismo servidor que la BD
- ✅ Encripta backups sensibles

---

## 🔄 Flujo de Trabajo Recomendado

### Antes de Hacer Cambios Importantes

1. **Crear backup manual:**
   ```bash
   npm run backup:database
   ```

2. **Verificar que el backup se creó:**
   ```bash
   ls -lh backups/
   ```

3. **Realizar los cambios**

4. **Si algo sale mal, restaurar:**
   ```bash
   npm run restore:backup -- "backups/backup_antes_de_cambio.sql.gz"
   ```

### Migraciones de Base de Datos

Las migraciones ahora crean backups automáticamente, pero es recomendable:

1. **Crear backup manual adicional:**
   ```bash
   npm run backup:database
   ```

2. **Ejecutar migración:**
   ```bash
   npm run migrate
   ```

3. **Verificar que todo funciona**

4. **Si hay problemas, restaurar:**
   ```bash
   npm run restore:backup -- "backups/backup_pre_migracion_..."
   ```

---

## 🐛 Solución de Problemas

### Error: "mysqldump no está instalado"

**Solución:**
1. Verifica que MySQL está instalado
2. Agrega MySQL al PATH del sistema
3. Reinicia la terminal/PowerShell

### Error: "No se puede crear el backup"

**Posibles causas:**
- Credenciales incorrectas en `.env`
- Base de datos no existe
- Permisos insuficientes

**Solución:**
1. Verifica las credenciales en `.env`
2. Verifica que la base de datos existe
3. Verifica permisos del usuario MySQL

### Error: "No se puede restaurar el backup"

**Posibles causas:**
- Archivo corrupto
- Base de datos en uso
- Permisos insuficientes

**Solución:**
1. Verifica que el archivo no está corrupto
2. Cierra conexiones activas a la BD
3. Verifica permisos del usuario MySQL

---

## 📊 Monitoreo

### Verificar Último Backup

```bash
# Windows
Get-ChildItem backups\*.sql.gz | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Linux/Mac
ls -t backups/*.sql.gz | head -1
```

### Verificar Tamaño de Backups

```bash
# Windows
Get-ChildItem backups\*.sql.gz | Measure-Object -Property Length -Sum

# Linux/Mac
du -sh backups/
```

---

## 📝 Notas Importantes

1. **Los backups incluyen TODOS los datos** de la base de datos
2. **Los backups comprimidos** ocupan menos espacio pero requieren descompresión
3. **La restauración sobrescribe** la base de datos actual
4. **Siempre crea un backup** antes de restaurar otro backup
5. **Verifica los backups periódicamente** para asegurar que funcionan

---

## 🔗 Scripts Relacionados

- `ejecutar-migracion-completa.ts` - Crea backup automático antes de migrar
- `backup-database.ts` - Script principal de backup
- `restore-backup.ts` - Script de restauración
- `backup-periodico.ts` - Script para backups periódicos
- `programar-backups.ps1` - Script para programar en Windows

---

## ✅ Checklist de Implementación

- [x] Script de backup manual
- [x] Script de restauración
- [x] Backup automático en migraciones
- [x] Script de backup periódico
- [x] Limpieza automática de backups antiguos
- [x] Programación de backups (Windows)
- [x] Documentación completa
- [ ] Programación de backups (Linux/Mac) - Ver sección Cron
- [ ] Integración con almacenamiento en la nube (futuro)
- [ ] Encriptación de backups (futuro)

---

**Última actualización:** 2025-11-18

