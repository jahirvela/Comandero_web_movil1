# 🔄 Cómo Reiniciar el Frontend Correctamente

## ⚠️ Importante

**Solo refrescar (F5) NO es suficiente** cuando hay cambios en la configuración o servicios.

Necesitas **reiniciar completamente** el frontend.

---

## 🚀 Pasos para Reiniciar el Frontend

### Paso 1: Detener el Frontend Actual

**📍 ¿En qué terminal?**

Flutter se ejecuta en una **terminal separada** (NO en la terminal de Cursor donde está el backend).

**Tienes 2 opciones:**

#### Opción A: Si Flutter está corriendo en una terminal de Dart/Flutter separada

1. **Ve a esa terminal de Dart/Flutter** (la que ejecutaste `flutter run -d chrome`)
2. **Presiona `Ctrl + C`** para detener el proceso
3. **Espera** a que se detenga completamente (verás "Application finished")

#### Opción B: Si no encuentras la terminal o Flutter está corriendo en segundo plano

1. **Abre una nueva terminal** (PowerShell o CMD)
2. **Busca el proceso de Flutter:**
   ```powershell
   Get-Process | Where-Object {$_.ProcessName -like "*dart*" -or $_.ProcessName -like "*flutter*"}
   ```
3. **O cierra Chrome completamente** (esto también detendrá Flutter si está en modo web)
4. **Luego continúa con el Paso 2**

**💡 Nota:** Si ejecutaste `flutter run -d chrome` desde la terminal de Cursor, entonces sí, detén el proceso ahí con `Ctrl + C`.

---

### Paso 2: Limpiar la Caché (Opcional pero Recomendado)

```powershell
cd comandero_flutter
flutter clean
flutter pub get
```

**Esto:**
- ✅ Limpia archivos compilados antiguos
- ✅ Reinstala dependencias
- ✅ Asegura que los cambios se apliquen

---

### Paso 3: Reiniciar el Frontend

```powershell
flutter run -d chrome
```

**Espera a que:**
- ✅ Se compile completamente
- ✅ Se abra Chrome automáticamente
- ✅ Veas la pantalla de login

---

## 🔍 Verificar que Todo Funcione

### 1. Abre la Consola del Navegador

1. **Presiona `F12`** en Chrome
2. **Ve a la pestaña "Console"**
3. **Busca mensajes que empiecen con:**
   - `=== ApiConfig ===` (debería mostrar la URL correcta)
   - `Intentando login con usuario: admin`
   - `✅ Tokens guardados correctamente` (si el login funciona)

---

### 2. Verifica la URL de la API

En la consola, deberías ver algo como:

```
=== ApiConfig ===
Environment: development
Base URL: http://localhost:3000/api
Socket URL: http://localhost:3000
Timeout: 30s
Max Retries: 2
================
```

**Si la URL es diferente**, hay un problema de configuración.

---

### 3. Intenta Hacer Login

1. **Usuario:** `admin`
2. **Contraseña:** `Demo1234`
3. **Observa la consola** para ver los mensajes

---

## 🐛 Si Aún No Funciona

### Verifica que el Backend Esté Corriendo

```powershell
cd comandero_flutter\backend
npm run dev
```

**Deberías ver:**
```
🚀 Servidor iniciado en http://localhost:3000
```

---

### Verifica la Conexión desde el Navegador

1. **Abre Chrome**
2. **Ve a:** `http://localhost:3000/api/health`
3. **Deberías ver:**
   ```json
   {"status":"ok","timestamp":"..."}
   ```

**Si no ves esto**, el backend no está corriendo o hay un problema de red.

---

### Verifica CORS

Si ves errores de CORS en la consola:

1. **Verifica el archivo `.env` del backend:**
   ```env
   CORS_ORIGIN=http://localhost:*,http://127.0.0.1:*
   ```

2. **Reinicia el backend** después de cambiar `.env`

---

## ✅ Checklist de Verificación

Antes de intentar login, verifica:

- [ ] Backend está corriendo (`npm run dev` en la terminal del backend)
- [ ] Frontend está corriendo (`flutter run -d chrome`)
- [ ] Puedes acceder a `http://localhost:3000/api/health` en el navegador
- [ ] La consola del navegador muestra la URL correcta (`http://localhost:3000/api`)
- [ ] No hay errores de CORS en la consola
- [ ] El usuario admin existe (ejecuta `node scripts/crear-usuario-admin.cjs` si no estás seguro)

---

## 🎯 Resumen

**NO solo refresques (F5).** Necesitas:

1. ✅ Detener el frontend (`Ctrl + C`)
2. ✅ Reiniciar el frontend (`flutter run -d chrome`)
3. ✅ Verificar la consola del navegador
4. ✅ Intentar login nuevamente

---

**Última actualización:** 2024-01-15

