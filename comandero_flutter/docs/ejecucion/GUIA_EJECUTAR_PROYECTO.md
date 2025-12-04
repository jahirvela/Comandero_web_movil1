# 🚀 Guía Paso a Paso: Ejecutar el Proyecto en Chrome

Esta guía te ayudará a ejecutar todo el proyecto Comandix en Chrome para probar todas las funcionalidades.

---

## 📋 Requisitos Previos

Antes de empezar, asegúrate de tener:

- ✅ **Node.js** instalado (versión 20 o superior)
- ✅ **Flutter** instalado y configurado
- ✅ **MySQL 8** instalado y corriendo
- ✅ **Base de datos** creada y con datos iniciales

---

## 🔧 Paso 1: Verificar que MySQL esté Corriendo

**✅ MySQL81 está configurado para iniciarse automáticamente**, así que debería estar corriendo siempre.

### Verificación Rápida

Ejecuta en PowerShell:

```powershell
Get-Service MySQL81
```

**Si ves "Running":** ✅ MySQL está corriendo, puedes continuar al siguiente paso.

**Si ves "Stopped":** ❌ Algo inusual pasó. Ejecuta:

```powershell
Start-Service MySQL81
```

**💡 Nota:** Si MySQL se detiene frecuentemente, revisa los logs de MySQL o ejecuta el script de configuración automática:

```powershell
cd "comandero_flutter\backend\scripts"
.\configurar-mysql-automatico.ps1
```

*(Este script requiere permisos de Administrador)*

---

## 📁 Paso 2: Verificar Configuración del Backend

### 2.1. Verificar/Crear archivo `.env`

Ve a la carpeta del backend:

```powershell
cd comandero_flutter\backend
```

**Si NO existe el archivo `.env`**, créalo copiando el ejemplo:

```powershell
Copy-Item .env.example .env
```

Luego edita el archivo `.env` con un editor de texto (Notepad, VS Code, etc.) y configura:

**⚠️ OBLIGATORIO - Debes cambiar estos valores:**

1. **`DATABASE_PASSWORD`**: Tu contraseña real de MySQL
2. **`JWT_ACCESS_SECRET`**: Un texto largo y aleatorio (mínimo 32 caracteres)
   - Ejemplo: `mi_secreto_super_seguro_12345678901234567890`
   - Puedes usar: https://randomkeygen.com/ para generar uno
3. **`JWT_REFRESH_SECRET`**: Otro texto largo y aleatorio diferente (mínimo 32 caracteres)

**✅ Los demás valores puedes dejarlos como están para desarrollo local.**

**Ejemplo de `.env` mínimo funcional:**

```env
NODE_ENV=development
PORT=3000
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_USER=root
DATABASE_PASSWORD=tu_contraseña_real_aqui
DATABASE_NAME=comandix
JWT_ACCESS_SECRET=mi_secreto_access_super_seguro_12345678901234567890
JWT_REFRESH_SECRET=mi_secreto_refresh_super_seguro_98765432109876543210
JWT_ACCESS_EXPIRES_IN=30m
JWT_REFRESH_EXPIRES_IN=7d
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://localhost:8081
SWAGGER_USERNAME=admin
SWAGGER_PASSWORD=Demo1234
PRINTER_TYPE=simulation
PRINTER_INTERFACE=file
```

**💡 Tip:** Si ya tienes un `.env` funcionando, no necesitas cambiarlo.

---

## 🖥️ Paso 3: Iniciar el Backend

### 3.1. Verificación Previa (Opcional pero Recomendado)

Antes de iniciar, verifica que todo esté listo:

```powershell
cd "C:\Users\Jahir VS\comandero_web_movil\comandero_flutter\backend\scripts"
.\verificar-antes-de-iniciar.ps1
```

