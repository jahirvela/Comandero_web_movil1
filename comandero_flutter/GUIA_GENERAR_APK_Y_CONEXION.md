# 📱 Guía: Generar APK y Configurar Conexión

Esta guía explica cómo generar el APK de la aplicación Flutter y configurar la conexión tanto para pruebas locales como para producción.

---

## 📋 Índice

1. [Generar APK para Pruebas](#generar-apk-para-pruebas)
2. [Conectar Celular a Laptop (Pruebas Locales)](#conectar-celular-a-laptop)
3. [Configurar para Producción (Servidor Privado)](#configurar-para-producción)
4. [Cómo Funciona el Sistema de Conexión](#cómo-funciona-el-sistema)

---

## 📦 Generar APK para Pruebas

### Prerequisitos

- ✅ Flutter SDK instalado
- ✅ Android SDK configurado
- ✅ Proyecto compilando correctamente

### Pasos para Generar APK

#### Opción 1: APK de Debug (Más Rápido, para Pruebas)

```bash
cd comandero_flutter
flutter build apk --debug
```

**Ubicación del APK:**
```
comandero_flutter\build\app\outputs\flutter-apk\app-debug.apk
```

**Ventajas:**
- ✅ Compilación más rápida
- ✅ Útil para pruebas rápidas
- ✅ Permite debugging

**Desventajas:**
- ⚠️ APK más grande
- ⚠️ No optimizado para producción

#### Opción 2: APK de Release (Recomendado para Distribución)

```bash
cd comandero_flutter
flutter build apk --release
```

**Ubicación del APK:**
```
comandero_flutter\build\app\outputs\flutter-apk\app-release.apk
```

**Ventajas:**
- ✅ APK optimizado y más pequeño
- ✅ Mejor rendimiento
- ✅ Listo para distribución

**Desventajas:**
- ⚠️ Compilación más lenta
- ⚠️ No permite debugging

#### Opción 3: APK Split por ABI (APK Más Pequeño)

```bash
cd comandero_flutter
flutter build apk --split-per-abi --release
```

Esto genera APKs separados para cada arquitectura (arm64-v8a, armeabi-v7a, x86_64).

**Ubicación:**
```
comandero_flutter\build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
comandero_flutter\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
comandero_flutter\build\app\outputs\flutter-apk\app-x86_64-release.apk
```

**Recomendación:** Usa `app-arm64-v8a-release.apk` para la mayoría de dispositivos modernos.

---

## 🔌 Conectar Celular a Laptop (Pruebas Locales)

### Escenario: Backend en Laptop, APK en Celular

```
┌─────────────┐         WiFi         ┌─────────────┐
│   Laptop    │ ◄──────────────────► │   Celular   │
│ (Backend)   │    (Misma Red)       │   (APK)     │
│ 192.168.1.5 │                      │             │
└─────────────┘                      └─────────────┘
```

### Paso 1: Obtener IP de la Laptop

**En Windows:**
```powershell
ipconfig
```

Busca la IP de tu adaptador WiFi o Ethernet, por ejemplo:
```
Adaptador de LAN inalámbrica Wi-Fi:
   Dirección IPv4. . . . . . . . . . . . : 192.168.1.5
```

**Anota esta IP**, la necesitarás en el paso 3.

### Paso 2: Iniciar el Backend en la Laptop

```bash
cd comandero_flutter/backend
npm run dev
```

Verifica que el backend esté corriendo en `http://0.0.0.0:3000` (escucha en todas las interfaces).

### Paso 3: Instalar APK en el Celular

1. **Transferir el APK al celular:**
   - Por USB: Conecta el celular y copia el APK
   - Por email: Envía el APK por correo
   - Por Google Drive/Dropbox: Sube y descarga
   - Por WiFi: Usa apps como "Portal" o "Send Anywhere"

2. **Instalar el APK:**
   - Abre el archivo APK en el celular
   - Permite "Fuentes desconocidas" si te lo pide
   - Instala la aplicación

### Paso 4: Configurar IP del Servidor en el APK

Al abrir la aplicación por primera vez, verás la pantalla de login.

1. **Configurar IP manualmente:**
   - En la pantalla de login, busca el botón "Configurar servidor" o similar
   - Ingresa la IP de tu laptop: `192.168.1.5` (la que obtuviste en el Paso 1)
   - Presiona "Probar conexión" o "Guardar"
   - Si la conexión es exitosa, podrás hacer login

2. **O usar detección automática:**
   - La app intentará detectar automáticamente la IP del servidor
   - Si está en la misma red WiFi, debería funcionar automáticamente

### Paso 5: Verificar Conexión

1. **Abre la app en el celular**
2. **Intenta hacer login** con algún usuario
3. **Si funciona:** ✅ Todo está bien configurado
4. **Si no funciona:** Revisa la sección de [Solución de Problemas](#solución-de-problemas)

---

## 🏭 Configurar para Producción (Servidor Privado)

### Escenario: Backend en Servidor Privado con Internet Móvil

```
┌──────────────────┐      Internet       ┌─────────────┐
│  Servidor        │      (Módem/4G)     │  Dispositivos│
│  Privado         │ ◄─────────────────► │  (Tablets/  │
│  192.168.1.100   │                     │  Celulares) │
│  (Backend)       │                     │             │
└──────────────────┘                     └─────────────┘
```

### Paso 1: Configurar Backend en el Servidor

1. **Configurar IP estática en el servidor:**
   - Asigna una IP fija al servidor (ej: `192.168.1.100`)
   - O configura el router para darle siempre la misma IP (DHCP reservation)

2. **Iniciar backend en el servidor:**
   ```bash
   cd comandero_flutter/backend
   npm run build
   npm start
   # O con PM2 para producción:
   pm2 start ecosystem.config.js
   ```

3. **Verificar que el backend esté accesible:**
   ```bash
   # Desde el servidor mismo:
   curl http://localhost:3000/health
   
   # O desde otro dispositivo en la red:
   curl http://192.168.1.100:3000/health
   ```

### Paso 2: Obtener IP del Servidor

**Método 1: IP Local (Si todos están en la misma red)**
- Si los dispositivos están en la misma red WiFi que el servidor
- Usa la IP local del servidor (ej: `192.168.1.100`)

**Método 2: IP Pública (Si el servidor tiene acceso desde internet)**
- Si el servidor tiene IP pública o dominio
- Configura port forwarding en el router
- Usa la IP pública o dominio (ej: `https://mi-servidor.com`)

### Paso 3: Generar APK para Producción

#### Opción A: APK con IP Hardcodeada (Para Servidor Fijo)

Edita `lib/config/api_config.dart` antes de compilar:

```dart
// Cambiar línea 31-34
static const String _productionApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://192.168.1.100:3000/api',  // IP de tu servidor
);
```

Luego compila:
```bash
flutter build apk --release --dart-define=API_ENV=production
```

#### Opción B: APK Configurable (Recomendado)

Mantén el APK configurable y permite que el usuario configure la IP desde la app.

**Ventajas:**
- ✅ Un solo APK para todas las instalaciones
- ✅ Puedes cambiar la IP del servidor sin recompilar
- ✅ Más flexible

**Cómo usar:**
1. Instala el APK en los dispositivos
2. En la pantalla de login, configura la IP del servidor
3. La IP se guarda automáticamente para futuras sesiones

### Paso 4: Instalar APK en Dispositivos

1. **Distribuir el APK:**
   - Copiar a cada dispositivo (USB, email, etc.)
   - O usar un servidor de descarga interno

2. **Instalar en cada dispositivo:**
   - Instalar el APK
   - Configurar la IP del servidor (si usaste Opción B)
   - Probar conexión y login

### Paso 5: Verificar Todo Funciona

1. **Abrir app en dispositivo**
2. **Hacer login** con usuarios de prueba
3. **Verificar que todas las funcionalidades funcionen:**
   - Crear órdenes
   - Ver inventario
   - Imprimir tickets
   - Etc.

---

## 🔍 Cómo Funciona el Sistema de Conexión

### Flujo de Configuración de IP

```
App Inicia
    ↓
¿Hay IP guardada manualmente? → SÍ → Usar IP guardada
    ↓ NO
¿Se detectó IP automáticamente? → SÍ → Usar IP detectada
    ↓ NO
Usar IP por defecto (10.0.2.2 para emulador)
    ↓
Usuario puede configurar IP manualmente desde la app
    ↓
IP se guarda en SharedPreferences
    ↓
Se usa en futuras sesiones
```

### Detección Automática de IP

El sistema intenta detectar automáticamente la IP del servidor:

1. **Detecta la IP del dispositivo móvil** (celular/tablet)
2. **Determina el rango de red** (ej: 192.168.1.x)
3. **Prueba IPs comunes** del mismo rango (192.168.1.1, 192.168.1.2, etc.)
4. **Cuando encuentra el servidor**, guarda esa IP

**Nota:** La detección automática puede tardar algunos segundos.

### Configuración Manual de IP

Si la detección automática falla, el usuario puede configurar la IP manualmente:

1. **Desde la pantalla de login:**
   - Buscar botón "Configurar servidor"
   - Ingresar IP manualmente (ej: `192.168.1.100`)
   - Probar conexión
   - Guardar

2. **La IP se guarda permanentemente** en el dispositivo usando `SharedPreferences`

---

## 🔧 Solución de Problemas

### Problema: "No se puede conectar al servidor"

**Soluciones:**

1. **Verificar que el backend esté corriendo:**
   ```bash
   # En la laptop/servidor:
   curl http://localhost:3000/health
   ```

2. **Verificar que estén en la misma red:**
   - Celular y laptop deben estar en la misma red WiFi
   - Verifica conectividad: `ping 192.168.1.5` (desde celular, si es posible)

3. **Verificar firewall de Windows:**
   - Windows puede estar bloqueando el puerto 3000
   - Permitir puerto 3000 en el firewall:
     ```powershell
     New-NetFirewallRule -DisplayName "Node.js Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
     ```

4. **Verificar IP correcta:**
   - Confirma la IP de la laptop: `ipconfig`
   - Ingresa esa IP exacta en la app

5. **Probar desde navegador del celular:**
   - Abre navegador en el celular
   - Ve a: `http://192.168.1.5:3000/health`
   - Si funciona aquí, el problema es de la app, no de red

### Problema: "Conexión lenta"

**Soluciones:**

1. **Verificar velocidad de red WiFi**
2. **Cerrar otras apps** que usen internet
3. **Acercarse al router WiFi** si la señal es débil

### Problema: "La app no encuentra el servidor automáticamente"

**Soluciones:**

1. **Configurar IP manualmente** (más confiable)
2. **Verificar que estén en la misma red**
3. **Esperar más tiempo** (la detección automática puede tardar)

---

## 📝 Resumen de Comandos

### Generar APK

```bash
# APK Debug (pruebas)
flutter build apk --debug

# APK Release (producción)
flutter build apk --release

# APK Split (más pequeño)
flutter build apk --split-per-abi --release
```

### Ubicación del APK

```
comandero_flutter\build\app\outputs\flutter-apk\app-release.apk
```

### Obtener IP de Windows

```powershell
ipconfig
# Buscar "Dirección IPv4" del adaptador WiFi/Ethernet
```

### Verificar Backend

```bash
# Health check
curl http://localhost:3000/health

# O desde otro dispositivo
curl http://192.168.1.5:3000/health
```

---

## ✅ Checklist para Producción

Antes de instalar el APK en producción:

- [ ] Backend configurado y corriendo en el servidor
- [ ] IP del servidor identificada (local o pública)
- [ ] APK generado con `flutter build apk --release`
- [ ] APK probado en al menos un dispositivo
- [ ] IP del servidor configurada en la app
- [ ] Login funciona correctamente
- [ ] Todas las funcionalidades probadas
- [ ] Documentación de IP del servidor guardada

---

**Última actualización**: 2024  
**Versión**: 1.0.0

