# 🖨️ Resumen: Sistema de Impresión de Tickets

## ✅ Estado: FUNCIONAL Y LISTO PARA USO

El sistema de impresión de tickets está **completamente implementado y funcionando**. Este documento explica cómo funciona y cómo configurarlo.

---

## 📋 Roles que Pueden Imprimir

Los siguientes roles tienen permiso para imprimir tickets:

1. ✅ **Administrador** (`administrador`)
2. ✅ **Cajero** (`cajero`)
3. ✅ **Capitán** (`capitan`)

**NOTA**: El rol de **Mesero** (`mesero`) **NO** puede imprimir tickets por seguridad y control.

---

## 🔧 Cómo Funciona el Sistema

### 1. Arquitectura

```
Frontend (Flutter) 
    ↓
POST /api/tickets/imprimir
    ↓
Backend (Node.js/TypeScript)
    ↓
Módulo de Impresión (tickets.printer.ts)
    ↓
Impresora Térmica POS-80 (USB/Red/Archivo)
```

### 2. Flujo de Impresión

1. **Usuario (cajero/admin/capitan)** hace clic en "Imprimir ticket" en la aplicación
2. **Frontend** envía una petición POST a `/api/tickets/imprimir` con el `ordenId`
3. **Backend** obtiene los datos completos de la orden desde la base de datos
4. **Backend** genera el contenido del ticket con comandos ESC/POS
5. **Backend** envía el ticket a la impresora configurada (USB, red, o archivo)
6. **Backend** registra la impresión en la bitácora
7. **Backend** emite evento Socket.IO para notificar a otros usuarios
8. **Frontend** muestra mensaje de éxito o error

---

## ⚙️ Configuración de Impresora

### Variables de Entorno (.env)

El sistema se configura mediante variables de entorno en el archivo `.env` del backend:

```env
# Tipo de impresora
PRINTER_TYPE=pos80              # 'pos80' para impresora real, 'simulation' para pruebas

# Interfaz de conexión
PRINTER_INTERFACE=usb           # 'usb', 'tcp' (red), o 'file' (archivo)

# Para impresora USB (Windows)
PRINTER_DEVICE=XP-80            # Nombre de la impresora o puerto (ej: USB001, LPT1)

# Para impresora de red (TCP/IP)
PRINTER_HOST=192.168.1.100      # IP de la impresora
PRINTER_PORT=9100               # Puerto (generalmente 9100 para RAW)

# Para modo simulación
PRINTER_SIMULATION_PATH=./tickets  # Carpeta donde se guardan los tickets
```

### Configuraciones Comunes

#### 1. Modo Simulación (Desarrollo/Pruebas)

```env
PRINTER_TYPE=simulation
PRINTER_INTERFACE=file
PRINTER_SIMULATION_PATH=./tickets
```

**Resultado**: Los tickets se guardan como archivos `.txt` en la carpeta `backend/tickets/`

#### 2. Impresora USB en Windows

```env
PRINTER_TYPE=pos80
PRINTER_INTERFACE=usb
PRINTER_DEVICE=XP-80
```

**Nota**: `PRINTER_DEVICE` puede ser:
- **Nombre de la impresora** (recomendado): `XP-80`, `POS-80`, `Epson TM-T20`, etc.
- **Puerto USB**: `USB001`, `USB002`, etc.
- **Puerto LPT**: `LPT1`, `LPT2`, etc.

#### 3. Impresora de Red (TCP/IP)

```env
PRINTER_TYPE=pos80
PRINTER_INTERFACE=tcp
PRINTER_HOST=192.168.1.100
PRINTER_PORT=9100
```

---

## 🖨️ Impresoras Compatibles

El sistema es compatible con impresoras térmicas que soporten el estándar **ESC/POS**, incluyendo:

- ✅ **POS-80** (80mm de ancho)
- ✅ **POS-58** (58mm de ancho)
- ✅ **Epson TM series** (TM-T20, TM-T82, etc.)
- ✅ **Xprinter XP series**
- ✅ **Star TSP series**
- ✅ Cualquier impresora térmica compatible con ESC/POS

---

## 📝 Formato del Ticket

El ticket generado incluye:

1. **Encabezado del restaurante**
   - Nombre del restaurante (grande y centrado)
   - Dirección
   - Teléfono
   - RFC (si está configurado)

2. **Datos de la orden**
   - Folio/Número de orden
   - Fecha y hora
   - Mesa (si aplica)
   - Cliente (si aplica)
   - Cajero