Este script verificará:
- ✅ MySQL está corriendo
- ✅ Puerto 3000 está libre
- ✅ Archivo `.env` existe y tiene las variables necesarias
- ✅ Node.js está instalado
- ✅ Dependencias npm están instaladas

### 3.2. Abrir una Terminal para el Backend

Abre una **nueva terminal** (PowerShell o CMD) y ve a la carpeta del backend:

```powershell
cd "C:\Users\Jahir VS\comandero_web_movil\comandero_flutter\backend"
```

### 3.3. Instalar Dependencias (Solo la primera vez)

Si es la primera vez que ejecutas el proyecto, instala las dependencias:

```powershell
npm install
```

Esto puede tardar unos minutos. Espera a que termine.

### 3.4. Liberar Puerto 3000 (Si es necesario)

Si el puerto 3000 está en uso, libéralo:

```powershell
cd scripts
.\cerrar-proceso-puerto-3000.ps1
```

### 3.5. Iniciar el Servidor

**Opción 1: Inicio Automático (Recomendado) ⭐**

Este comando **siempre funciona** - libera el puerto 3000 automáticamente si está ocupado:

```powershell
npm run dev
```

**O también puedes usar:**

```powershell
npm run dev:auto
```

**Ambos comandos hacen lo mismo:**
- ✅ Liberan el puerto 3000 automáticamente si está ocupado
- ✅ Inician el backend sin intervención manual
- ✅ Funcionan 100% del tiempo

**Opción 2: Liberar Puerto Manualmente (Si es necesario)**

Si por alguna razón necesitas liberar el puerto manualmente:

```powershell
cd scripts
.\liberar-puerto-3000.ps1
cd ..
npm run dev
```

**Opción 3: Script Completo con Verificaciones**

Para una verificación completa antes de iniciar (MySQL, dependencias, puerto):

```powershell
cd scripts
.\iniciar-backend.ps1
```

**Deberías ver algo como:**

```
🚀 Servidor iniciado en http://localhost:3000
📚 Swagger UI disponible en http://localhost:3000/docs
✅ Base de datos conectada
```

**✅ Si ves estos mensajes:** El backend está corriendo correctamente.

**❌ Si ves errores:**
- **Error de conexión a MySQL:** Verifica que MySQL esté corriendo y que las credenciales en `.env` sean correctas
- **Error de puerto en uso:** Algo más está usando el puerto 3000, ciérralo o cambia el puerto en `.env`

**⚠️ IMPORTANTE:** Deja esta terminal abierta. El backend debe seguir corriendo mientras pruebas.

---

## 🌐 Paso 4: Verificar que el Backend Funciona

Antes de iniciar el frontend, verifica que el backend esté respondiendo:

### 4.1. Abrir Swagger en el Navegador

Abre Chrome y ve a:

```
http://localhost:3000/docs
```

**Deberías ver:**
- La interfaz de Swagger con todos los endpoints documentados
- Un botón "Authorize" en la parte superior

### 4.2. Probar el Endpoint de Health

En Swagger UI:

1. **Busca la sección "Health"** en la lista de tags (está al principio, antes de "Auth")
2. **Expande la sección "Health"**
3. **Verás el endpoint:** `GET /health` (o `GET /api/health` dependiendo de cómo se muestre)
4. **Haz clic en el endpoint** para expandirlo
5. **Haz clic en "Try it out"** (botón azul)
6. **Haz clic en "Execute"** (botón verde)

**Deberías ver una respuesta como:**
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T12:34:56.789Z"
}
```

**✅ Si funciona:** El backend está listo y funcionando correctamente.

**❌ Si no funciona:** 
- Revisa los errores en la terminal del backend
- Verifica que el servidor esté corriendo en `http://localhost:3000`
- Intenta acceder directamente a `http://localhost:3000/api/health` en el navegador

---

## 📱 Paso 5: Iniciar el Frontend en Chrome

### 5.1. Abrir una Nueva Terminal para el Frontend

