# Documentación Técnica: Implementación de Alertas en Tiempo Real (Mesero → Cocinero)

## Resumen Ejecutivo

Este documento detalla todos los intentos realizados para implementar el sistema de alertas en tiempo real desde el rol de mesero hacia el rol de cocinero usando Socket.IO, los errores encontrados durante el proceso, y las soluciones técnicas aplicadas.

**Estado Actual:** En proceso de resolución - Problema crítico identificado: el backend autentica sockets con el usuario incorrecto (mesero ID: 2) cuando debería autenticar con el cocinero (ID: 3).

---

## 1. Problema Inicial

### Descripción
Se requiere implementar un sistema de alertas en tiempo real donde:
- El **mesero** puede enviar alertas (demora, cancelación, modificación) relacionadas con órdenes
- El **cocinero** debe recibir estas alertas en tiempo real en su interfaz
- La comunicación debe ser bidireccional y estable usando Socket.IO

### Requisitos Técnicos
- Backend: Node.js/TypeScript con Socket.IO
- Frontend: Flutter/Dart con `socket_io_client`
- Autenticación: JWT tokens almacenados en `flutter_secure_storage`
- Roles: mesero, cocinero, administrador, cajero, capitán

---

## 2. Arquitectura Inicial

### Flujo Esperado
```
Mesero (Frontend) 
  → Emite evento 'cocina.alerta' 
  → Backend recibe y re-emite 
  → Cocinero (Frontend) recibe y muestra en UI
```

### Archivos Involucrados
- **Backend:**
  - `backend/src/realtime/socket.ts` - Configuración Socket.IO
  - `backend/src/modules/alertas/alertas.service.ts` - Lógica de alertas
  - `backend/src/modules/alertas/alertas.routes.ts` - Endpoints REST

- **Frontend:**
  - `lib/services/socket_service.dart` - Servicio Socket.IO
  - `lib/controllers/cocinero_controller.dart` - Controlador del cocinero
  - `lib/views/mesero/alert_to_kitchen_modal.dart` - UI para enviar alertas
  - `lib/services/alertas_service.dart` - Servicio de alertas

---

## 3. Intentos de Implementación

### Intento 1: Implementación Básica con Eventos Socket.IO

**Enfoque:**
- El mesero emite directamente el evento `cocina.alerta` vía Socket.IO
- El backend re-emite el evento a todos los sockets en el room `role:cocinero`
- El cocinero escucha el evento `cocina.alerta` y actualiza su UI

**Código Implementado:**
```dart
// Frontend - Mesero
SocketService().emit('cocina.alerta', payload);

// Backend - socket.ts
socket.on('cocina.alerta', (payload) => {
  io.to('role:cocinero').emit('cocina.alerta', alertData);
});

// Frontend - Cocinero
socketService.onCocinaAlerta((data) {
  // Procesar y mostrar alerta
});
```

**Errores Encontrados:**
1. ❌ El cocinero no recibía las alertas
2. ❌ El socket del cocinero se desconectaba al hacer login
3. ❌ El socket se conectaba con el rol incorrecto (mesero en lugar de cocinero)

**Causa Raíz Identificada:**
- El socket se conectaba con el token del usuario anterior (mesero) en lugar del token actual (cocinero)
- No había verificación de usuario/rol después de la conexión

---

### Intento 2: Verificación de Usuario/Rol Post-Conexión

**Enfoque:**
- Agregar verificación en el evento `connected` para comparar el usuario del socket con el del storage
- Si hay desajuste, desconectar y reconectar con el token correcto

**Código Implementado:**
```dart
// socket_service.dart
_socket!.on('connected', (data) async {
  final user = data['user'];
  final storedUserId = await _storage.read(key: 'userId');
  
  if (storedUserId != user['id']) {
    // Desconectar y reconectar
    disconnectCompletely();
    await connect();
  }
});
```

**Errores Encontrados:**
1. ❌ Bucle infinito de reconexión
2. ❌ El backend seguía devolviendo el usuario incorrecto (mesero ID: 2) incluso cuando el frontend enviaba el token del cocinero (ID: 3)
3. ❌ Logs en bucle en la consola

**Causa Raíz Identificada:**
- El backend estaba usando `socket.user` del middleware que podía estar en caché
- No había re-autenticación en `handleConnection`

---

### Intento 3: Mejora de la Desconexión y Limpieza de Tokens

**Enfoque:**
- Mejorar `disconnectCompletely()` para limpiar completamente el socket
- Agregar delays después de logout para asegurar que el token se elimine completamente
- Verificar el token antes de conectar

