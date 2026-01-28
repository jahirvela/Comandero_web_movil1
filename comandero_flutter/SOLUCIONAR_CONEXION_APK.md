# 🔧 Solucionar Problema de Conexión del APK

## 🔍 Problema

El APK en el celular no puede conectarse al backend en la laptop para hacer login.

---

## ✅ Solución Paso a Paso

### Paso 1: Obtener IP de tu Laptop

**Ejecuta en PowerShell/CMD:**

```powershell
ipconfig
```

**Busca "Dirección IPv4"** del adaptador **WiFi** o **Ethernet** (depende de cómo esté conectada tu laptop).

**Ejemplo de salida:**
```
Adaptador de LAN inalámbrica Wi-Fi:
   Dirección IPv4. . . . . . . . . . . . . . . . . . . . . : 192.168.1.5
```

**Anota esta IP** (en el ejemplo: `192.168.1.5`)

---

### Paso 2: Verificar que Backend esté Corriendo

**Verifica que el backend esté corriendo:**

1. Ve a la terminal donde ejecutaste `npm run dev`
2. Debe aparecer algo como:
   ```
   Comandix API escuchando en http://0.0.0.0:3000
   ```

**Si NO está corriendo:**

```powershell
cd comandero_flutter\backend
npm run dev
```

---

### Paso 3: Verificar Conexión desde Laptop

**Prueba que el backend responda:**

Abre un navegador en tu laptop y ve a:
```
http://localhost:3000/health
```

Debe responder con algo como:
```json
{"status":"ok","timestamp":"..."}
```

**Si funciona**, el backend está bien.

---

### Paso 4: Verificar que Estén en la Misma Red WiFi

**IMPORTANTE:** Tu celular y tu laptop DEBEN estar conectados a la **misma red WiFi**.

**Verifica:**
1. En tu celular: Ve a Configuración → WiFi
2. Verifica el nombre de la red WiFi a la que está conectado
3. En tu laptop: Verifica que esté conectada a la misma red WiFi

**Si NO están en la misma red:**
- Conecta ambos a la misma red WiFi
- Es esencial para que funcionen

---

### Paso 5: Configurar IP en el APK

**En tu celular:**

1. **Abre la app** Comandero
2. **En la pantalla de login**, busca uno de estos:
   - Botón **"Configurar servidor"** o **⚙️** (icono de configuración)
   - O toca y mantén presionado en algún lugar de la pantalla de login
   - O busca un menú de configuración

3. **Si no encuentras el botón**, intenta esto:
   - Toca cualquier campo de texto (usuario o contraseña) y luego busca el botón
   - O desliza desde los bordes de la pantalla
   - O busca en la parte superior/inferior de la pantalla

4. **Cuando encuentres la configuración:**
   - Ingresa la IP de tu laptop (la que obtuviste en Paso 1)
   - **Solo la IP, sin `http://` ni puerto**
   - Ejemplo: `192.168.1.5` (NO `http://192.168.1.5:3000`)

5. **Presiona "Probar conexión"** o **"Guardar"**

6. **Si dice "Conexión exitosa"**, ya puedes hacer login

---

### Paso 6: Probar Login

1. **Cierra la app** completamente (cárgala del todo)
2. **Ábrela de nuevo**
3. **Intenta hacer login** con tus credenciales
4. **Si funciona**, ¡listo!

---

## 🔍 Si Aún No Funciona

### Verificar desde el Celular (Navegador)

1. **Abre el navegador** en tu celular (Chrome, Firefox, etc.)
2. **Ve a:** `http://[IP_DE_TU_LAPTOP]:3000/health`
   - Ejemplo: `http://192.168.1.5:3000/health`
3. **Si funciona**, deberías ver un JSON con `{"status":"ok",...}`
4. **Si NO funciona**, hay un problema de red o firewall

### Problema: Firewall de Windows

**Windows puede estar bloqueando el puerto 3000.**

**Solución rápida:**

```powershell
# Ejecuta como Administrador
New-NetFirewallRule -DisplayName "Node.js Backend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

O manualmente:
1. Ve a: **Configuración → Seguridad de Windows → Firewall**
2. **Permitir una app a través del firewall**
3. Busca **Node.js** y permite **Tráfico entrante**

### Problema: Backend no está escuchando en todas las interfaces

**Verifica que el backend esté configurado para escuchar en `0.0.0.0`:**

El backend debe estar configurado para escuchar en `0.0.0.0:3000`, no solo en `localhost:3000`.

**Si tu backend está corriendo con `npm run dev`**, ya debería estar bien configurado.

---

## 🎯 Resumen Rápido

1. ✅ Obtener IP de laptop: `ipconfig` → Buscar IPv4
2. ✅ Backend corriendo: `npm run dev` en `backend/`
3. ✅ Misma red WiFi: Celular y laptop en la misma red
4. ✅ Configurar IP en APK: Pantalla de login → Configurar servidor → Ingresar IP
5. ✅ Probar conexión desde celular
6. ✅ Hacer login

---

## 📱 Ubicación del Botón de Configuración en el APK

El botón puede estar en diferentes lugares dependiendo de la versión:

- **Parte superior** de la pantalla de login (icono ⚙️)
- **Parte inferior** de la pantalla de login
- **Dentro del campo de usuario** (al tocar)
- **Menú desplegable** desde algún icono

Si no lo encuentras, también puedes:
- Intentar hacer login primero (aunque falle)
- Cuando falle, debería aparecer un diálogo con opción "Configurar IP" o "Configurar servidor"

---

**¿Necesitas más ayuda? Comparte:**
- La IP que obtuviste
- Si el backend está corriendo
- Si están en la misma red WiFi
- Si encuentras el botón de configuración en el APK

