# 🚀 Guía: Despliegue en Producción

Esta guía explica cómo desplegar el sistema completo en un servidor privado para que funcione tanto desde navegador web como desde APK en dispositivos móviles.

---

## 🎯 Escenario Final

```
┌─────────────────────────────────────────────────────────┐
│              SERVIDOR PRIVADO                           │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Backend (Node.js) - Puerto 3000                │   │
│  │  MySQL Database                                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Aplicación Web (Flutter Web)                   │   │
│  │  www.comandix.com (ejemplo)                     │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Modem con Chip (Internet 4G)                  │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
          │                    │
          │                    │
    ┌─────┴─────┐        ┌─────┴─────┐
    │           │        │           │
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│ Chrome  │ │ Chrome  │ │ Tablet  │ │ Celular │
│ (Web)   │ │ (Web)   │ │ (APK)   │ │ (APK)   │
│ Admin   │ │ Mesero  │ │ Mesero  │ │ Cociner │
└─────────┘ └─────────┘ └─────────┘ └─────────┘
```

---

## ✅ Respuesta Rápida

**SÍ, una vez desplegado correctamente:**

1. ✅ **Administrador** puede acceder desde Chrome a `www.comandix.com` y usar el sistema
2. ✅ **Meseros, cocineros, cajeros** pueden usar el APK en tablets/celulares
3. ✅ **Todo funciona** en tiempo real entre web y móviles
4. ✅ **Comunicación local** (no consume datos del chip)
5. ✅ **Internet del modem** solo se usa si el servidor necesita conectarse a internet externo

---

## 📋 Requisitos del Servidor

### Hardware Mínimo

- **CPU**: 2+ cores
- **RAM**: 4GB+ (recomendado 8GB)
- **Disco**: 20GB+ espacio libre
- **Red**: Conexión estable (WiFi o Ethernet)

### Software Requerido

- **Sistema Operativo**: Linux (Ubuntu Server recomendado) o Windows Server
- **Node.js**: >= 20.0.0
- **MySQL**: 8.0+
- **Nginx** (opcional, recomendado para servir la web)
- **PM2** (recomendado para mantener el backend corriendo)

---

## 🔧 Paso 1: Configurar el Servidor

### 1.1 Instalar Software

```bash
# Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# MySQL
sudo apt-get install mysql-server

# PM2 (para mantener el backend corriendo)
sudo npm install -g pm2

# Nginx (para servir la aplicación web)
sudo apt-get install nginx
```

### 1.2 Configurar IP Estática

Asigna una IP fija al servidor (ejemplo: `192.168.1.100`)

**En Linux:**
```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

```bash
sudo netplan apply
```

---

## 📦 Paso 2: Subir el Proyecto al Servidor

### 2.1 Subir Archivos

Puedes usar:
- **SCP/SFTP**: `scp -r comandero_flutter user@servidor:/ruta/`
- **Git**: Clonar el repositorio en el servidor
- **USB**: Copiar archivos directamente

### 2.2 Estructura en el Servidor

```
/home/comandero/
├── backend/          # Backend Node.js
├── web/              # Aplicación Flutter Web compilada
└── database/         # Backups de base de datos
```

---

## ⚙️ Paso 3: Configurar Backend

### 3.1 Variables de Entorno

Crea archivo `.env` en `backend/`:

```env
# Entorno
NODE_ENV=production
PORT=3000

# Base de Datos
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_USER=comandero_user
DATABASE_PASSWORD=tu_password_seguro
DATABASE_NAME=comandero
DATABASE_CONNECTION_LIMIT=20

# JWT
JWT_ACCESS_SECRET=tu_secret_muy_largo_y_seguro_minimo_32_caracteres
JWT_REFRESH_SECRET=otro_secret_muy_largo_y_seguro_minimo_32_caracteres
JWT_ACCESS_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# CORS - IMPORTANTE: Configurar tu dominio
CORS_ORIGIN=https://www.comandix.com,http://www.comandix.com,http://192.168.1.100

# API Base URL (para Swagger)
API_BASE_URL=https://www.comandix.com

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX=1000
RATE_LIMIT_LOGIN_WINDOW_MS=60000
RATE_LIMIT_LOGIN_MAX=5

# Logs
LOG_LEVEL=info
LOG_PRETTY=false