**Código Implementado:**
```dart
// auth_controller.dart - logout()
await SocketService().disconnectCompletely();
await Future.delayed(const Duration(milliseconds: 500));
await _storage.delete(key: 'accessToken');
await _storage.deleteAll();

// socket_service.dart - connect()
final token = await _storage.read(key: 'accessToken');
// Decodificar y verificar token antes de conectar
```

**Errores Encontrados:**
1. ❌ El backend seguía autenticando con el usuario incorrecto
2. ❌ El token se leía correctamente del storage (userId: 3, role: cocinero)
3. ❌ El backend decodificaba el token pero devolvía usuario incorrecto (mesero ID: 2)

**Causa Raíz Identificada:**
- El backend estaba usando `socket.user` asignado por el middleware en lugar de re-autenticar en `handleConnection`
- Posible caché del usuario en el objeto socket

---

### Intento 4: Re-autenticación Forzada en handleConnection

**Enfoque:**
- Modificar `handleConnection` para que SIEMPRE re-autentique usando el token del handshake actual
- No confiar en `socket.user` del middleware
- Agregar logging extensivo para rastrear el flujo

**Código Implementado:**
```typescript
// backend/src/realtime/socket.ts
const handleConnection = (socket: Socket) => {
  // CRÍTICO: Re-autenticar SIEMPRE usando el token del handshake actual
  const user = authenticateSocket(socket);
  
  if (!user) {
    socket.disconnect(true);
    return;
  }
  
  (socket as Socket & { user: SocketUser }).user = user;
  
  socket.emit('connected', {
    socketId: socket.id,
    user: {
      id: user.id,
      username: user.username,
      roles: user.roles
    }
  });
};
```

**Errores Encontrados:**
1. ⚠️ Pendiente de prueba - Implementación reciente

**Solución Aplicada:**
- Re-autenticación forzada en cada conexión
- Logging detallado para debugging
- Detención del bucle infinito en el frontend después de 3 intentos

---

## 4. Errores Técnicos Detallados

### Error 1: Socket se Conecta con Usuario Incorrecto

**Síntoma:**
```
Frontend envía: Token userId: 3, role: cocinero
Backend responde: Usuario autenticado - ID: 2, Username: mesero, Roles: mesero
```

**Causa Técnica:**
- El middleware `io.use()` autentica y asigna `socket.user`
- `handleConnection` confiaba en `socket.user` del middleware
- El middleware podía estar usando un token en caché o el socket podía tener un usuario residual de una conexión anterior

**Solución:**
- Re-autenticar siempre en `handleConnection` usando `authenticateSocket(socket)`
- Leer el token directamente del `socket.handshake.auth.token` en cada conexión

---

### Error 2: Bucle Infinito de Reconexión

**Síntoma:**
```
⚠️ Socket.IO: Usuario/Rol no coincide (Socket: 2/mesero, Storage: 3/cocinero)
🔄 Desconectando y reconectando con token correcto... (Intento 1/3)
[Se repite infinitamente]
```

**Causa Técnica:**
- El frontend detectaba el desajuste y intentaba reconectar
- El backend seguía devolviendo el usuario incorrecto
- No había límite de intentos o el límite no funcionaba correctamente

**Solución:**
- Implementar contador de intentos con ventana de tiempo (30 segundos)
- Detener reconexión después de 3 intentos fallidos
- Aumentar delay entre reconexiones a 3 segundos
- Verificar token antes de reconectar

---

### Error 3: Token No Se Actualiza en Storage

**Síntoma:**
```
Login como cocinero → Token guardado correctamente
Socket conecta → Usa token del mesero anterior
```

**Causa Técnica:**
- `FlutterSecureStorage` en web puede tener delays en la escritura
- El socket se conectaba antes de que el token se guardara completamente
- No había verificación de que el token guardado coincidiera con el usuario actual

**Solución:**
- Agregar delays después de guardar tokens (500ms)
- Verificar que el token se guardó correctamente antes de conectar
- Decodificar el token y comparar con el userId esperado
- Releer el token del storage antes de conectar el socket

---

### Error 4: Alerta No Aparece en Interfaz del Cocinero

**Síntoma:**
```
Mesero envía alerta → Logs muestran "Alerta emitida"
Cocinero no recibe → Logs muestran "0 alertas recibidas"
```

**Causa Técnica:**
- El socket del cocinero no estaba conectado al room correcto (`role:cocinero`)
- El socket se conectaba con el rol incorrecto (mesero)
- Los listeners no se registraban correctamente

**Solución:**
- Asegurar que el socket se una al room `role:cocinero` después de la autenticación
- Verificar que los listeners se registren después de la conexión exitosa
- Agregar logging para rastrear cuando se reciben alertas

