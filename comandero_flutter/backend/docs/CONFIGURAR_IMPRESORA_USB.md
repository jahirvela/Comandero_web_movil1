# 🖨️ Guía: Configurar Impresora Térmica USB POS-80 en Windows

Esta guía explica cómo configurar una impresora térmica USB POS-80 para que funcione con el sistema Comandero.

---

## 📋 Requisitos Previos

1. **Impresora térmica POS-80** compatible con comandos ESC/POS
2. **Cable USB** para conectar la impresora a la computadora
3. **Controladores** de la impresora instalados en Windows
4. **Windows 10/11** (o Windows 7/8.1)

---

## 🔧 Paso 1: Instalar la Impresora en Windows

### Opción A: Instalación Automática (Recomendada)

1. **Conectar la impresora** al puerto USB de la computadora
2. **Encender la impresora**
3. Windows debería detectar automáticamente la impresora
4. Si Windows no la detecta automáticamente:
   - Ir a **Configuración** → **Dispositivos** → **Impresoras y escáneres**
   - Hacer clic en **Agregar impresora o escáner**
   - Seguir las instrucciones del asistente

### Opción B: Instalación Manual con Controladores

1. **Descargar los controladores** del sitio web del fabricante
2. **Instalar los controladores** antes de conectar la impresora (si es posible)
3. **Conectar la impresora** y seguir las instrucciones del instalador
4. **Verificar la instalación**:
   - Ir a **Configuración** → **Dispositivos** → **Impresoras y escáneres**
   - Confirmar que la impresora aparece en la lista

---

## 🔍 Paso 2: Identificar el Nombre o Puerto de la Impresora

Después de instalar la impresora, necesitas identificar cómo Windows la reconoce. Tienes dos opciones:

### Opción 1: Nombre de la Impresora (Recomendado)

1. Ir a **Configuración** → **Dispositivos** → **Impresoras y escáneres**
2. Buscar tu impresora en la lista
3. **Anotar el nombre exacto** de la impresora (por ejemplo: "XP-80", "POS-80", "Epson TM-T20", etc.)

### Opción 2: Puerto de la Impresora

1. Ir a **Configuración** → **Dispositivos** → **Impresoras y escáneres**
2. Hacer clic en tu impresora
3. Hacer clic en **Administrar** → **Propiedades de la impresora**
4. Ir a la pestaña **Puertos**
5. Ver el puerto asignado (puede ser algo como `USB001`, `LPT1`, `COM3`, etc.)

**Nota**: Para impresoras USB modernas, Windows generalmente usa `USB001`, `USB002`, etc.

---

## ⚙️ Paso 3: Configurar el Sistema Comandero

### Editar el archivo `.env`

Abre el archivo `.env` en la carpeta `backend` y configura las siguientes variables:

```env
# Tipo de impresora: 'pos80' para impresora real, 'simulation' para pruebas
PRINTER_TYPE=pos80

# Interfaz: 'usb' para USB, 'tcp' para red, 'file' para guardar en archivo
PRINTER_INTERFACE=usb

# Nombre de la impresora o puerto (ejemplos):
# Opción 1: Nombre de la impresora (recomendado)
PRINTER_DEVICE=XP-80

# Opción 2: Puerto USB de Windows
# PRINTER_DEVICE=USB001

# Opción 3: Puerto LPT (si aplica)
# PRINTER_DEVICE=LPT1

# Opción 4: Puerto COM (si aplica, menos común para USB)
# PRINTER_DEVICE=COM3
```

### Ejemplos de Configuración

#### Ejemplo 1: Nombre de Impresora (Más Confiable)

```env
PRINTER_TYPE=pos80
PRINTER_INTERFACE=usb
PRINTER_DEVICE=XP-80
```

#### Ejemplo 2: Puerto USB

```env
PRINTER_TYPE=pos80
PRINTER_INTERFACE=usb
PRINTER_DEVICE=USB001
```

#### Ejemplo 3: Puerto LPT (Para Impresoras Antiguas)

```env
PRINTER_TYPE=pos80
PRINTER_INTERFACE=usb
PRINTER_DEVICE=LPT1
```

---

## 🧪 Paso 4: Probar la Configuración

### Modo Simulación (Recomendado Primero)

Antes de probar con la impresora real, prueba en modo simulación:

```env
PRINTER_TYPE=simulation
PRINTER_INTERFACE=file
PRINTER_SIMULATION_PATH=./tickets
```

1. **Iniciar el backend**:
   ```bash
   cd backend
   npm run dev
   ```

2. **Intentar imprimir un ticket** desde la aplicación

3. **Verificar** que se creó un archivo en la carpeta `backend/tickets/`

### Modo Real (Después de Verificar)

Una vez que la simulación funciona:

1. **Cambiar a modo real** en `.env`:
   ```env
   PRINTER_TYPE=pos80
   PRINTER_INTERFACE=usb
   PRINTER_DEVICE=XP-80  # Cambiar por el nombre de tu impresora
   ```

2. **Reiniciar el backend**

3. **Probar imprimir un ticket** desde la aplicación

4. **Verificar** que el ticket se imprime correctamente

---

## 🔍 Solución de Problemas

### Error: "No se pudo conectar a la impresora USB"

**Soluciones:**

1. **Verificar que la impresora esté encendida y conectada**
   - Revisar el cable USB
   - Verificar que el LED de la impresora esté encendido

2. **Verificar el nombre/puerto de la impresora**
   - Ir a Configuración → Dispositivos → Impresoras y escáneres
   - Confirmar el nombre exacto (mayúsculas/minúsculas importan)
   - Si usas puerto, verificar que sea correcto

3. **Probar con un nombre diferente**
   - Intentar con el puerto USB en lugar del nombre
   - Ejemplo: cambiar `XP-80` por `USB001`

4. **Reinstalar los controladores**
   - Desinstalar la impresora en Windows
   - Reiniciar la computadora
   - Volver a instalar los controladores

5. **Verificar permisos**
   - Asegurarse de que el backend tenga permisos para acceder a la impresora
   - En algunos casos, ejecutar el backend como administrador puede ayudar

### Error: "Impresora no responde"

**Soluciones:**

1. **Probar impresión de prueba desde Windows**
   - Ir a la impresora en Windows
   - Hacer clic derecho → **Propiedades de la impresora**
   - Ir a la pestaña **General**
   - Hacer clic en **Imprimir página de prueba**

2. **Verificar que la impresora esté en línea**
   - Ir a Configuración → Dispositivos → Impresoras y escáneres
   - Verificar que la impresora muestre "Lista" o "En línea"

3. **Revisar papel y tinta**
   - Verificar que haya papel en la impresora
   - Verificar que la tinta/ribbon esté bien (si aplica)

### El ticket se imprime pero el formato está mal

**Soluciones:**

1. **Verificar que la impresora sea compatible con ESC/POS**
   - La mayoría de impresoras térmicas POS-80 son compatibles
   - Si no lo es, puede que necesites configurar la impresora diferente

2. **Ajustar ancho de papel**
   - Algunas impresoras tienen diferentes anchos (58mm, 80mm)
   - El sistema está configurado para 80mm (estándar POS-80)

---

## 📝 Notas Importantes

1. **Nombre de Impresora vs Puerto**:
   - Usar el **nombre de la impresora** es más confiable porque no cambia
   - El puerto USB puede cambiar si conectas otros dispositivos USB

2. **Múltiples Impresoras**:
   - Si tienes múltiples impresoras, puedes configurar diferentes nombres/puertos
   - El sistema actualmente solo soporta una impresora a la vez

3. **Permisos en Windows**:
   - En algunos casos, Windows puede pedir permisos para acceder a la impresora
   - Asegúrate de permitir el acceso cuando Windows lo solicite

4. **Reiniciar Backend**:
   - Después de cambiar la configuración en `.env`, **reiniciar el backend** es necesario

---

## 🎯 Roles que Pueden Imprimir

Los siguientes roles pueden imprimir tickets:

- ✅ **Administrador** (`administrador`)
- ✅ **Cajero** (`cajero`)
- ✅ **Capitán** (`capitan`)

El rol de **Mesero** (`mesero`) **NO** puede imprimir tickets por seguridad.

---

## 📞 Soporte

Si después de seguir esta guía sigues teniendo problemas:

1. **Revisar los logs** del backend para ver errores específicos
2. **Probar en modo simulación** primero para verificar que el sistema funciona
3. **Verificar la documentación** del fabricante de tu impresora
4. **Contactar al soporte técnico** si es necesario

---

**Última actualización**: 2024  
**Versión del sistema**: 1.0.0

