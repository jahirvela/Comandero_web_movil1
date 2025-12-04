# 🌐 Guía de Despliegue: Módem 4G + VPS

## 📋 Contexto del Escenario

El sistema Comandix se despliega en un escenario real:

- **Backend**: Servidor VPS remoto (administrado por el Ing. Ethan)
- **Red del puesto**: Módem 4G con chip (Telcel/Movistar/AT&T)
- **Dispositivos**: Tablets conectadas por WiFi al módem
- **Conexión**: Tablets → WiFi → Módem 4G → Internet → VPS

---

## 🎯 Objetivo 1: Configuración de URLs y Entornos

### Backend

#### Variables de Entorno

Crear archivo `.env.production` en `backend/`:

```env
# ============================================
# ENTORNO
# ============================================
NODE_ENV=production

# ============================================
# SERVIDOR
# ============================================
PORT=3000
API_BASE_URL=https://api.comandix.com  # URL pública del VPS

# ============================================
# BASE DE DATOS
# ============================================
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_USER=comandix_user
DATABASE_PASSWORD=tu_password_seguro
DATABASE_NAME=comandero
DATABASE_CONNECTION_LIMIT=20

# ============================================
# JWT
# ============================================
JWT_ACCESS_SECRET=tu_secret_muy_largo_y_seguro_minimo_32_caracteres
JWT_REFRESH_SECRET=otro_secret_diferente_muy_largo_y_seguro_minimo_32_caracteres
JWT_ACCESS_EXPIRES_IN=30m
JWT_REFRESH_EXPIRES_IN=7d

# ============================================
# CORS
# ============================================
# IMPORTANTE: Agregar todas las URLs desde donde se accederá
# Ejemplo: https://app.comandix.com, https://admin.comandix.com
CORS_ORIGIN=https://app.comandix.com,https://admin.comandix.com

# ============================================
# RATE LIMITING
# ============================================
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX=100
RATE_LIMIT_LOGIN_WINDOW_MS=60000
RATE_LIMIT_LOGIN_MAX=5

# ============================================
# LOGGING
# ============================================
LOG_LEVEL=info
LOG_PRETTY=false

# ============================================
# IMPRESORA
# ============================================
PRINTER_TYPE=pos80
PRINTER_INTERFACE=tcp
PRINTER_HOST=192.168.1.100  # IP local de la impresora en el puesto
PRINTER_PORT=9100
```

#### Desarrollo Local

Para desarrollo, usar `.env` (o `.env.development`):

```env
NODE_ENV=development
PORT=3000
# API_BASE_URL no es necesario en desarrollo
CORS_ORIGIN=http://localhost:8080,http://localhost:3000
LOG_LEVEL=debug
LOG_PRETTY=true
```

---

### Frontend Flutter

#### Configuración por Ambiente

El frontend usa variables de compilación para cambiar entre desarrollo y producción.

**Desarrollo (por defecto):**
```bash
flutter run
# Usa: http://localhost:3000 o http://10.0.2.2:3000
```

**Producción:**
```bash
# Opción 1: Variable de entorno
flutter run --dart-define=API_ENV=production --dart-define=API_URL=https://api.comandix.com

# Opción 2: Compilar con configuración
flutter build apk --dart-define=API_ENV=production --dart-define=API_URL=https://api.comandix.com
```

**Personalizado (para testing):**
```bash
flutter run --dart-define=CUSTOM_API_URL=https://192.168.1.100:3000
```

#### Cambiar URL del Servidor

**Método 1: Variables de compilación (recomendado para producción)**

Editar `lib/config/api_config.dart` y cambiar:

```dart
static const String _productionApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://api.comandix.com', // ← Cambiar aquí
);
```

Luego compilar:
```bash
flutter build apk --dart-define=API_URL=https://tu-servidor.com
```

**Método 2: Configuración manual (para testing rápido)**

Editar directamente `lib/config/api_config.dart`:

