# 📱 Resumen: Despliegue con Módem 4G + VPS

## 🎯 ¿Qué se hizo?

Se adaptó todo el proyecto Comandix para que funcione correctamente en un escenario real de producción:

- **Backend en un servidor remoto (VPS)**
- **Tablets conectadas por WiFi a un módem 4G con chip**
- **Robustez ante cortes de Internet y latencia variable**

---

## ✅ Cambios Realizados

### 1. Configuración de URLs (Backend + Flutter)

#### Backend

Ahora todas las URLs se configuran desde variables de entorno:

- **`.env.production`**: Para el servidor en producción
- **`.env`**: Para desarrollo local

**Lo importante:** Ya no hay URLs fijas de `localhost`. Todo se configura desde `.env`.

**Variables nuevas:**
- `API_BASE_URL`: URL pública del VPS (ej: `https://api.comandix.com`)
- `CORS_ORIGIN`: URLs permitidas para conectarse (separadas por comas)

#### Flutter

El frontend ahora detecta automáticamente si está en desarrollo o producción:

- **Desarrollo**: Usa `localhost` o `10.0.2.2` (emulador)
- **Producción**: Usa la URL del VPS que configures

**Para cambiar la URL del servidor:**

1. **Opción 1 (Recomendada)**: Al compilar la app:
   ```bash
   flutter build apk --dart-define=API_ENV=production --dart-define=API_URL=https://api.comandix.com
   ```

2. **Opción 2**: Editar `lib/config/api_config.dart` y cambiar:
   ```dart
   static const String _productionApiUrl = 'https://tu-servidor.com';
   ```

---

### 2. Robustez ante Internet Móvil

#### Reintentos Automáticos (HTTP)

Si una petición falla por problemas de red, la app automáticamente:

- **Reintenta 3 veces** (en producción)
- **Espera progresivamente** entre intentos (1s, 2s, 3s)
- **Solo reintenta** en errores de conexión (no en errores del servidor)

**Ejemplo:** Si creas una orden y se corta el Internet, la app esperará y reintentará automáticamente cuando vuelva la conexión.

#### Reconexión Automática (Socket.IO)

El sistema de tiempo real ahora:

- **Se reconecta automáticamente** si se pierde la conexión
- **Intenta hasta 10 veces** con delays progresivos
- **Muestra el estado** de conexión (conectado, desconectado, reconectando)

**En la app puedes:**
- Ver un icono verde cuando está conectado
- Ver un icono rojo cuando está desconectado
- Ver "Reconectando..." cuando está intentando volver a conectar

#### Manejo de Errores Amigable

Ahora cuando hay problemas de conexión, la app muestra mensajes claros:

- "No se pudo conectar al servidor. Verifica tu conexión a Internet."
- "Tiempo de espera agotado. Verifica tu conexión a Internet."
- "El servidor no está disponible. Intenta más tarde."

**No se rompe la app**, solo muestra un mensaje y permite reintentar.

---

### 3. Seguridad para Servidor Público

#### Protección contra Ataques

- **Rate Limiting**: Limita cuántas peticiones puede hacer una IP
  - General: 100 peticiones por minuto
  - Login: 5 intentos por minuto (protección contra fuerza bruta)

- **Helmet**: Headers de seguridad HTTP automáticos

- **Logs Seguros**: En producción no se muestran detalles sensibles ni stack traces

#### CORS Configurado

Solo permite conexiones desde dominios autorizados (configurados en `CORS_ORIGIN`).

---

## 📋 Cómo Configurar para Producción

### Paso 1: Backend en el VPS

1. **Crear archivo `.env.production`** en `backend/`:

```env
NODE_ENV=production
PORT=3000
API_BASE_URL=https://api.comandix.com  # ← URL de tu VPS
CORS_ORIGIN=https://app.comandix.com   # ← URLs permitidas

# ... resto de variables (BD, JWT, etc.)
```

2. **Iniciar el backend:**
```bash
npm run build
npm start
```

### Paso 2: Compilar Flutter

```bash
cd comandero_flutter

# Compilar para Android
flutter build apk --release \
  --dart-define=API_ENV=production \
  --dart-define=API_URL=https://api.comandix.com
```

### Paso 3: Instalar en Tablets

1. Transferir el APK a las tablets
2. Instalar
3. Conectar tablets al WiFi del módem
4. Abrir la app

**¡Listo!** La app se conectará automáticamente al VPS.

---

## 🔄 ¿Qué Pasa si se Corta el Internet?

### Escenario: Módem pierde señal

1. **La app detecta** que no hay conexión
2. **Muestra mensaje** "Sin conexión a Internet"
3. **Socket.IO intenta reconectar** automáticamente
4. **Cuando vuelve el Internet:**
   - Socket.IO se reconecta solo
   - Las peticiones HTTP se reintentan automáticamente
   - Todo vuelve a funcionar sin intervención

**No necesitas hacer nada**, todo es automático.

---

## 📁 Archivos Modificados

### Backend

- `src/config/env.ts` - Variables de entorno
- `src/config/swagger.ts` - URLs dinámicas
- `src/config/rate-limit.ts` - Rate limiting para login
- `src/middlewares/error-handler.ts` - Logs seguros en producción
- `src/server.ts` - Socket.IO optimizado para móvil
- `src/auth/auth.routes.ts` - Rate limiting en login

### Frontend

- `lib/config/api_config.dart` - Configuración por ambiente
- `lib/services/api_service.dart` - Reintentos automáticos
- `lib/services/socket_service.dart` - Reconexión automática y estado

### Documentación

- `backend/docs/deploy-network.md` - Guía completa de despliegue

---

## 🎯 Resumen para Mario

**¿Qué cambió?**

1. **URLs configurables**: Ya no hay `localhost` fijo. Todo se configura desde variables.

2. **Robustez ante cortes**: Si se corta el Internet, la app:
   - Reintenta automáticamente
   - Se reconecta sola
   - Muestra mensajes claros

3. **Seguridad mejorada**: Protección contra ataques y logs seguros.

**¿Qué necesitas hacer cuando tengas el VPS?**

1. Crear `.env.production` con la URL del VPS
2. Compilar Flutter con `--dart-define=API_URL=...`
3. Instalar en tablets
4. ¡Listo!

**¿Funciona en desarrollo local?**

Sí, todo sigue funcionando igual. Los cambios son compatibles con desarrollo local.

---

## ✅ Checklist Final

- [x] URLs configurables desde variables de entorno
- [x] Reintentos automáticos en HTTP
- [x] Reconexión automática en Socket.IO
- [x] Manejo robusto de errores
- [x] Rate limiting para login
- [x] Logs seguros en producción
- [x] Socket.IO optimizado para móvil
- [x] Documentación completa

**Todo está listo para producción.** 🚀

---

**Última actualización:** 2024-01-15