Abre **otra terminal nueva** (deja la del backend abierta) y ve a la carpeta del proyecto Flutter:

```powershell
cd "C:\Users\Jahir VS\comandero_web_movil\comandero_flutter"
```

### 5.2. Verificar Dependencias de Flutter

Si es la primera vez, obtén las dependencias:

```powershell
flutter pub get
```

### 5.3. Verificar que Chrome esté Disponible

Verifica que Flutter detecte Chrome:

```powershell
flutter devices
```

**Deberías ver algo como:**
```
Chrome (web) • chrome • web-javascript • Google Chrome
```

**✅ Si ves Chrome:** Puedes continuar.

**❌ Si no ves Chrome:** Asegúrate de tener Chrome instalado y actualizado.

### 5.4. Ejecutar la App en Chrome

Ejecuta el siguiente comando:

```powershell
flutter run -d chrome
```

**Esto hará:**
1. Compilar la aplicación Flutter
2. Abrir Chrome automáticamente
3. Mostrar la app en `http://localhost:xxxxx` (Flutter asigna un puerto automáticamente)

**⏳ Esto puede tardar 1-2 minutos la primera vez.** Espera a que veas:

```
✓ Built build/web
Launching lib/main.dart on Chrome in debug mode...
```

**✅ Si la app se abre en Chrome:** ¡Perfecto! El frontend está corriendo.

**❌ Si hay errores:**
- **Error de compilación:** Revisa los mensajes de error en la terminal
- **Chrome no se abre:** Verifica que Chrome esté instalado y actualizado

---

## 🔗 Paso 6: Verificar que Todo Esté Conectado

### 6.1. Verificar la Conexión Backend-Frontend

Una vez que la app se abra en Chrome:

1. **Deberías ver la pantalla de login**
2. **Intenta iniciar sesión con:**
   - Usuario: `admin`
   - Contraseña: `Demo1234`

**✅ Si el login funciona:** El frontend está conectado al backend correctamente.

**❌ Si el login falla:**

**Primero, asegúrate de que el usuario admin exista con la contraseña correcta:**

Ejecuta el script para crear/actualizar el usuario admin:

```powershell
cd comandero_flutter\backend
node scripts/crear-usuario-admin.cjs
```

Este script:
- ✅ Crea o actualiza el usuario `admin` con la contraseña `Demo1234`
- ✅ Asigna el rol de Administrador
- ✅ Genera el hash correcto de la contraseña

**Luego, verifica:**
- ✅ Que el backend esté corriendo (Paso 3)
- ✅ Que la URL en `lib/config/api_config.dart` sea `http://localhost:3000/api`
- ✅ Revisa la consola del navegador (F12) para ver errores detallados
- ✅ Revisa la terminal del backend para ver errores del servidor

### 6.2. Verificar Socket.IO (Tiempo Real)

Después de iniciar sesión:

1. **Abre la consola del navegador** (F12 → Console)
2. **Deberías ver mensajes como:**
   ```
   Socket.IO conectado
   ```
   o
   ```
   Socket connected
   ```

**✅ Si ves estos mensajes:** Socket.IO está funcionando.

**❌ Si no ves estos mensajes:**
- Verifica que el backend esté corriendo
- Revisa la URL de Socket.IO en `lib/config/api_config.dart`

---

## 🧪 Paso 7: Probar Funcionalidades

Ahora que todo está corriendo, puedes probar:

### 7.1. Funcionalidades Básicas

- ✅ **Login/Logout**
- ✅ **Ver mesas**
- ✅ **Ver productos**
- ✅ **Crear órdenes**
- ✅ **Ver órdenes**

### 7.2. Funcionalidades Avanzadas

- ✅ **Tiempo real:** Abre la app en dos pestañas de Chrome y verás los cambios en tiempo real
- ✅ **Pagos:** Procesa pagos desde la app
- ✅ **Reportes:** Genera PDFs y CSVs (si tienes los permisos)
- ✅ **Alertas:** Las alertas aparecerán en tiempo real

