# 🔧 Corrección de Autenticación de Socket.IO y Sistema de Alertas

## 📋 Resumen del Problema

Se identificaron y corrigieron problemas críticos en el sistema de autenticación de Socket.IO que causaban:

1. **Usuario incorrecto en socket**: El socket se quedaba autenticado con el usuario anterior (ej: mesero ID 2) después de cambiar a otro usuario (ej: cocinero ID 3)
2. **Bucle infinito de reconexiones**: El frontend detectaba un mismatch entre el usuario del socket y el storage, intentando reconectar indefinidamente
3. **Alertas no llegaban al cocinero**: Las alertas del mesero no se recibían correctamente debido a problemas de autenticación
4. **Errores de Flutter**: "Cannot send Null" en consola debido a print statements con valores null

## ✅ Soluciones Implementadas

### 1. Frontend - Socket Service (`lib/services/socket_service.dart`)

#### Cambios Principales:

- **Desconexión completa antes de conectar**: El método `connect()` ahora siempre desconecta cualquier socket anterior antes de crear uno nuevo, asegurando que no se reutilicen conexiones con tokens viejos.

- **Validación de token antes de conectar**: Se valida que el token del storage corresponda al usuario actual antes de crear la conexión, evitando usar tokens de usuarios anteriores.

- **Eliminación de bucle infinito**: Se removió la lógica de reconexión automática cuando hay un mismatch. Ahora, si el backend devuelve un usuario diferente al esperado, el socket se desconecta y se marca como error, requiriendo que el usuario haga logout/login.

- **Manejo seguro de null en prints**: Todos los print statements ahora validan que los valores no sean null antes de imprimirlos.

#### Flujo de Conexión:

```
1. Desconectar socket anterior (si existe)
2. Leer token del storage (sin caché)
3. Validar que el token corresponde al usuario actual
4. Crear nuevo socket con el token válido
5. En el evento 'connected', verificar que el usuario coincida
6. Si hay mismatch, desconectar y marcar error (NO reconectar automáticamente)
```

### 2. Frontend - Auth Controller (`lib/controllers/auth_controller.dart`)

#### Cambios en Login:

1. **Desconexión temprana**: Se desconecta el socket anterior ANTES de guardar cualquier dato nuevo en storage
2. **Validación de token**: Se verifica múltiples veces que el token guardado corresponde al usuario logueado
3. **Orden correcto de operaciones**:
   ```
   1. Desconectar socket anterior
   2. Verificar token en storage
   3. Guardar información del usuario
   4. Verificar consistencia
   5. Conectar nuevo socket
   ```

#### Cambios en Logout:

1. **Limpieza completa y ordenada**:
   ```
   1. Resetear estado en memoria
   2. Desconectar socket completamente
   3. Limpiar tokens del storage
   4. Limpiar datos de usuario
   5. Limpiar todo el storage
   6. Restaurar solo flags que deben persistir
   7. Verificar que todo se limpió correctamente
   ```

### 3. Backend - Socket Authentication (`backend/src/realtime/socket.ts`)

El backend ya estaba correctamente implementado:
- ✅ Lee el token SIEMPRE directamente del handshake (no usa caché)
- ✅ Valida el token con JWT en cada conexión
- ✅ Asigna el usuario correcto al socket
- ✅ Une el socket a los rooms correctos (`user:{id}`, `role:{role}`)
- ✅ Emite el evento `connected` con el usuario correcto

No se requirieron cambios en el backend.

### 4. Sistema de Alertas Mesero → Cocinero

El sistema de alertas ya estaba implementado correctamente:
- ✅ Endpoint `POST /alertas/cocina` en `alertas.routes.ts`
- ✅ Método `crearYEmitirAlertaCocina` en `alertas.service.ts`
- ✅ Emisión a `role:cocinero` vía Socket.IO
- ✅ Listener `cocina.alerta` en `cocinero_controller.dart`