# Impresora (si aplica)
PRINTER_TYPE=pos80
PRINTER_INTERFACE=usb
PRINTER_DEVICE=XP-80
```

### 3.2 Instalar Dependencias

```bash
cd backend
npm install
```

### 3.3 Configurar Base de Datos

```bash
# Crear base de datos
mysql -u root -p
CREATE DATABASE comandero;
CREATE USER 'comandero_user'@'localhost' IDENTIFIED BY 'tu_password_seguro';
GRANT ALL PRIVILEGES ON comandero.* TO 'comandero_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# Ejecutar migraciones
cd backend
npm run crear-tabla-ingredientes
npm run optimizar-indices
```

### 3.4 Compilar Backend

```bash
cd backend
npm run build
```

### 3.5 Iniciar con PM2

```bash
cd backend
pm2 start ecosystem.config.js
pm2 save
pm2 startup  # Para iniciar automáticamente al reiniciar
```

---

## 🌐 Paso 4: Compilar y Desplegar Aplicación Web

### 4.1 Compilar Flutter Web

```bash
cd comandero_flutter
flutter build web --release --dart-define=API_ENV=production --dart-define=API_URL=https://www.comandix.com/api
```

**O si usas IP en lugar de dominio:**

```bash
flutter build web --release --dart-define=API_ENV=production --dart-define=API_URL=http://192.168.1.100:3000/api
```

### 4.2 Ubicación de Archivos Compilados

```
comandero_flutter/build/web/
├── index.html
├── main.dart.js
├── assets/
└── ...
```

### 4.3 Configurar Nginx

Crea archivo `/etc/nginx/sites-available/comandix`:

```nginx
server {
    listen 80;
    server_name www.comandix.com comandix.com;

    # Redirigir a HTTPS (si tienes certificado SSL)
    # return 301 https://$server_name$request_uri;

    # O servir directamente en HTTP (si no tienes SSL)
    root /home/comandero/web;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy para API
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Proxy para Socket.IO
    location /socket.io {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

```bash
# Habilitar sitio
sudo ln -s /etc/nginx/sites-available/comandix /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 4.4 Copiar Archivos Web

```bash
# Copiar archivos compilados
sudo cp -r comandero_flutter/build/web/* /home/comandero/web/
sudo chown -R www-data:www-data /home/comandero/web
```

---

## 📱 Paso 5: Configurar APK para Producción

### Opción A: APK con URL Hardcodeada

Antes de compilar, edita `lib/config/api_config.dart`:

```dart
static const String _productionApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://www.comandix.com/api',  // Tu dominio
);
```

Luego compila:
```bash
flutter build apk --release --dart-define=API_ENV=production
```

### Opción B: APK Configurable (Recomendado)

Compila el APK normal (sin cambios):
```bash
flutter build apk --release
```

Los usuarios configurarán la IP/URL del servidor desde la app al instalarla.

**Ventaja:** Un solo APK para todas las instalaciones.

---

## 🔐 Paso 6: Configurar Dominio (Opcional)

### Si Tienes Dominio (www.comandix.com)

1. **Configurar DNS:**
   - A record: `www.comandix.com` → IP pública del servidor
   - O si tienes IP privada, usar servicio como No-IP o DuckDNS

2. **Configurar SSL (Recomendado):**
   ```bash
   sudo apt-get install certbot python3-certbot-nginx
   sudo certbot --nginx -d www.comandix.com
   ```

### Si NO Tienes Dominio

Usa la IP del servidor directamente:
- **Web**: `http://192.168.1.100`
- **API**: `http://192.168.1.100:3000/api`

---

## ✅ Paso 7: Verificar que Todo Funciona

### 7.1 Verificar Backend

```bash
# Health check
curl http://localhost:3000/health

# O desde otro dispositivo
curl http://192.168.1.100:3000/health
```

### 7.2 Verificar Web

1. Abre navegador
2. Ve a `https://www.comandix.com` (o `http://192.168.1.100`)
3. Deberías ver la pantalla de login
4. Intenta hacer login

### 7.3 Verificar APK

1. Instala el APK en un dispositivo
2. Configura la IP/URL del servidor
3. Intenta hacer login
4. Verifica que funcione

---

## 🔄 Flujo de Uso en Producción

### Escenario 1: Administrador desde Chrome

1. Abre Chrome
2. Va a `www.comandix.com`
3. Hace login como administrador
4. Puede gestionar todo: usuarios, inventario, menú, reportes, etc.

### Escenario 2: Mesero desde Tablet (APK)

1. Abre la app en la tablet
2. Hace login como mesero
3. Puede crear órdenes, ver mesas, enviar a cocina, etc.
4. **Todo se sincroniza en tiempo real** con el administrador en Chrome

### Escenario 3: Cocinero desde Celular (APK)

1. Abre la app en el celular
2. Hace login como cocinero
3. Ve las órdenes que el mesero creó
4. Actualiza estados, marca tiempo estimado
5. **El mesero y administrador ven los cambios en tiempo real**

### Escenario 4: Cajero desde Tablet (APK)

1. Abre la app en la tablet
2. Hace login como cajero
3. Ve las órdenes que el mesero envió
4. Procesa pagos, imprime tickets
5. **Todo se sincroniza en tiempo real**

---

## 🌐 Configuración de Red

### Red Local (Recomendado)

```
Servidor: 192.168.1.100 (IP fija)
Dispositivos: 192.168.1.101-254 (DHCP)
Router: 192.168.1.1
```

**Ventajas:**
- ✅ Comunicación rápida (red local)
- ✅ No consume datos del chip
- ✅ Funciona aunque el chip se quede sin saldo

### Internet del Modem

El modem con chip se conecta al servidor para:
- ✅ Actualizaciones del sistema (opcional)
- ✅ Backups en la nube (opcional)
- ✅ Acceso remoto (opcional)

**NO se usa para:**
- ❌ Comunicación entre dispositivos y servidor (es local)
- ❌ Sincronización de datos (es local)

---

## 📝 Checklist de Despliegue

Antes de decir "listo", verifica:

### Backend
- [ ] Backend compilado y corriendo con PM2
- [ ] Base de datos creada y migraciones ejecutadas
- [ ] Variables de entorno configuradas
- [ ] CORS configurado con el dominio/IP correcto
- [ ] Health check funciona: `curl http://localhost:3000/health`

### Web
- [ ] Aplicación web compilada
- [ ] Archivos copiados a `/home/comandero/web`
- [ ] Nginx configurado y corriendo
- [ ] Dominio/IP accesible desde navegador
- [ ] Login funciona desde Chrome

### APK
- [ ] APK generado para producción
- [ ] APK probado en al menos un dispositivo
- [ ] IP/URL del servidor configurable desde la app

### Red
- [ ] Servidor con IP estática configurada
- [ ] Todos los dispositivos en la misma red
- [ ] Firewall permite puerto 3000 y 80/443
- [ ] Modem conectado (si aplica)

### Pruebas
- [ ] Login funciona desde web
- [ ] Login funciona desde APK
- [ ] Crear orden desde mesero (APK)
- [ ] Ver orden en cocinero (APK)
- [ ] Ver orden en administrador (web)
- [ ] Sincronización en tiempo real funciona
- [ ] Imprimir ticket funciona

---

## 🎯 Respuesta Final

**SÍ, una vez desplegado correctamente:**

1. ✅ **Administrador** puede entrar desde Chrome a `www.comandix.com` y usar el sistema completo
2. ✅ **Meseros, cocineros, cajeros** pueden usar el APK en tablets/celulares
3. ✅ **Todo funciona en tiempo real** - cambios en un dispositivo se ven en todos
4. ✅ **Comunicación local** - no consume datos del chip
5. ✅ **Sistema completo y funcional** para uso en el restaurante

**Lo único que necesitas hacer:**
1. Subir el proyecto al servidor
2. Configurar las variables de entorno
3. Compilar y desplegar la web
4. Generar el APK
5. Instalar el APK en los dispositivos
6. Configurar la IP/URL del servidor en cada dispositivo

---

## 📚 Documentación Adicional

- `GUIA_GENERAR_APK_Y_CONEXION.md` - Cómo generar APK y configurar conexión
- `ESTADO_PRODUCCION.md` - Estado del sistema y optimizaciones
- `CHECKLIST_PRODUCCION.md` - Checklist completo de producción

---

**Última actualización**: 2024  
**Versión**: 1.0.0

