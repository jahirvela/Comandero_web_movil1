# 🔗 Integración Frontend-Backend

## ✅ Estado de la Integración

El frontend Flutter ahora está completamente integrado con el backend Node.js/Express.

## 📦 Dependencias Agregadas

- `http: ^1.2.2` - Cliente HTTP básico
- `dio: ^5.4.3+1` - Cliente HTTP avanzado con interceptores
- `socket_io_client: ^2.0.3+1` - Cliente Socket.IO para tiempo real

## 🚀 Instalación

1. **Instalar dependencias de Flutter:**
```bash
cd comandero_flutter
flutter pub get
```

2. **Asegúrate de que el backend esté corriendo:**
```bash
cd backend
npm run dev
```

## ⚙️ Configuración

### URL del Backend

La configuración está en `lib/config/api_config.dart`:

- **Web (Chrome)**: `http://localhost:3000/api`
- **Android Emulator**: `http://10.0.2.2:3000/api`
- **iOS Simulator**: `http://localhost:3000/api`
- **Dispositivo Físico**: Cambia `10.0.2.2` por la IP de tu máquina (ej: `192.168.1.100`)

### Para Dispositivos Físicos

Si vas a probar en un dispositivo físico (celular/tablet real):

1. Encuentra la IP de tu computadora:
   - Windows: `ipconfig` en PowerShell
   - Mac/Linux: `ifconfig` o `ip addr`

2. Actualiza `lib/config/api_config.dart`:
```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000/api';
  } else {
    // Cambia esta IP por la de tu computadora
    return 'http://192.168.1.XXX:3000/api';
  }
}
```

3. Asegúrate de que el backend acepte conexiones desde tu red local (verifica CORS en `backend/src/config/cors.ts`)

## 🔐 Autenticación

El sistema de autenticación está completamente integrado:

- **Login**: Se conecta al endpoint `/api/auth/login`
- **Tokens**: Se guardan automáticamente en `FlutterSecureStorage`
- **Refresh**: Los tokens se renuevan automáticamente cuando expiran
- **Logout**: Limpia todos los tokens almacenados

### Credenciales de Prueba

- Usuario: `admin`
- Contraseña: `Demo1234`

Otros usuarios disponibles:
- `cajero1` / `Demo1234`
- `capitan1` / `Demo1234`
- `mesero1` / `Demo1234`
- `cocinero1` / `Demo1234`

## 📡 Servicios Disponibles

### AuthService
- `login(username, password)` - Iniciar sesión
- `getProfile()` - Obtener perfil del usuario
- `refreshToken(token)` - Renovar token
- `logout()` - Cerrar sesión

### MesasService
- `getMesas()` - Listar todas las mesas
- `getMesa(id)` - Obtener una mesa
- `createMesa(data)` - Crear mesa
- `updateMesa(id, data)` - Actualizar mesa
- `cambiarEstadoMesa(id, estadoId, nota?)` - Cambiar estado
- `getEstadosMesa()` - Obtener estados disponibles

### ProductosService
- `getProductos()` - Listar productos
- `getProducto(id)` - Obtener producto
- `createProducto(data)` - Crear producto
- `updateProducto(id, data)` - Actualizar producto

### OrdenesService
- `getOrdenes()` - Listar órdenes
- `getOrden(id)` - Obtener orden
- `createOrden(data)` - Crear orden
- `updateOrden(id, data)` - Actualizar orden
- `agregarItems(id, items)` - Agregar items a orden
- `cambiarEstado(id, estadoId)` - Cambiar estado
- `getEstadosOrden()` - Obtener estados disponibles

### PagosService
- `getPagos()` - Listar pagos
- `getPago(id)` - Obtener pago
- `registrarPago(data)` - Registrar pago
- `registrarPropina(ordenId, monto)` - Registrar propina
- `getFormasPago()` - Obtener formas de pago
- `getPropinas()` - Obtener propinas

### SocketService
- `connect()` - Conectar a Socket.IO
- `disconnect()` - Desconectar
- `onOrderCreated(callback)` - Escuchar órdenes creadas
- `onOrderUpdated(callback)` - Escuchar órdenes actualizadas
- `onOrderCancelled(callback)` - Escuchar órdenes canceladas
- `emitKitchenAlert(payload)` - Enviar alerta de cocina

## 🧪 Pruebas

### 1. Probar en Web (Chrome)
```bash
flutter run -d chrome --web-port=8080
```

### 2. Probar en Android Emulator
```bash
flutter run -d Pixel_5_API_33
```

### 3. Probar en iOS Simulator
```bash
flutter run -d iPhone
```

### 4. Probar en Dispositivo Físico
1. Conecta tu dispositivo por USB
2. Habilita depuración USB
3. Ejecuta: `flutter run`

## 🔧 Solución de Problemas

### Error: "Connection refused"
- Verifica que el backend esté corriendo (`npm run dev` en la carpeta `backend`)
- Verifica la URL en `api_config.dart`
- Para dispositivos físicos, usa la IP de tu computadora, no `localhost`

### Error: "CORS policy"
- Verifica que `CORS_ORIGIN` en `.env` del backend incluya tu origen
- Para desarrollo local, puedes usar: `CORS_ORIGIN=http://localhost:8080,http://localhost:3000`

### Error: "401 Unauthorized"
- Verifica que las credenciales sean correctas
- Verifica que el token no haya expirado (30 minutos)
- Haz logout y login de nuevo

### Error: "Socket.IO connection failed"
- Verifica que el backend esté corriendo
- Verifica la URL de Socket.IO en `api_config.dart`
- Asegúrate de tener un token válido antes de conectar

## 📝 Notas Importantes

1. **Tokens**: Los tokens duran 30 minutos. Si expiran, se renuevan automáticamente si hay un refresh token válido.

2. **Almacenamiento**: Los tokens se guardan en `FlutterSecureStorage`, que es seguro tanto en web como en móvil.

3. **Tiempo Real**: Socket.IO se conecta automáticamente después del login. Los eventos se emiten desde el backend cuando se crean/actualizan órdenes.

4. **Roles**: Los roles del backend se mapean automáticamente:
   - `administrador` → `admin`
   - Otros roles se mantienen igual

## 🎯 Próximos Pasos

1. Actualizar los controladores (MeseroController, CocineroController, etc.) para usar los servicios reales
2. Integrar Socket.IO en las vistas que necesiten tiempo real
3. Agregar manejo de errores más robusto
4. Agregar indicadores de carga

