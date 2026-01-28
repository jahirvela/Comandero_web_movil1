# ⚡ Pasos Rápidos: Configurar Conexión del APK

## 🎯 Tu IP: **192.168.1.32**

---

## 📱 Pasos en tu Celular (2 minutos)

### Paso 1: Abre la App
- Abre la app **Comandero** en tu celular

### Paso 2: Intenta Login
- Ingresa cualquier usuario y contraseña
- Toca "Iniciar sesión"
- **Espera a que aparezca el error** (es normal, todavía no está configurada la IP)

### Paso 3: Configurar IP
Cuando aparezca el error **"No se pudo conectar al servidor"**:

1. Verás un diálogo con dos botones:
   - **"Cerrar"**
   - **"Configurar IP"** ← **Toca este**

2. Se abrirá la pantalla de configuración

3. En el campo "IP del servidor", ingresa:
   ```
   192.168.1.32
   ```
   (Solo el número, sin `http://` ni `:3000`)

4. Toca **"Probar conexión"**

5. Si dice **"✅ Conexión exitosa"**:
   - Toca **"Guardar"**
   - Vuelve a la pantalla de login

6. **Intenta hacer login de nuevo**
   - Ahora debería funcionar

---

## ✅ Checklist Antes de Configurar

Asegúrate de que:

- [ ] **Backend corriendo** en la laptop:
  ```powershell
  cd comandero_flutter\backend
  npm run dev
  ```
  Debe aparecer: `Comandix API escuchando en http://0.0.0.0:3000`

- [ ] **Celular y laptop en la misma red WiFi**
  - Verifica que ambos estén conectados al mismo WiFi

- [ ] **Firewall permitiendo conexión** (si no funciona, permite el puerto 3000)

---

## 🔍 Si No Aparece el Botón "Configurar IP"

Si intentas hacer login y NO aparece el diálogo con "Configurar IP":

1. **Verifica que el backend esté corriendo**
2. **Verifica que estén en la misma red WiFi**
3. **Cierra completamente la app** y ábrela de nuevo
4. **Intenta hacer login de nuevo** (debe aparecer el error y el diálogo)

---

## 🆘 Si Aún No Funciona

### Probar desde el Navegador del Celular

1. Abre el navegador en tu celular (Chrome, Firefox, etc.)
2. Ve a: `http://192.168.1.32:3000/health`
3. **Si funciona**, deberías ver un JSON con `{"status":"ok",...}`
4. **Si NO funciona**, hay un problema de red o firewall

### Problema: Firewall

Si el navegador del celular tampoco funciona, el firewall de Windows puede estar bloqueando.

**Solución rápida (ejecuta como Administrador):**

```powershell
New-NetFirewallRule -DisplayName "Node.js Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

---

## 📝 Resumen

1. ✅ IP de tu laptop: **192.168.1.32**
2. ✅ Backend corriendo: `npm run dev`
3. ✅ Misma red WiFi
4. ✅ Intentar login → Error → "Configurar IP"
5. ✅ Ingresar: **192.168.1.32**
6. ✅ Probar conexión → Guardar
7. ✅ Login exitoso

---

**¡Listo! Ya debería funcionar.**