---

### Error 5: Duplicación de Inserción en Base de Datos

**Síntoma:**
```
Error 500: Internal Server Error al guardar alerta
Logs: "Duplicate entry for key 'PRIMARY'"
```

**Causa Técnica:**
- `crearAlerta` se llamaba dos veces:
  1. Dentro de `emitirAlerta`
  2. Directamente en `crearAlertaDesdeRequest`
- Esto causaba un intento de insertar la misma alerta dos veces

**Solución:**
- Modificar `emitirAlerta` para retornar el ID de la alerta creada
- Remover la llamada duplicada a `crearAlerta` en `crearAlertaDesdeRequest`
- Usar el ID retornado por `emitirAlerta`

---

### Error 6: URL Duplicada en API Call

**Síntoma:**
```
404 Not Found: http://localhost:3000/api/api/alertas
```

**Causa Técnica:**
- `ApiConfig.baseUrl` ya incluye `/api`
- El código hacía `_dio.post('/api/alertas')`
- Resultado: `/api` + `/api/alertas` = `/api/api/alertas`

**Solución:**
- Cambiar endpoint de `/api/alertas` a `/alertas`
- El `baseUrl` ya incluye el prefijo `/api`

---

## 5. Soluciones Técnicas Implementadas

### Solución 1: Re-autenticación Forzada en Backend

**Archivo:** `backend/src/realtime/socket.ts`

**Cambio:**
```typescript
// ANTES
const handleConnection = (socket: Socket) => {
  const socketUser = (socket as Socket & { user?: SocketUser }).user;
  const user = socketUser || authenticateSocket(socket);
  // ...
};

// DESPUÉS
const handleConnection = (socket: Socket) => {
  // CRÍTICO: Re-autenticar SIEMPRE usando el token del handshake actual
  const user = authenticateSocket(socket);
  
  if (!user) {
    socket.disconnect(true);
    return;
  }
  
  (socket as Socket & { user: SocketUser }).user = user;
  // ...
};
```

**Razón:**
- Asegura que cada conexión use el token más reciente del handshake
- Evita usar usuarios en caché del middleware
- Garantiza que el usuario autenticado sea el correcto

---

### Solución 2: Verificación de Token en Frontend

**Archivo:** `lib/services/socket_service.dart`

**Cambio:**
```dart
// Antes de conectar, verificar que el token sea del usuario correcto
final token = await _storage.read(key: 'accessToken');
final userId = await _storage.read(key: 'userId');

// Decodificar token
final parts = token.split('.');
final payload = parts[1];
final decoded = jsonDecode(base64Decode(paddedPayload));
final tokenUserId = decoded['sub']?.toString();

if (tokenUserId != userId) {
  // Token no coincide, no conectar
  return;
}
```

**Razón:**
- Previene conexiones con tokens incorrectos
- Detecta problemas de sincronización entre storage y token
- Evita bucles de reconexión innecesarios

---

### Solución 3: Límite de Intentos de Reconexión

**Archivo:** `lib/services/socket_service.dart`

**Cambio:**
```dart
// Contador de intentos con ventana de tiempo
int _reconnectionAttempts = 0;
static const int _maxReconnectionAttempts = 3;
DateTime? _lastReconnectionAttempt;
static const int _reconnectionTimeWindow = 30; // segundos

// En el handler de 'connected'
if (_reconnectionAttempts >= _maxReconnectionAttempts) {
  // Detener reconexión y mostrar error
  _updateState(SocketConnectionState.error);
  return;
}
```

**Razón:**
- Previene bucles infinitos de reconexión
- Limita intentos dentro de una ventana de tiempo
- Proporciona feedback claro al usuario sobre el error

---

### Solución 4: Mejora de Desconexión Completa

**Archivo:** `lib/services/socket_service.dart`

**Cambio:**
```dart
void disconnectCompletely() {
  // Limpiar socket actual
  if (_socket != null) {
    for (final eventName in _registeredEvents) {
      _socket!.off(eventName);
    }
    _socket!.clearListeners();
    _socket!.disconnect();
    _socket!.dispose();
    _socket = null;
  }
  
  // Limpiar listeners y contadores
  _pendingListeners.clear();
  _activeListeners.clear();
  _listenerCounts.clear();
  _reconnectionAttempts = 0;
  _lastReconnectionAttempt = null;
  _isReconnecting = false;
}
```

**Razón:**
- Asegura limpieza completa del socket anterior
- Previene listeners residuales
- Resetea todos los contadores y flags

---

### Solución 5: Logging Extensivo

