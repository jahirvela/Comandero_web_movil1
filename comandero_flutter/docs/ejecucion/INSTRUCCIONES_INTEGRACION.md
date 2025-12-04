# 🚀 Instrucciones de Integración Frontend-Backend

## ✅ Lo que se ha completado

1. ✅ **Dependencias agregadas**: `http`, `dio`, `socket_io_client`
2. ✅ **Servicio de API base** (`ApiService`) con manejo automático de tokens
3. ✅ **Servicio de autenticación** (`AuthService`) conectado al backend
4. ✅ **AuthController actualizado** para usar el backend real
5. ✅ **Servicios creados** para todos los módulos:
   - MesasService
   - ProductosService
   - OrdenesService
   - PagosService
   - SocketService (tiempo real)
6. ✅ **Configuración de URLs** para web, Android, iOS y dispositivos físicos

## 🔧 Configuración Inicial

### 1. Verificar que el backend esté corriendo

```bash
cd backend
npm run dev
```

El backend debe estar en `http://localhost:3000`

### 2. Configurar CORS (si es necesario)

Si vas a probar en Flutter Web, asegúrate de que el `.env` del backend tenga:

```env
CORS_ORIGIN=http://localhost:8080,http://localhost:3000
```

### 3. Para dispositivos físicos

Si vas a probar en un celular/tablet real:

1. Encuentra la IP de tu computadora:
   ```bash
   # Windows
   ipconfig
   
   # Mac/Linux
   ifconfig
   ```

2. Edita `lib/config/api_config.dart` y cambia:
   ```dart
   return 'http://TU_IP_AQUI:3000/api';
   ```

## 🧪 Cómo Probar

### Opción 1: Web (Chrome)
```bash
cd comandero_flutter
flutter run -d chrome --web-port=8080
```

### Opción 2: Android Emulator
```bash
flutter run -d Pixel_5_API_33
```

### Opción 3: iOS Simulator
```bash
flutter run -d iPhone
```

### Opción 4: Dispositivo Físico
```bash
# Conecta tu dispositivo por USB
flutter devices  # Ver dispositivos disponibles
flutter run -d <device_id>
```

## 🔐 Login

Usa estas credenciales para probar:

- **Usuario**: `admin`
- **Contraseña**: `Demo1234`

O cualquier otro usuario creado en el backend con contraseña `Demo1234`.

## 📱 Funcionalidades Integradas

### ✅ Autenticación
- Login con backend real
- Tokens JWT almacenados de forma segura
- Refresh automático de tokens
- Logout

### ✅ Servicios Listos
- MesasService - Gestión de mesas
- ProductosService - Catálogo de productos
- OrdenesService - Gestión de órdenes
- PagosService - Procesamiento de pagos
- SocketService - Comunicación en tiempo real

## 🔄 Próximos Pasos (Opcional)

Los servicios están listos, pero los controladores (MeseroController, CocineroController, etc.) aún usan datos mock. Para completar la integración:

1. Actualizar `MeseroController` para usar `MesasService` y `OrdenesService`
2. Actualizar `CocineroController` para usar `OrdenesService` y `SocketService`
3. Actualizar `CajeroController` para usar `PagosService`
4. Actualizar otros controladores según corresponda

## ⚠️ Notas Importantes

1. **URLs**: La configuración en `api_config.dart` usa:
   - Web: `localhost:3000`
   - Android Emulator: `10.0.2.2:3000`
   - iOS Simulator: `localhost:3000`
   - Dispositivo físico: Necesitas cambiar a la IP de tu máquina

2. **Tokens**: Los tokens duran 30 minutos y se renuevan automáticamente

3. **Socket.IO**: Se conecta automáticamente después del login. Los eventos se emiten desde el backend cuando hay cambios en órdenes.

4. **Errores**: Si ves errores de conexión:
   - Verifica que el backend esté corriendo
   - Verifica la URL en `api_config.dart`
   - Para dispositivos físicos, usa la IP de tu computadora

## 🎯 Estado Actual

- ✅ Backend funcionando
- ✅ Frontend con servicios integrados
- ✅ Autenticación funcionando
- ⏳ Controladores aún usan datos mock (se pueden actualizar gradualmente)

¡Todo está listo para probar! 🚀

