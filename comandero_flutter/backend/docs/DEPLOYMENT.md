# 🚀 Guía de Deployment para Producción

Esta guía te ayudará a configurar y desplegar el sistema Comandero en un entorno de producción.

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Configuración del Entorno](#configuración-del-entorno)
3. [Configuración de la Base de Datos](#configuración-de-la-base-de-datos)
4. [Configuración del Backend](#configuración-del-backend)
5. [Configuración del Frontend](#configuración-del-frontend)
6. [Backups Automáticos](#backups-automáticos)
7. [Monitoreo y Logging](#monitoreo-y-logging)
8. [Seguridad](#seguridad)
9. [Verificación Pre-Deployment](#verificación-pre-deployment)
10. [Proceso de Deployment](#proceso-de-deployment)

---

## 📦 Requisitos Previos

### Software Necesario

- **Node.js**: Versión 20.0.0 o superior
- **MySQL**: Versión 8.0 o superior
- **Git**: Para clonar el repositorio
- **PM2** (recomendado): Para gestión de procesos en producción
  ```bash
  npm install -g pm2
  ```

### Servidor

- **RAM**: Mínimo 2GB, recomendado 4GB+
- **CPU**: Mínimo 2 cores, recomendado 4 cores+
- **Disco**: Mínimo 20GB libres
- **Sistema Operativo**: Linux (Ubuntu 20.04+ recomendado) o Windows Server

---

## ⚙️ Configuración del Entorno

### 1. Clonar el Repositorio

```bash
git clone <url-del-repositorio>
cd comandero_web_movil/comandero_flutter/backend
```

### 2. Instalar Dependencias

```bash
npm install
```

### 3. Configurar Variables de Entorno

```bash
# Copiar el archivo de ejemplo
cp .env.example .env

# Editar el archivo .env con tus valores
nano .env  # o usar tu editor preferido
```

**Variables Críticas para Producción:**

```env
NODE_ENV=production
PORT=3000

# Base de datos
DATABASE_HOST=tu-servidor-db
DATABASE_USER=usuario_seguro
DATABASE_PASSWORD=contraseña_fuerte
DATABASE_NAME=comandero

# JWT - GENERAR SECRETOS SEGUROS
JWT_ACCESS_SECRET=<generar-con-openssl-rand-base64-32>
JWT_REFRESH_SECRET=<generar-con-openssl-rand-base64-32>

# CORS - Solo tu dominio de producción
CORS_ORIGIN=https://tu-dominio.com

# Logging
LOG_LEVEL=info
LOG_PRETTY=false
```

**Generar Secretos JWT:**

```bash
# En Linux/Mac
openssl rand -base64 32

# En Windows PowerShell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

---

## 🗄️ Configuración de la Base de Datos

### 1. Crear Base de Datos

```sql
CREATE DATABASE comandero CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 2. Crear Usuario de Base de Datos

```sql
CREATE USER 'comandero_user'@'localhost' IDENTIFIED BY 'contraseña_fuerte';
GRANT ALL PRIVILEGES ON comandero.* TO 'comandero_user'@'localhost';
FLUSH PRIVILEGES;
```

### 3. Ejecutar Migraciones

```bash
# Ejecutar el script de migración
npm run migrate:full
# O manualmente:
tsx scripts/ejecutar-migracion-completa.ts
```

### 4. Crear Usuario Administrador

```bash
npm run create-admin
```

---

## 🔧 Configuración del Backend

### 1. Compilar el Proyecto

```bash
npm run build
```

### 2. Configurar PM2 (Recomendado)

Crear archivo `ecosystem.config.js`:

```javascript
module.exports = {
  apps: [{
    name: 'comandero-backend',
    script: './dist/server.js',
    instances: 2, // Número de instancias (recomendado: número de CPUs)
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    max_memory_restart: '1G',
    watch: false
  }]
};
```

### 3. Iniciar con PM2

```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup  # Configurar inicio automático
```

### 4. Verificar Estado

```bash
pm2 status
pm2 logs comandero-backend
```

---

## 🎨 Configuración del Frontend

### 1. Configurar API URL

Editar `comandero_flutter/lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'https://tu-dominio.com/api';
  static const String socketUrl = 'https://tu-dominio.com';
}
```

### 2. Compilar para Producción

```bash
cd ../lib
flutter build web --release
# O para móvil:
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

---

## 💾 Backups Automáticos

### Configurar Backups Diarios

```bash
# En Windows
npm run backup:programar

# En Linux (configurar cron)
crontab -e
# Agregar:
0 2 * * * cd /ruta/al/proyecto/backend && npm run backup:periodico
```

Ver documentación completa en: [GUIA_RESPALDOS.md](./GUIA_RESPALDOS.md)

---

## 📊 Monitoreo y Logging

### 1. Logs con PM2

```bash
# Ver logs en tiempo real
pm2 logs comandero-backend

# Ver últimos 100 líneas
pm2 logs comandero-backend --lines 100
```

### 2. Monitoreo de Recursos

```bash
pm2 monit
```

### 3. Configurar Rotación de Logs

```bash
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
```

---

## 🔒 Seguridad

### Checklist de Seguridad

- [ ] ✅ Variables de entorno configuradas correctamente
- [ ] ✅ Secretos JWT generados con suficiente entropía
- [ ] ✅ Base de datos con usuario dedicado (no root)
- [ ] ✅ CORS configurado solo para dominios permitidos
- [ ] ✅ Rate limiting activado
- [ ] ✅ Helmet configurado (ya incluido)
- [ ] ✅ HTTPS configurado en el servidor web (Nginx/Apache)
- [ ] ✅ Firewall configurado (solo puertos necesarios abiertos)
- [ ] ✅ Backups automáticos configurados
- [ ] ✅ Logs configurados y monitoreados

### Configurar HTTPS con Nginx (Ejemplo)

```nginx
server {
    listen 443 ssl http2;
    server_name tu-dominio.com;

    ssl_certificate /ruta/a/certificado.crt;
    ssl_certificate_key /ruta/a/llave.key;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## ✅ Verificación Pre-Deployment

### Script de Verificación

Ejecutar antes de desplegar:

```bash
# 1. Verificar que todas las dependencias estén instaladas
npm install

# 2. Verificar que el proyecto compile sin errores
npm run build

# 3. Verificar conexión a la base de datos
tsx scripts/verificar-conexion-db.ts

# 4. Verificar que las migraciones estén aplicadas
tsx scripts/verificar-estructura-bd.ts

# 5. Verificar que el servidor inicie correctamente
npm start
```

---

## 🚀 Proceso de Deployment

### 1. Preparación

```bash
# Actualizar código
git pull origin main

# Instalar nuevas dependencias
npm install

# Compilar
npm run build
```

### 2. Backup de Base de Datos

```bash
npm run backup:database
```

### 3. Aplicar Migraciones (si hay)

```bash
npm run migrate:full
```

### 4. Reiniciar Servicio

```bash
# Con PM2
pm2 restart comandero-backend

# O sin PM2
npm start
```

### 5. Verificar

```bash
# Verificar que el servidor responda
curl http://localhost:3000

# Verificar logs
pm2 logs comandero-backend --lines 50
```

---

## 🆘 Solución de Problemas

### El servidor no inicia

1. Verificar logs: `pm2 logs comandero-backend`
2. Verificar variables de entorno: `cat .env`
3. Verificar puerto: `netstat -ano | findstr :3000` (Windows) o `lsof -i :3000` (Linux)

### Error de conexión a base de datos

1. Verificar credenciales en `.env`
2. Verificar que MySQL esté corriendo
3. Verificar firewall y permisos de usuario

### Errores de CORS

1. Verificar `CORS_ORIGIN` en `.env`
2. Verificar que el dominio del frontend esté incluido

---

## 📞 Soporte

Para más información, consulta:
- [GUIA_RESPALDOS.md](./GUIA_RESPALDOS.md) - Sistema de backups
- [CONFIGURACION_FINAL.md](./CONFIGURACION_FINAL.md) - Configuración general

---

**Última actualización**: 2024-01-XX