**Archivos:** `backend/src/realtime/socket.ts`, `lib/services/socket_service.dart`

**Cambio:**
```typescript
// Backend
logger.info({ 
  socketId: socket.id,
  tokenDecodedPreview: {
    sub: tokenPreview.sub,
    username: tokenPreview.username,
    roles: tokenPreview.roles
  },
  authUserId,
  authRole
}, '🔍 Autenticando socket con token');
```

```dart
// Frontend
print('🔍 Socket: Verificando token - Token userId: $tokenUserId, Token roles: ${tokenRoles.join(", ")}, Storage userId: $userId, Storage role: $userRole');
```

**Razón:**
- Facilita debugging del flujo de autenticación
- Permite rastrear exactamente qué token se está usando
- Identifica desajustes entre frontend y backend

---

## 6. Estado Actual

### Problema Crítico Pendiente

**Descripción:**
El backend sigue autenticando sockets con el usuario incorrecto (mesero ID: 2) cuando el frontend envía el token del cocinero (ID: 3).

**Evidencia:**
```
Frontend logs:
  🔑 Token decodificado - UserId: 3, Username: cocinero, Roles: cocinero
  📤 Auth data que se enviará: {token: ..., userId: 3, role: cocinero}

Backend logs (esperado):
  ✅ Middleware: Socket autenticado correctamente - userId: 3, roles: cocinero

Backend logs (actual):
  👤 Socket.IO: Usuario autenticado - ID: 2, Username: mesero, Roles: mesero
```

**Última Solución Aplicada:**
- Re-autenticación forzada en `handleConnection`
- Logging extensivo en middleware y `handleConnection`
- Verificación de token en frontend antes de conectar

**Próximos Pasos:**
1. Verificar logs del backend para confirmar qué token está recibiendo
2. Verificar que `authenticateSocket` esté leyendo el token correcto del handshake
3. Verificar que `verifyAccessToken` esté decodificando el token correcto
4. Si el problema persiste, considerar limpiar cualquier caché de sockets en el servidor

---

## 7. Lecciones Aprendidas

### 1. No Confiar en Estado Caché en Socket.IO
- Siempre re-autenticar usando el token del handshake actual
- No asumir que `socket.user` del middleware es correcto

### 2. Verificar Token en Múltiples Puntos
- Frontend: Antes de conectar
- Backend Middleware: Al recibir conexión
- Backend handleConnection: Al procesar conexión

### 3. Implementar Límites de Reconexión
- Prevenir bucles infinitos
- Proporcionar feedback claro al usuario

### 4. Logging Extensivo es Crítico
- Facilita debugging de problemas complejos
- Permite rastrear el flujo completo de datos

### 5. FlutterSecureStorage en Web Tiene Delays
- Agregar delays después de escribir tokens
- Verificar que los tokens se guardaron correctamente

---

## 8. Referencias Técnicas

### Archivos Modificados

**Backend:**
- `backend/src/realtime/socket.ts` - Autenticación Socket.IO
- `backend/src/modules/alertas/alertas.service.ts` - Lógica de alertas
- `backend/src/utils/jwt.ts` - Verificación de tokens JWT

**Frontend:**
- `lib/services/socket_service.dart` - Servicio Socket.IO
- `lib/controllers/auth_controller.dart` - Controlador de autenticación
- `lib/controllers/cocinero_controller.dart` - Controlador del cocinero
- `lib/views/mesero/alert_to_kitchen_modal.dart` - UI de alertas
- `lib/services/alertas_service.dart` - Servicio de alertas

### Dependencias Clave

**Backend:**
- `socket.io` - Servidor Socket.IO
- `jsonwebtoken` - Verificación de tokens JWT

**Frontend:**
- `socket_io_client` - Cliente Socket.IO para Flutter
- `flutter_secure_storage` - Almacenamiento seguro de tokens

---

## 9. Conclusión

El problema principal es que el backend está autenticando sockets con el usuario incorrecto. A pesar de múltiples intentos de solución, el problema persiste. La última solución implementada (re-autenticación forzada en `handleConnection`) debería resolver el problema, pero requiere pruebas adicionales para confirmar.

**Recomendaciones:**
1. Verificar logs del backend en tiempo real durante el login del cocinero
2. Confirmar que el token recibido en el backend es el correcto
3. Si el problema persiste, considerar reiniciar el servidor backend completamente
4. Implementar un mecanismo de limpieza de sockets antiguos en el servidor

---

**Última Actualización:** 2025-12-08
**Estado:** En proceso de resolución
**Próxima Acción:** Verificar logs del backend y probar la última solución implementada

