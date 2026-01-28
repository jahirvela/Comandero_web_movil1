# 🔧 Solución: Alertas No Llegan en APK

## 🐛 Problema Identificado

Las alertas no estaban llegando al mesero en el APK porque:

1. **Socket.IO no se estaba conectando correctamente** - Los logs mostraban `socketsCount: 0`
2. **Error en el backend** - `require is not defined` en `routes/index.ts`
3. **socketUrl no usaba la IP correcta** - Usaba `10.0.2.2` en vez de la IP del servidor
4. **Listeners se configuraban antes de la conexión** - No verificaba si Socket.IO estaba conectado

---

## ✅ Cambios Realizados

### 1. Backend: Corregido Error de `require`

**Archivo:** `backend/src/routes/index.ts`

- Cambiado `require('os')` por `import { networkInterfaces } from 'os'`
- Esto corrige el error que aparecía en los logs

### 2. Frontend: Corregido `socketUrl` para Usar IP Correcta

**Archivo:** `lib/config/api_config.dart`

- Ahora `socketUrl` usa la misma lógica de prioridad que `baseUrl`:
  1. IP guardada manualmente por el usuario
  2. IP del servidor detectada automáticamente
  3. IP local detectada del dispositivo
  4. IP por defecto: `192.168.1.32` (para pruebas)

### 3. Frontend: Agregados Logs de Depuración

**Archivo:** `lib/services/socket_service.dart`

- Logs que muestran la URL de conexión de Socket.IO
- Logs cuando se conecta/desconecta con la URL
- Esto ayuda a identificar problemas de conexión

### 4. Frontend: Mejorada Configuración de Listeners

**Archivo:** `lib/controllers/mesero_controller.dart`

- Ahora verifica que Socket.IO esté conectado antes de configurar listeners
- Si no está conectado, espera y luego reconecta
- Configura listeners solo cuando la conexión está establecida

---

## 📱 Próximos Pasos para Probar

### 1. Recompilar el APK

```bash
cd comandero_flutter
flutter build apk --release
```

### 2. Instalar el Nuevo APK en tu Celular

- Desinstala el APK anterior
- Instala el nuevo APK

### 3. Verificar los Logs

Cuando inicies sesión en el APK, busca en los logs del backend:

```
✅ Socket.IO: Conectado exitosamente (socket id: xxxxx)
✅ Socket.IO: URL conectada: http://192.168.1.32:3000
```

Si ves esto, Socket.IO está conectado correctamente.

### 4. Probar el Flujo

1. **Mesero**: Inicia sesión en el APK
2. **Cocinero**: Inicia sesión (puede ser en web o APK)
3. **Cocinero**: Marca una orden como "Iniciar" o "Listo"
4. **Mesero**: Debe recibir la alerta

---

## 🔍 Verificar Conexión de Socket.IO

### En el Backend (Logs)

Busca líneas como:
```
✅ Socket.IO: Conectado exitosamente (socket id: xxxxx)
```

Si ves `socketsCount: 0` cuando se emiten alertas, significa que no hay clientes conectados.

### En el Frontend (Debug)

Los logs del APK mostrarán:
```
📤 Socket: URL de conexión: http://192.168.1.32:3000
✅ Socket.IO: Conectado exitosamente (socket id: xxxxx)
```

---

## ⚠️ Posibles Problemas

### 1. Firewall Bloqueando Conexiones

Si el firewall de Windows está bloqueando el puerto 3000:
- Abre el puerto 3000 en el firewall
- O desactiva temporalmente el firewall para pruebas

### 2. IP Incorrecta

Si la IP de tu laptop cambió:
- Verifica la IP: `ipconfig` en Windows
- Usa la pantalla de configuración en el APK para actualizar la IP

### 3. Socket.IO No Se Conecta

Si ves errores de conexión:
- Verifica que el backend esté corriendo
- Verifica que puedas acceder a `http://192.168.1.32:3000/api/health` desde el celular
- Revisa los logs del backend para ver errores de autenticación

---

## 📝 Notas

- Los logs agregados ayudarán a identificar problemas de conexión
- Si Socket.IO se conecta correctamente, las alertas deberían funcionar
- Si aún hay problemas, revisa los logs del backend cuando se emiten alertas

---

## 🔄 Si Aún No Funciona

1. Verifica que ambos dispositivos (laptop y celular) estén en la misma red WiFi
2. Verifica que el backend esté accesible desde el celular: `http://192.168.1.32:3000/api/health`
3. Revisa los logs del backend cuando el cocinero marca una orden
4. Busca errores de conexión en los logs del backend

