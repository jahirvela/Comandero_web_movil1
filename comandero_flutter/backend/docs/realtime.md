# Realtime Comandix (Socket.IO)

## Configuración del backend

- Servidor Socket.IO montado sobre el mismo `httpServer` de Express.
- Autenticación en `connection` usando token JWT (mismo que API REST).
- Espacios/salas:
  - Por rol: `role:administrador`, `role:capitan`, `role:mesero`, `role:cocinero`, `role:cajero`.
  - Por estación: `station:tacos`, `station:consomes`, `station:bebidas` (cliente la envía en `auth.station`).
  - Por orden: `orden:{id}` (para listeners específicos).
- Eventos broadcast disponibles:
  - `pedido.creado` → payload `OrdenDetalle`.
  - `pedido.actualizado` → payload `OrdenDetalle`.
  - `pedido.cancelado` → payload `OrdenDetalle`.
  - `cocina.alerta` → payload `{ mensaje: string; estacion?: string }` (dirigido a `station:*` o `role:cocinero`).
  - `connected` → respuesta inicial al cliente con `socketId` y datos del usuario.

## Conexión desde Flutter

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

final socket = IO.io(
  'http://localhost:3000', // cambiar por host en producción
  IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setAuth({
        'token': accessToken, // JWT obtenido en /auth/login
        'station': 'tacos',   // opcional, para unirse a estación
      })
      .build(),
);

socket.onConnect((_) {
  print('Conectado: ${socket.id}');
});

socket.on('pedido.creado', (data) {
  // Parsear OrdenDetalle
});

socket.on('pedido.actualizado', (data) {
  // Actualizar UI o estados
});

socket.on('pedido.cancelado', (data) {
  // Notificar cancelación
});

socket.on('cocina.alerta', (data) {
  // Mostrar alerta a la cocina
});

socket.connect();
```

## Envío de eventos desde Flutter

```dart
socket.emit('cocina.alerta', {
  'mensaje': 'Orden 123 con retraso',
  'estacion': 'tacos', // opcional
});
```

## Buenas prácticas

- Renovar el token JWT cuando expire y reconectar.
- Manejar `socket.onDisconnect` para reconexión automática.
- Usar `socket.io` namespaces si se requiere separación por módulo en el futuro.
- Validar permisos en el backend antes de emitir eventos sensibles.

