# 🔧 Solución Rápida: Configurar IP del Servidor

## ⚠️ Problema

Tocaste "Configurar IP" pero no apareció nada.

---

## ✅ Solución Alternativa (Más Rápida)

Ya que la pantalla de configuración puede tener problemas, puedes configurar la IP directamente usando una **variable de entorno** o **modificando temporalmente el código**.

Pero hay una forma **MÁS SIMPLE** que no requiere recompilar:

---

## 🎯 Opción 1: Usar el Navegador del Celular (Temporal)

Mientras solucionamos el problema del APK, puedes **probar que la conexión funcione** desde el navegador:

1. **Abre el navegador** en tu celular (Chrome, Firefox, etc.)
2. **Ve a:** `http://192.168.1.32:3000/health`
3. **Si funciona**, deberías ver un JSON
4. Esto confirma que la red está bien

---

## 🎯 Opción 2: Recompilar APK con IP Hardcodeada (Recomendado)

La forma más segura es **recompilar el APK con tu IP específica**:

### Paso 1: Editar api_config.dart

Abre el archivo: `comandero_flutter/lib/config/api_config.dart`

Busca la línea 31-34 y cámbiala temporalmente:

**ANTES:**
```dart
static const String _productionApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://api.comandix.com',
);
```

**DESPUÉS (temporalmente para pruebas):**
```dart
static const String _productionApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://192.168.1.32:3000/api',  // TU IP AQUÍ
);
```

### Paso 2: También cambiar la URL de desarrollo

Busca la línea 304-326 (función `_developmentApiUrlSync`) y en la parte que dice:

**ANTES:**
```dart
return 'http://10.0.2.2:3000/api';
```

**DESPUÉS:**
```dart
return 'http://192.168.1.32:3000/api';  // TU IP AQUÍ
```

### Paso 3: Recompilar APK

```powershell
cd comandero_flutter
flutter build apk --release
```

### Paso 4: Instalar el nuevo APK

1. Desinstala el APK anterior
2. Instala el nuevo APK
3. Ya debería conectarse directamente

---

## 🎯 Opción 3: Usar ADB para Configurar (Si tienes ADB)

Si tienes ADB instalado y el celular conectado:

```powershell
adb shell "run-as com.example.comandero_flutter sh -c 'echo \"192.168.1.32\" > /data/data/com.example.comandero_flutter/shared_prefs/flutter.manual_server_ip.xml'"
```

Pero esto es más complejo.

---

## 🎯 Opción 4: Verificar Logs del APK (Para Debug)

Si el APK está en modo debug, puedes ver los logs:

```powershell
adb logcat | findstr "comandero"
```

Pero si compilaste en release, los logs son limitados.

---

## ✅ RECOMENDACIÓN: Opción 2

**La Opción 2 (recompilar con IP hardcodeada) es la más confiable** para pruebas iniciales.

Una vez que confirmes que funciona, podemos arreglar la pantalla de configuración para que funcione correctamente.

---

## 📝 Resumen Rápido

**TU IP:** `192.168.1.32`

**Solución más rápida:**
1. Editar `lib/config/api_config.dart`
2. Cambiar IP por defecto a `192.168.1.32:3000`
3. Recompilar APK: `flutter build apk --release`
4. Instalar nuevo APK
5. Probar login

---

¿Quieres que te ayude a hacer la Opción 2? Puedo hacer los cambios en el código por ti.