```dart
static const String _productionApiUrl = 'https://192.168.1.100:3000';
```

---

## 🎯 Objetivo 2: Robustez ante Internet Móvil

### Características Implementadas

#### 1. Reintentos Automáticos (HTTP)

El `ApiService` ahora incluye:

- **Reintentos automáticos**: 3 intentos en producción, 2 en desarrollo
- **Backoff exponencial**: Espera progresiva entre reintentos
- **Errores recuperables**: Solo reintenta en errores de red/timeout

**Ejemplo de uso:**
```dart
// Automáticamente reintenta si hay error de conexión
final response = await apiService.get('/mesas');
```

#### 2. Reconexión Automática (Socket.IO)

El `SocketService` incluye:

- **Reconexión automática**: Hasta 10 intentos
- **Delay progresivo**: 1-5 segundos entre intentos
- **Estado observable**: Stream para mostrar estado de conexión en UI

**Ejemplo de uso:**
```dart
// Escuchar cambios de estado
socketService.connectionStateStream.listen((state) {
  if (state == SocketConnectionState.connected) {
    print('Conectado');
  } else if (state == SocketConnectionState.reconnecting) {
    print('Reconectando...');
  }
});
```

#### 3. Verificación de Conectividad

```dart
// Verificar si hay conexión con el servidor
final tieneConexion = await apiService.checkConnection();
if (!tieneConexion) {
  // Mostrar mensaje al usuario
}
```

#### 4. Manejo de Errores Amigable

```dart
try {
  await apiService.post('/ordenes', data: ordenData);
} on DioException catch (e) {
  final mensaje = ApiService.getErrorMessage(e);
  // Mostrar mensaje amigable al usuario
  showDialog(context: context, child: Text(mensaje));
}
```

---

## 🎯 Objetivo 3: Seguridad para Servidor Público

### Medidas Implementadas

#### 1. Helmet

Configurado automáticamente en `server.ts`:
- Headers de seguridad HTTP
- Prevención de XSS
- Prevención de clickjacking

#### 2. Rate Limiting

- **General**: 100 requests/minuto por IP
- **Login**: 5 intentos/minuto por IP (protección contra fuerza bruta)

#### 3. Logs Seguros

- **Producción**: No muestra stack traces ni detalles sensibles
- **Desarrollo**: Muestra detalles completos para debugging

#### 4. CORS Configurado

Solo permite conexiones desde dominios autorizados.

---

## 🎯 Objetivo 4: Flujo Completo "Puesto de Barbacoa"

### Escenario Real

```
┌─────────────┐
│   Tablets    │
│  (Meseros,  │
│  Cocineros) │
└──────┬──────┘
       │ WiFi
       ▼
┌─────────────┐
│  Módem 4G   │
│  (Chip)     │
└──────┬──────┘
       │ Internet Móvil
       ▼
┌─────────────┐
│     VPS     │
│  (Backend)  │
└─────────────┘
```

### Pasos de Configuración

#### 1. Configurar Backend en VPS

```bash
# En el VPS
cd /ruta/del/backend
cp .env.example .env.production
# Editar .env.production con las configuraciones reales
npm install
npm run build
npm start
```

#### 2. Configurar Dominio (Opcional pero Recomendado)

**Con Nginx + Let's Encrypt:**

```nginx
# /etc/nginx/sites-available/comandix
server {
    listen 80;
    server_name api.comandix.com;

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

**Con Certbot (HTTPS):**
```bash
sudo certbot --nginx -d api.comandix.com
```

#### 3. Compilar Flutter para Producción

```bash
cd comandero_flutter

# Android
flutter build apk --release \
  --dart-define=API_ENV=production \
  --dart-define=API_URL=https://api.comandix.com

# O si usas IP directamente
flutter build apk --release \
  --dart-define=API_ENV=production \
  --dart-define=API_URL=https://192.168.1.100:3000