3. **Items de la orden**
   - Cantidad
   - Descripción del producto
   - Precio unitario
   - Total por línea
   - Modificadores (si aplica)
   - Notas (si aplica)

4. **Totales**
   - Subtotal
   - Descuentos (si aplica)
   - Impuestos (si aplica)
   - Propina sugerida (si aplica)
   - **TOTAL** (en negrita)

5. **Código de barras** (opcional)
   - Code128 con el folio de la orden
   - Texto debajo del código

6. **Mensaje final**
   - "¡Gracias por su preferencia!"
   - "Vuelva pronto"

7. **Corte de papel** (automático)

---

## 🔌 Conexión USB en Windows

### Pasos para Conectar

1. **Instalar la impresora en Windows**
   - Conectar la impresora vía USB
   - Instalar los controladores del fabricante
   - Verificar que aparezca en "Dispositivos e impresoras"

2. **Identificar el nombre de la impresora**
   - Ir a Configuración → Dispositivos → Impresoras y escáneres
   - Anotar el nombre exacto de la impresora

3. **Configurar en .env**
   ```env
   PRINTER_TYPE=pos80
   PRINTER_INTERFACE=usb
   PRINTER_DEVICE=NombreDeTuImpresora
   ```

4. **Reiniciar el backend**

5. **Probar la impresión**

### Métodos de Conexión

El sistema intenta dos métodos en Windows:

1. **Método 1: escpos-usb** (intento principal)
   - Usa la librería `escpos-usb` para comunicación directa
   - Funciona si la impresora es reconocida como dispositivo USB

2. **Método 2: Windows Nativo** (fallback)
   - Si escpos-usb falla, usa comandos nativos de Windows
   - Usa el nombre de la impresora instalada en Windows
   - Funciona con cualquier impresora instalada en Windows

---

## 🧪 Pruebas

### Probar en Modo Simulación

1. Configurar `.env`:
   ```env
   PRINTER_TYPE=simulation
   PRINTER_INTERFACE=file
   ```

2. Iniciar el backend

3. Intentar imprimir un ticket desde la aplicación

4. Verificar que se creó un archivo en `backend/tickets/ticket-YYYY-MM-DD-HH-mm-ss.txt`

### Probar con Impresora Real

1. Configurar `.env` con los datos de tu impresora

2. Reiniciar el backend

3. Intentar imprimir un ticket desde la aplicación

4. Verificar que el ticket se imprime correctamente

---

## 🔍 Solución de Problemas

### Error: "No se pudo conectar a la impresora USB"

**Soluciones:**
1. Verificar que la impresora esté encendida y conectada
2. Verificar el nombre/puerto en `PRINTER_DEVICE` (mayúsculas/minúsculas importan)
3. Probar con el puerto USB en lugar del nombre (ej: `USB001`)
4. Reinstalar los controladores de la impresora
5. Verificar que la impresora esté "En línea" en Windows

### El ticket se imprime pero el formato está mal

**Soluciones:**
1. Verificar que la impresora sea compatible con ESC/POS
2. Verificar el ancho del papel (el sistema está configurado para 80mm)
3. Ajustar la configuración de la impresora en Windows si es necesario

### El código de barras no aparece

**Soluciones:**
1. Verificar que `incluirCodigoBarras` esté en `true` (es el valor por defecto)
2. Verificar que la impresora soporte códigos de barras Code128

---

## 📚 Archivos Importantes

### Backend

- `backend/src/modules/tickets/tickets.printer.ts` - Lógica de impresión
- `backend/src/modules/tickets/tickets.service.ts` - Servicio de tickets
- `backend/src/modules/tickets/tickets.controller.ts` - Controlador de endpoints
- `backend/src/modules/tickets/tickets.routes.ts` - Rutas y permisos
- `backend/src/config/env.ts` - Configuración de variables de entorno

### Frontend

- `lib/services/tickets_service.dart` - Servicio Flutter para imprimir tickets

### Documentación

- `backend/docs/CONFIGURAR_IMPRESORA_USB.md` - Guía detallada de configuración
- `backend/docs/IMPRESION_REPORTES_ALERTAS.md` - Documentación técnica completa

---

## ✅ Conclusión

El sistema de impresión está **completamente funcional** y listo para uso en producción. Solo necesitas:

1. ✅ Configurar las variables de entorno en `.env`
2. ✅ Conectar la impresora USB e instalarla en Windows
3. ✅ Probar en modo simulación primero
4. ✅ Cambiar a modo real y probar con la impresora física

---

**Última actualización**: 2024  
**Versión del sistema**: 1.0.0

