# ✅ Solución: Problemas de Login

## 🔧 Problema Resuelto

Se corrigieron los problemas de login que impedían iniciar sesión con el usuario `admin` y contraseña `Demo1234`.

---

## 🎯 Cambios Realizados

### 1. Script para Crear/Actualizar Usuario Admin

**Archivo:** `comandero_flutter/backend/scripts/crear-usuario-admin.cjs`

**Qué hace:**
- ✅ Genera el hash correcto de la contraseña "Demo1234" usando bcrypt
- ✅ Crea el usuario admin si no existe
- ✅ Actualiza la contraseña del usuario admin si ya existe
- ✅ Asigna el rol de Administrador al usuario
- ✅ Crea el rol Administrador si no existe

**Cómo usarlo:**
```powershell
cd comandero_flutter\backend
node scripts/crear-usuario-admin.cjs
```

---

### 2. Mejoras en el Manejo de Errores

**Archivo:** `comandero_flutter/lib/services/auth_service.dart`

**Mejoras:**
- ✅ Logs más detallados para debugging
- ✅ Mensajes de error más claros
- ✅ Información sobre la URL intentada
- ✅ Detección de problemas de conexión

**Ahora verás en la consola:**
- ✅ Tipo de error
- ✅ Status code
- ✅ Response data
- ✅ URL intentada
- ✅ Mensaje de error específico

---

## 📋 Pasos para Solucionar Problemas de Login

### Paso 1: Crear/Actualizar Usuario Admin

Si el login no funciona, primero asegúrate de que el usuario admin exista con la contraseña correcta:

```powershell
cd comandero_flutter\backend
node scripts/crear-usuario-admin.cjs
```

**Deberías ver:**
```
✅ Conectado a la base de datos
✅ Hash generado para contraseña: Demo1234
✅ Usuario admin actualizado/creado
✅ Rol Administrador asignado
✅ Proceso completado exitosamente
📝 Credenciales:
   Usuario: admin
   Contraseña: Demo1234
```

---

### Paso 2: Verificar que el Backend Esté Corriendo

Asegúrate de que el backend esté corriendo:

```powershell
cd comandero_flutter\backend
npm run dev
```

**Deberías ver:**
```
🚀 Servidor iniciado en http://localhost:3000
```

---

### Paso 3: Verificar la Configuración de la API

Abre `comandero_flutter/lib/config/api_config.dart` y verifica que:

```dart
static String get _developmentApiUrl {
  if (kIsWeb) {
    return 'http://localhost:3000/api';  // ✅ Correcto para Chrome
  } else {
    return 'http://10.0.2.2:3000/api';    // ✅ Correcto para emuladores
  }
}
```

---

### Paso 4: Probar el Login

1. Abre la app en Chrome
2. Intenta iniciar sesión con:
   - **Usuario:** `admin`
   - **Contraseña:** `Demo1234`

---

### Paso 5: Revisar Errores

Si el login sigue fallando:

**En la consola del navegador (F12 → Console):**
- Busca mensajes que empiecen con `❌ Error en login`
- Verifica el tipo de error
- Verifica la URL intentada

**En la terminal del backend:**
- Busca errores relacionados con autenticación
- Verifica que MySQL esté conectado
- Verifica que las tablas existan

---

## 🐛 Errores Comunes y Soluciones

### Error: "Credenciales incorrectas"

**Causa:** El usuario no existe o la contraseña es incorrecta.

**Solución:**
```powershell
cd comandero_flutter\backend
node scripts/crear-usuario-admin.cjs
```

---

### Error: "No se pudo conectar al servidor"

**Causa:** El backend no está corriendo o la URL es incorrecta.

**Solución:**
1. Verifica que el backend esté corriendo:
   ```powershell
   cd comandero_flutter\backend
   npm run dev
   ```

2. Verifica la URL en `api_config.dart`:
   ```dart
   return 'http://localhost:3000/api';  // Para Chrome
   ```

3. Prueba acceder directamente en el navegador:
   ```
   http://localhost:3000/api/health
   ```

---

### Error: "Tiempo de espera agotado"

**Causa:** El backend está tardando mucho en responder.

**Solución:**
1. Verifica que MySQL esté corriendo
2. Verifica que no haya errores en la terminal del backend
3. Aumenta el timeout en `api_config.dart` si es necesario

---

### Error: "Respuesta del servidor no tiene la estructura esperada"

**Causa:** El backend está devolviendo una respuesta en formato diferente.

**Solución:**
1. Verifica que el backend esté actualizado
2. Revisa la respuesta en la consola del navegador
3. Verifica que el endpoint `/api/auth/login` devuelva:
   ```json
   {
     "user": { ... },
     "tokens": {
       "accessToken": "...",
       "refreshToken": "..."
     }
   }
   ```

---

## ✅ Verificación Final

Después de seguir estos pasos, deberías poder:

1. ✅ Iniciar sesión con `admin` / `Demo1234`
2. ✅ Ver la pantalla principal según tu rol
3. ✅ Ver mensajes de éxito en la consola

---

## 📝 Credenciales por Defecto

Después de ejecutar el script:

- **Usuario:** `admin`
- **Contraseña:** `Demo1234`
- **Rol:** Administrador

---

**Última actualización:** 2024-01-15