```

#### 4. Instalar en Tablets

```bash
# Transferir el APK a las tablets e instalar
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### 5. Configurar WiFi en Tablets

1. Conectar tablets al WiFi del módem
2. Verificar que tengan Internet
3. Abrir la app Comandix
4. La app se conectará automáticamente al VPS

---

### Pruebas del Flujo Completo

#### ✅ Login

1. Abrir app en tablet
2. Ingresar credenciales
3. Verificar que se conecte al VPS
4. Verificar que Socket.IO se conecte

#### ✅ Operaciones CRUD

1. Crear una mesa
2. Crear una orden
3. Agregar productos
4. Cambiar estado de orden
5. Verificar que todo se guarde en la BD del VPS

#### ✅ Tiempo Real

1. Abrir app en dos tablets
2. Crear orden en una
3. Verificar que aparezca en tiempo real en la otra

#### ✅ Cortes de Red

1. Desconectar WiFi del módem
2. Intentar crear una orden
3. Verificar que muestre mensaje de "sin conexión"
4. Reconectar WiFi
5. Verificar que Socket.IO se reconecte automáticamente
6. Verificar que las peticiones HTTP se reintenten

---

## 📝 Checklist de Despliegue

### Backend

- [ ] Crear `.env.production` con todas las variables
- [ ] Configurar `API_BASE_URL` con el dominio/IP del VPS
- [ ] Configurar `CORS_ORIGIN` con las URLs permitidas
- [ ] Verificar que `NODE_ENV=production`
- [ ] Configurar HTTPS (Nginx + Let's Encrypt)
- [ ] Probar que el backend responda en `https://api.comandix.com/api/health`

### Frontend

- [ ] Compilar con `API_ENV=production`
- [ ] Configurar `API_URL` con la URL del VPS
- [ ] Probar login desde tablet
- [ ] Verificar que Socket.IO se conecte
- [ ] Probar operaciones CRUD
- [ ] Probar reconexión después de cortes

### Red

- [ ] Verificar que el módem tenga Internet
- [ ] Verificar que las tablets se conecten al WiFi
- [ ] Probar ping desde tablet al VPS
- [ ] Verificar que no haya firewall bloqueando

---

## 🐛 Solución de Problemas

### Error: "No se pudo conectar al servidor"

**Causas posibles:**
1. El VPS no está accesible desde Internet
2. Firewall bloqueando el puerto 3000
3. URL incorrecta en `API_URL`

**Solución:**
1. Verificar que el VPS tenga el puerto 3000 abierto
2. Probar desde navegador: `https://api.comandix.com/api/health`
3. Verificar `API_URL` en la app

### Error: "CORS policy"

**Causa:** El dominio de la app no está en `CORS_ORIGIN`

**Solución:**
1. Agregar el dominio a `CORS_ORIGIN` en `.env.production`
2. Reiniciar el backend

### Socket.IO no se conecta

**Causas posibles:**
1. WebSocket bloqueado por firewall
2. URL incorrecta
3. Token inválido

**Solución:**
1. Verificar que el puerto 3000 permita WebSocket
2. Verificar `SOCKET_URL` en la app
3. Verificar que el login haya sido exitoso

### App se cuelga después de cortes de red

**Causa:** No se está manejando correctamente la reconexión

**Solución:**
1. Verificar que `SocketService` tenga reconexión habilitada
2. Verificar que `ApiService` tenga reintentos configurados
3. Agregar manejo de errores en la UI

---

## 📚 Referencias

- [Documentación de Dio (HTTP Client)](https://pub.dev/packages/dio)
- [Documentación de Socket.IO Client](https://pub.dev/packages/socket_io_client)
- [Nginx Reverse Proxy](https://nginx.org/en/docs/http/ngx_http_proxy_module.html)
- [Let's Encrypt](https://letsencrypt.org/)

---

**Última actualización:** 2024-01-15  
**Versión:** 1.0.0

