# 🔌 Resumen: Configuración de Conexión para APK

## 🎯 Resumen Ejecutivo

Este documento resume cómo funciona la conexión entre el APK y el backend, tanto para **pruebas locales** como para **producción**.

---

## 📱 Escenario 1: Pruebas Locales (Laptop + Celular)

### Arquitectura

```
┌─────────────┐         WiFi         ┌─────────────┐
│   Laptop    │ ◄──────────────────► │   Celular   │
│ (Backend)   │    (Misma Red)       │   (APK)     │
│ 192.168.1.5 │                      │             │
└─────────────┘                      └─────────────┘
```

### Pasos Rápidos

1. **Obtener IP de la laptop:**
   ```powershell
   ipconfig
   # Buscar "Dirección IPv4" (ej: 192.168.1.5)
   ```
   O ejecutar: `obtener_ip_laptop.bat`

2. **Iniciar backend en laptop:**
   ```bash
   cd backend
   npm run dev
   ```

3. **Generar APK:**
   ```bash
   flutter build apk --release
   ```
   O ejecutar: `generar_apk.bat`

4. **Instalar APK en celular** y configurar IP del servidor (192.168.1.5)

---

## 🏭 Escenario 2: Producción (Servidor Privado + Dispositivos)

### Arquitectura

```
┌──────────────────┐      Internet       ┌─────────────┐
│  Servidor        │      (Módem/4G)     │  Dispositivos│
│  Privado         │ ◄─────────────────► │  (Tablets/  │
│  192.168.1.100   │                     │  Celulares) │
│  (Backend)       │                     │             │
└──────────────────┘                     └─────────────┘
```

### Pasos Rápidos

1. **Configurar backend en servidor:**
   - IP estática: `192.168.1.100` (ejemplo)
   - Iniciar backend: `npm start` o `pm2 start`

2. **Generar APK:**
   ```bash
   flutter build apk --release
   ```

3. **Instalar APK en dispositivos** y configurar IP del servidor (192.168.1.100)

---

## 🔍 Cómo Funciona el Sistema

### Detección Automática

1. La app detecta la IP del dispositivo móvil
2. Determina el rango de red (ej: 192.168.1.x)
3. Prueba IPs comunes del mismo rango
4. Cuando encuentra el servidor, usa esa IP

### Configuración Manual

1. Usuario ingresa IP manualmente desde la app
2. IP se guarda en `SharedPreferences`
3. Se usa en futuras sesiones

### Prioridad de IP

1. **IP guardada manualmente** (más confiable)
2. IP detectada automáticamente
3. IP por defecto (10.0.2.2 para emulador)

---

## 📝 Comandos Útiles

### Generar APK

```bash
# Debug (pruebas)
flutter build apk --debug

# Release (producción)
flutter build apk --release

# Split (más pequeño)
flutter build apk --split-per-abi --release
```

### Obtener IP

```powershell
# Windows
ipconfig

# O ejecutar
obtener_ip_laptop.bat
```

### Verificar Backend

```bash
# Desde servidor
curl http://localhost:3000/health

# Desde otro dispositivo
curl http://192.168.1.100:3000/health
```

---

## ⚠️ Solución Rápida de Problemas

### "No se puede conectar al servidor"

1. ✅ Backend corriendo? → `curl http://localhost:3000/health`
2. ✅ Misma red WiFi? → Verificar en ambos dispositivos
3. ✅ Firewall bloqueando? → Permitir puerto 3000
4. ✅ IP correcta? → Verificar con `ipconfig`

### "Conexión lenta"

1. ✅ Verificar velocidad de WiFi
2. ✅ Cerrar apps que usen internet
3. ✅ Acercarse al router

---

## 📚 Documentación Completa

Para más detalles, ver:
- `GUIA_GENERAR_APK_Y_CONEXION.md` - Guía completa paso a paso

---

**Última actualización**: 2024