Con las correcciones de autenticación, las alertas ahora funcionan correctamente porque:
- El socket del cocinero se autentica con el usuario correcto
- El socket se une correctamente al room `role:cocinero`
- El backend emite las alertas al room correcto
- El frontend recibe las alertas en tiempo real

## 🔍 Flujo Completo de Alertas

### Mesero envía alerta:

1. Mesero abre modal de alerta desde una orden
2. Selecciona tipo y razón
3. Frontend llama a `AlertasService().enviarAlertaACocina()`
4. Se hace POST a `/alertas/cocina` con JWT del mesero
5. Backend:
   - Valida JWT (usuario autenticado es mesero)
   - Inserta alerta en BD (una sola vez)
   - Emite evento `cocina.alerta` a room `role:cocinero`
6. Cocinero recibe evento en tiempo real
7. `CocineroController` actualiza la lista de alertas
8. UI se actualiza automáticamente

### Cocinero recibe alerta:

1. Socket del cocinero está autenticado como cocinero (ID 3, role: cocinero)
2. Socket está unido al room `role:cocinero`
3. Backend emite evento `cocina.alerta` al room
4. Listener `onCocinaAlerta` en `cocinero_controller.dart` recibe el evento
5. Se parsea la alerta y se agrega a la lista
6. `notifyListeners()` actualiza la UI

## 🛡️ Prevención de Problemas

### Para evitar que el problema vuelva a ocurrir:

1. **Siempre desconectar socket antes de logout/login**: El logout ahora lo hace automáticamente
2. **Validar token antes de conectar**: El `connect()` ahora valida el token
3. **NO reconectar automáticamente en caso de mismatch**: Se requiere logout/login manual
4. **Limpiar storage completamente en logout**: Se elimina todo y solo se restaura lo necesario

### Verificación:

Para verificar que todo funciona correctamente:

1. **Login como mesero (ID 2)**:
   - Verificar en logs del backend: `tokenDecodedPreview.sub = 2`
   - Verificar en frontend: Socket conectado con ID 2, role mesero

2. **Logout completo**:
   - Verificar que no queden tokens en storage
   - Verificar que el socket se desconectó

3. **Login como cocinero (ID 3)**:
   - Verificar en logs del backend: `tokenDecodedPreview.sub = 3`
   - Verificar en frontend: Socket conectado con ID 3, role cocinero
   - Verificar que NO hay bucles de reconexión

4. **Enviar alerta desde mesero**:
   - Crear orden como mesero
   - Enviar alerta desde modal
   - Verificar que el cocinero la recibe en tiempo real

## 📝 Archivos Modificados

### Frontend:
- `lib/services/socket_service.dart` - Correcciones en autenticación y conexión
- `lib/controllers/auth_controller.dart` - Mejoras en login/logout
- `lib/services/api_service.dart` - Corrección de prints con null

### Backend:
- Ningún cambio necesario (ya estaba correcto)

## 🎯 Criterios de Aceptación Cumplidos

✅ Cuando inicia sesión como cocinero:
- Storage: userId=3, role=cocinero, token con sub:3
- Backend muestra: tokenDecodedPreview.sub = 3
- Socket autenticado como: id=3, roles=["cocinero"]
- No hay bucles de desconexión/reconexión

✅ Cuando inicia sesión como mesero:
- Storage: userId=2, role=mesero
- Backend muestra: sub:2, roles=["mesero"]
- Socket se asigna correctamente a rooms user:2, role:mesero

✅ Alertas mesero → cocinero:
- Mesero crea alerta
- Backend inserta en BD una sola vez
- Backend emite a role:cocinero
- Cocinero recibe en tiempo real
- No hay errores de "Cannot send Null"

## 🔒 Restricciones Respetadas

- ✅ NO se modificó la lógica de otros roles (cajero, capitán, admin)
- ✅ NO se cambió la autenticación HTTP
- ✅ NO se cambiaron nombres de eventos ni rooms de otros módulos
- ✅ Solo se modificó lo estrictamente necesario para el flujo Mesero → Cocinero