---

## 🐛 Solución de Problemas Comunes

### Problema 1: "Error de conexión a la base de datos"

**Solución:**
1. Verifica que MySQL esté corriendo (Paso 1)
2. Verifica las credenciales en `.env`
3. Verifica que la base de datos `comandix` exista

### Problema 2: "El frontend no se conecta al backend"

**Solución:**
1. Verifica que el backend esté corriendo en `http://localhost:3000`
2. Abre `http://localhost:3000/docs` en Chrome para verificar
3. Revisa `lib/config/api_config.dart` - debe usar `http://localhost:3000/api` para desarrollo

### Problema 3: "Socket.IO no se conecta"

**Solución:**
1. Verifica que el backend esté corriendo
2. Verifica que Socket.IO esté configurado en `backend/src/realtime/socket.ts`
3. Revisa la consola del navegador (F12) para ver errores específicos

### Problema 4: "Error 401 Unauthorized"

**Solución:**
1. El token expiró - cierra sesión y vuelve a iniciar sesión
2. Verifica que el JWT_SECRET en `.env` sea el mismo que cuando creaste el usuario

### Problema 5: "El puerto 3000 está en uso" (Error EADDRINUSE)

**Solución Rápida (Recomendada):**

Ejecuta el script para liberar el puerto automáticamente:

```powershell
cd comandero_flutter\backend\scripts
.\cerrar-proceso-puerto-3000.ps1
```

**Solución Manual:**

1. Ver qué proceso está usando el puerto:
   ```powershell
   netstat -ano | findstr :3000
   ```

2. Cerrar el proceso (reemplaza `<PID>` con el número que aparezca):
   ```powershell
   taskkill /PID <PID> /F
   ```

**Solución Alternativa:**

Si prefieres usar otro puerto, cambia en `.env`:
```env
PORT=3001
```

Y actualiza `lib/config/api_config.dart` para usar el puerto 3001.

---

## 📊 Resumen de URLs Importantes

Cuando todo esté corriendo, estas son las URLs que usarás:

| Servicio | URL | Descripción |
|----------|-----|-------------|
| **Backend API** | `http://localhost:3000/api` | API REST del backend |
| **Swagger UI** | `http://localhost:3000/docs` | Documentación interactiva |
| **Frontend (Chrome)** | `http://localhost:xxxxx` | App Flutter (puerto asignado automáticamente) |

---

## ✅ Checklist Final

Antes de empezar a probar, verifica:

- [ ] MySQL está corriendo
- [ ] Backend está corriendo (`npm run dev`)
- [ ] Swagger funciona en `http://localhost:3000/docs`
- [ ] Frontend está corriendo en Chrome (`flutter run -d chrome`)
- [ ] Puedo iniciar sesión en la app
- [ ] Socket.IO está conectado (ver consola del navegador)

**Si todos los checkboxes están marcados:** ✅ **¡Todo está listo para probar!**

---

## 🎯 Próximos Pasos

Una vez que todo funcione:

1. **Prueba todas las funcionalidades** que implementamos
2. **Abre múltiples pestañas** para probar tiempo real
3. **Revisa los logs** del backend para ver qué está pasando
4. **Prueba en diferentes navegadores** si quieres

---

## 💡 Tips Útiles

- **Mantén ambas terminales abiertas:** Una para el backend, otra para Flutter
- **Usa la consola del navegador (F12):** Te mostrará errores y mensajes útiles
- **Revisa los logs del backend:** Te dirán si hay problemas con la base de datos o las peticiones
- **Si algo no funciona:** Revisa primero que MySQL y el backend estén corriendo

---

**¡Listo! Ahora puedes probar todo el proyecto en Chrome.** 🎉

Si encuentras algún problema, revisa la sección "Solución de Problemas Comunes" o los logs en las terminales.

