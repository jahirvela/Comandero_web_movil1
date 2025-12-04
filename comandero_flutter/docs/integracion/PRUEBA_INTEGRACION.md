# 🧪 Guía de Prueba de Integración

## ✅ Verificación Rápida

### Paso 1: Verificar Backend
```bash
cd backend
npm run dev
```

Debe mostrar:
```
Comandix API escuchando en http://0.0.0.0:3000
```

### Paso 2: Verificar Frontend
```bash
cd comandero_flutter
flutter pub get  # Si no lo has hecho
flutter run -d chrome
```

### Paso 3: Probar Login

1. Abre la app en el navegador
2. Ingresa:
   - Usuario: `admin`
   - Contraseña: `Demo1234`
3. Debe hacer login exitosamente y redirigirte al dashboard

### Paso 4: Verificar en Consola

En la consola del navegador (F12) deberías ver:
- `Socket.IO conectado exitosamente` (después del login)
- `Socket.IO: Confirmación de conexión recibida`

## 🔍 Verificación de Endpoints

### Desde Flutter (en el código)

Puedes probar los servicios directamente:

```dart
// Ejemplo: Obtener mesas
final mesasService = MesasService();
final mesas = await mesasService.getMesas();
print('Mesas: $mesas');

// Ejemplo: Obtener productos
final productosService = ProductosService();
final productos = await productosService.getProductos();
print('Productos: $productos');
```

### Desde Swagger

1. Ve a `http://localhost:3000/docs`
2. Haz login con `admin` / `Demo1234`
3. Autoriza con el token
4. Prueba cualquier endpoint

## 🐛 Solución de Problemas

### Error: "Connection refused"
**Causa**: Backend no está corriendo
**Solución**: Ejecuta `npm run dev` en la carpeta `backend`

### Error: "CORS policy"
**Causa**: CORS no está configurado para Flutter web
**Solución**: Agrega `http://localhost:8080` al `CORS_ORIGIN` en `.env` del backend

### Error: "401 Unauthorized"
**Causa**: Token expirado o inválido
**Solución**: 
- Haz logout y login de nuevo
- Verifica que el token se esté guardando correctamente

### Socket.IO no conecta
**Causa**: Token no válido o backend no acepta la conexión
**Solución**:
- Verifica que el login haya sido exitoso
- Revisa los logs del backend para ver errores de autenticación

## ✅ Checklist de Funcionalidad

- [ ] Login funciona con credenciales correctas
- [ ] Login falla con credenciales incorrectas
- [ ] Token se guarda después del login
- [ ] Socket.IO se conecta después del login
- [ ] Logout limpia tokens y desconecta Socket.IO
- [ ] Los servicios pueden hacer peticiones GET
- [ ] Los servicios pueden hacer peticiones POST
- [ ] Los tokens se renuevan automáticamente cuando expiran

## 📝 Notas

- Todos los servicios están listos para usar
- El manejo de errores está implementado
- Los tokens duran 30 minutos
- Socket.IO se conecta automáticamente después del login

