# ✅ Solución: Problema de CORS

## 🔍 Problema Identificado

El backend está funcionando correctamente (puedes acceder a `http://localhost:3000`), pero el frontend Flutter Web no puede conectarse debido a **restricciones de CORS**.

---

## 🔧 Solución

### Paso 1: Corregir Configuración de CORS

**Ejecuta el script de corrección:**

```powershell
cd comandero_flutter\backend\scripts
.\corregir-cors.ps1
```

Este script:
- ✅ Verifica la configuración actual de CORS
- ✅ Actualiza `CORS_ORIGIN` en el archivo `.env` para permitir `localhost:*`
- ✅ Permite conexiones desde cualquier puerto de localhost

---

### Paso 2: Reiniciar el Backend

**IMPORTANTE:** Después de cambiar `.env`, debes reiniciar el backend.

1. **Detén el backend** (Ctrl + C en la terminal donde está corriendo)
2. **Reinícialo:**
   ```powershell
   cd comandero_flutter\backend
   npm run dev
   ```

---

### Paso 3: Verificar que Funcione

1. **Reinicia el frontend** (si está corriendo):
   - Detén Flutter (Ctrl + C)
   - Reinicia: `flutter run -d chrome`

2. **Abre la consola del navegador** (F12 → Console)

3. **Deberías ver:**
   ```
   🔍 Verificando conexión con el backend en http://localhost:3000/api...
   ✅ Conexión exitosa con el backend
   ```

4. **Intenta hacer login:**
   - Usuario: `admin`
   - Contraseña: `Demo1234`

---

## 📝 Configuración de CORS Correcta

El archivo `.env` del backend debe tener:

```env
CORS_ORIGIN=http://localhost:*,http://127.0.0.1:*
```

**Esto permite:**
- ✅ Conexiones desde `http://localhost` con cualquier puerto
- ✅ Conexiones desde `http://127.0.0.1` con cualquier puerto
- ✅ Flutter Web puede conectarse desde cualquier puerto que asigne

---

## 🐛 Si Aún No Funciona

### Verificar que CORS Esté Configurado

```powershell
cd comandero_flutter\backend\scripts
.\verificar-cors.ps1
```

Este script te mostrará la configuración actual de CORS.

---

### Verificar Manualmente

1. **Abre el archivo `.env` del backend:**
   ```
   comandero_flutter\backend\.env
   ```

2. **Busca la línea `CORS_ORIGIN`**

3. **Asegúrate de que tenga:**
   ```
   CORS_ORIGIN=http://localhost:*,http://127.0.0.1:*
   ```

4. **Si no está, agrégalo o actualízalo**

5. **Reinicia el backend**

---

## ✅ Checklist

- [ ] Ejecuté `.\corregir-cors.ps1`
- [ ] Reinicié el backend (`npm run dev`)
- [ ] Reinicié el frontend (`flutter run -d chrome`)
- [ ] La consola del navegador muestra `✅ Conexión exitosa con el backend`
- [ ] Puedo hacer login con `admin` / `Demo1234`

---

## 🎯 Resumen

**El problema era CORS.** El backend no permitía conexiones desde el puerto que Flutter Web estaba usando.

**Solución:**
1. Actualizar `CORS_ORIGIN` en `.env` para permitir `localhost:*`
2. Reiniciar el backend
3. Reiniciar el frontend

**¡Ahora debería funcionar!** 🚀

---

**Última actualización:** 2024-01-15

