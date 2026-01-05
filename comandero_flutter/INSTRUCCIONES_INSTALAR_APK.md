# 📱 Instrucciones para Instalar el APK en tu Celular

## ✅ APK Generado Exitosamente

**Ubicación:** `build\app\outputs\flutter-apk\app-release.apk`  
**Tamaño:** ~61 MB

---

## 📤 Paso 1: Enviar APK por WhatsApp Web

### Método 1: Desde tu Laptop (Recomendado)

1. **Abre WhatsApp Web** en tu navegador:
   - Ve a: https://web.whatsapp.com
   - Escanea el código QR con tu celular

2. **Busca tu propio número** en los chats (o crea un chat contigo mismo)

3. **Arrastra y suelta** el archivo APK:
   - Abre el explorador de archivos
   - Ve a: `C:\Users\Jahir VS\comandero_web_movil\comandero_flutter\build\app\outputs\flutter-apk\`
   - Arrastra `app-release.apk` al chat de WhatsApp Web
   - O haz clic en el clip 📎 y selecciona el archivo

4. **Envía el archivo** a ti mismo

### Método 2: Desde el Explorador de Archivos

1. **Abre el explorador** de archivos de Windows
2. **Navega a:**
   ```
   C:\Users\Jahir VS\comandero_web_movil\comandero_flutter\build\app\outputs\flutter-apk\
   ```
3. **Haz clic derecho** en `app-release.apk`
4. **Selecciona "Compartir"** → **WhatsApp**
5. **Envía** a tu propio número

---

## 📱 Paso 2: Descargar APK en tu Celular

1. **Abre WhatsApp** en tu celular
2. **Busca el mensaje** que te enviaste con el APK
3. **Descarga el archivo** tocando en él
4. **Espera a que termine** la descarga

---

## 🔓 Paso 3: Permitir Instalación de Fuentes Desconocidas

Android te pedirá permiso para instalar aplicaciones de fuentes desconocidas.

### En Android 8.0+ (Oreo y superior):

1. **Abre "Configuración"** en tu celular
2. **Ve a "Seguridad"** o **"Aplicaciones"**
3. **Habilita "Instalar aplicaciones desconocidas"** o **"Fuentes desconocidas"**
4. O cuando intentes instalar, Android te preguntará:
   - **"¿Permitir que WhatsApp instale aplicaciones?"**
   - Toca **"Permitir esta vez"** o **"Permitir"**

### Si te aparece un mensaje al instalar:

1. **Toca "Configuración"** en el mensaje
2. **Activa el interruptor** para permitir la instalación
3. **Vuelve atrás** y toca "Instalar" de nuevo

---

## 📲 Paso 4: Instalar el APK

1. **Abre el archivo** descargado desde WhatsApp:
   - Toca el mensaje con el APK
   - O ve a Descargas y abre el archivo

2. **Toca "Instalar"**
3. **Espera** a que termine la instalación (puede tardar unos segundos)
4. **Toca "Abrir"** o busca "Comandero" en tus aplicaciones

---

## ⚙️ Paso 5: Configurar IP del Servidor

**IMPORTANTE:** Antes de poder usar la app, debes configurar la IP de tu laptop.

### Obtener IP de tu Laptop:

1. **En tu laptop**, abre PowerShell o CMD
2. **Ejecuta:**
   ```powershell
   ipconfig
   ```
3. **Busca "Dirección IPv4"** del adaptador WiFi o Ethernet
   - Ejemplo: `192.168.1.5` o `192.168.0.10`

### Configurar en el APK:

1. **Abre la app** en tu celular
2. **En la pantalla de login**, busca el botón **"Configurar servidor"** o **⚙️**
3. **Ingresa la IP** de tu laptop (sin `http://` ni puerto)
   - Ejemplo: `192.168.1.5`
4. **Toca "Probar conexión"** o **"Guardar"**
5. **Si dice "Conexión exitosa"**, ya puedes hacer login

---

## 🖥️ Paso 6: Iniciar Backend en la Laptop

**ANTES** de usar la app, asegúrate de que el backend esté corriendo:

1. **Abre PowerShell** o CMD en tu laptop
2. **Navega al directorio del backend:**
   ```powershell
   cd "C:\Users\Jahir VS\comandero_web_movil\comandero_flutter\backend"
   ```
3. **Inicia el backend:**
   ```powershell
   npm run dev
   ```
4. **Espera** a que veas este mensaje:
   ```
   Comandix API escuchando en http://0.0.0.0:3000
   ```

5. **NO cierres esta ventana** mientras uses la app

---

## ✅ Paso 7: Probar la App

1. **Abre la app** en tu celular
2. **Haz login** con cualquier usuario que tengas en la base de datos
3. **Verifica que funcione:**
   - Puedes ver el menú
   - Puedes navegar entre secciones
   - Si eres mesero, puedes ver mesas
   - Si eres cocinero, puedes ver órdenes
   - etc.

---

## ⚠️ Solución de Problemas

### "No se puede conectar al servidor"

1. ✅ **Verifica que el backend esté corriendo** (Paso 6)
2. ✅ **Verifica que estés en la misma red WiFi:**
   - Tu celular y laptop deben estar conectados al mismo WiFi
3. ✅ **Verifica la IP:**
   - Ejecuta `ipconfig` en la laptop
   - Asegúrate de usar la IP correcta (IPv4 del WiFi)
4. ✅ **Verifica el firewall:**
   - Windows puede estar bloqueando el puerto 3000
   - Permite el puerto en el firewall si es necesario

### "La app no encuentra el servidor automáticamente"

- **Configura la IP manualmente** (Paso 5)
- Es más confiable que la detección automática

### "No puedo instalar el APK"

1. ✅ **Verifica que hayas permitido fuentes desconocidas** (Paso 3)
2. ✅ **Revisa el almacenamiento** de tu celular (debe tener espacio suficiente)
3. ✅ **Intenta descargar el APK de nuevo** desde WhatsApp

---

## 🎯 Checklist Rápido

- [ ] Backend corriendo en la laptop (`npm run dev`)
- [ ] Celular y laptop en la misma red WiFi
- [ ] IP de la laptop obtenida (`ipconfig`)
- [ ] APK descargado desde WhatsApp
- [ ] Fuentes desconocidas permitidas en Android
- [ ] APK instalado en el celular
- [ ] IP configurada en la app
- [ ] Login exitoso

---

## 📞 Resumen de Pasos

1. 📤 **Enviar APK por WhatsApp Web** → Tu número
2. 📱 **Descargar APK** en el celular desde WhatsApp
3. 🔓 **Permitir fuentes desconocidas** en Android
4. 📲 **Instalar APK** tocando el archivo
5. ⚙️ **Configurar IP** del servidor en la app
6. 🖥️ **Iniciar backend** en la laptop (`npm run dev`)
7. ✅ **Probar login** y funcionalidades

---

**¡Listo! Ya puedes probar el sistema desde tu celular conectado al backend de tu laptop.**

