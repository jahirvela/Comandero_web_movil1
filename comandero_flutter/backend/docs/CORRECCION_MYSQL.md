# 🔧 Corrección de Error de Conexión MySQL

## ❌ Error Encontrado

```
ERROR: Error al establecer la conexión inicial con MySQL
connect ECONNREFUSED 127.0.0.1:3307
```

## ✅ Correcciones Aplicadas

### 1. Puerto Actualizado
- **Antes**: `DATABASE_PORT=3307`
- **Después**: `DATABASE_PORT=3306` (puerto estándar de MySQL)

El archivo `.env` ha sido actualizado automáticamente.

### 2. MySQL No Está Corriendo
El servicio MySQL81 está detenido. Necesitas iniciarlo.

## 🚀 Soluciones

### Opción 1: Iniciar MySQL desde PowerShell (Recomendado)

**Ejecuta PowerShell como Administrador** y luego:

```powershell
cd comandero_flutter\backend
.\scripts\iniciar-mysql.ps1
```

O manualmente:

```powershell
Start-Service -Name MySQL81
```

### Opción 2: Iniciar MySQL desde Servicios de Windows

1. Presiona `Win + R`
2. Escribe `services.msc` y presiona Enter
3. Busca el servicio **MySQL81**
4. Haz clic derecho > **Iniciar**

### Opción 3: Verificar Puerto Real de MySQL

Si MySQL está configurado para usar el puerto 3307, actualiza el `.env`:

```env
DATABASE_PORT=3307
```

Para verificar en qué puerto está corriendo MySQL:

```powershell
Get-NetTCPConnection -LocalPort 3306,3307 | Select-Object LocalPort, State
```

## ✅ Verificación

Después de iniciar MySQL, verifica que esté corriendo:

```powershell
Get-Service MySQL81 | Select-Object Name, Status
```

Debería mostrar `Status: Running`

## 📝 Notas

- El puerto por defecto de MySQL es **3306**
- Si tu instalación de MySQL usa otro puerto, actualiza `DATABASE_PORT` en `.env`
- Asegúrate de que MySQL esté corriendo antes de iniciar el backend

## 🔄 Reiniciar Backend

Después de corregir MySQL, reinicia el backend:

```powershell
cd comandero_flutter\backend
npm run dev
```

Deberías ver:
```
✅ Conexión MySQL inicial establecida correctamente
```

En lugar del error anterior.

