# ⚡ Pasos Rápidos: Generar y Usar el APK

## 🎯 Objetivo

Generar el APK, instalarlo en tu celular/tablet, y conectarlo al backend para hacer pruebas.

---

## 📦 Paso 1: Generar el APK

### Opción A: Usar el Script (Más Fácil)

```bash
# En Windows
generar_apk.bat
```

Selecciona la opción **2** (APK Release).

### Opción B: Comando Manual

```bash
cd comandero_flutter
flutter build apk --release
```

**Ubicación del APK generado:**
```
comandero_flutter\build\app\outputs\flutter-apk\app-release.apk
```

---

## 🔌 Paso 2: Obtener IP de tu Laptop

### Opción A: Usar el Script

```bash
obtener_ip_laptop.bat
```

### Opción B: Comando Manual

```powershell
ipconfig
```

**Busca "Dirección IPv4"** de tu adaptador WiFi o Ethernet (ejemplo: `192.168.1.5`)

---

## 💻 Paso 3: Iniciar Backend en Laptop

```bash
cd comandero_flutter/backend
npm run dev
```

**Verifica que diga:**
```
Comandix API escuchando en http://0.0.0.0:3000
```

---

## 📱 Paso 4: Instalar APK en Celular

1. **Copiar APK al celular:**
   - Conecta el celular por USB y copia el archivo `app-release.apk`
   - O envíalo por email/WhatsApp/Drive

2. **Instalar:**
   - Abre el archivo APK en el celular
   - Permite "Fuentes desconocidas" si te lo pide
   - Instala

---

## ⚙️ Paso 5: Configurar IP en el APK

1. **Abre la app** en el celular
2. **En la pantalla de login**, busca el botón **"Configurar servidor"** o **⚙️**
3. **Ingresa la IP** de tu laptop (la que obtuviste en Paso 2)
   - Ejemplo: `192.168.1.5`
4. **Presiona "Probar conexión"**
5. **Si dice "Conexión exitosa"**, presiona "Guardar"

---

## ✅ Paso 6: Probar

1. **Haz login** con cualquier usuario
2. **Prueba las funcionalidades** según el rol:
   - **Mesero**: Crear órdenes, ver mesas
   - **Cocinero**: Ver órdenes, actualizar estados
   - **Cajero**: Procesar pagos, imprimir tickets
   - **Administrador**: Ver todo, gestionar inventario

---

## 🏭 Para Producción (Servidor Privado)

Cuando tengas el servidor privado funcionando:

1. **Obtén la IP del servidor** (ejemplo: `192.168.1.100`)
2. **Instala el APK** en los dispositivos
3. **Configura la IP del servidor** en cada dispositivo (mismo proceso que Paso 5)
4. **Listo!** Todos los dispositivos se conectarán al servidor

---

## ⚠️ Solución Rápida de Problemas

### "No se puede conectar"

1. ✅ Backend corriendo? → Ver Paso 3
2. ✅ Misma red WiFi? → Celular y laptop en la misma red
3. ✅ IP correcta? → Verificar con `ipconfig`
4. ✅ Firewall? → Permitir puerto 3000 en Windows

### "App no encuentra el servidor"

1. **Configura IP manualmente** (Paso 5)
2. **Es más confiable** que la detección automática

---

## 📚 Documentación Completa

Para más detalles, ver:
- `GUIA_GENERAR_APK_Y_CONEXION.md` - Guía completa
- `RESUMEN_CONFIGURACION_CONEXION.md` - Resumen técnico

---

**¡Listo!** Ya puedes probar el sistema desde tu celular conectado al backend de tu laptop.

