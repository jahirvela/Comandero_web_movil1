# 📄 Documentación: Impresión, Reportes y Alertas

## 🎯 Resumen

Este documento explica las nuevas funcionalidades implementadas:
1. **Impresión de tickets térmicos POS-80**
2. **Generación de reportes PDF y CSV**
3. **Sistema de alertas en tiempo real mejorado**

---

## 🖨️ 1. IMPRESIÓN DE TICKETS TÉRMICOS

### Librería Utilizada

**escpos (v3.0.0-alpha.6)** con soporte para:
- `escpos-network` - Impresoras de red (TCP/IP)
- `escpos-usb` - Impresoras USB
- Modo simulación - Guarda tickets en archivos .txt

### Configuración

Agregar al archivo `.env` del backend:

```env
# Tipo de impresora: 'pos80' o 'simulation'
PRINTER_TYPE=simulation

# Interfaz: 'usb', 'tcp' o 'file'
PRINTER_INTERFACE=file

# Para impresora de red
PRINTER_HOST=192.168.1.100
PRINTER_PORT=9100

# Para impresora USB (ruta del dispositivo)
PRINTER_DEVICE=/dev/usb/lp0

# Para modo simulación o archivo
PRINTER_SIMULATION_PATH=./tickets

# Configuración del restaurante (opcional)
RESTAURANTE_NOMBRE=Comandix Restaurant
RESTAURANTE_DIRECCION=Calle Principal 123
RESTAURANTE_TELEFONO=555-1234
RESTAURANTE_RFC=ABC123456789
```

### Endpoint

**POST** `/api/tickets/imprimir`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Body:**
```json
{
  "ordenId": 123,
  "incluirCodigoBarras": true
}
```

**Respuesta exitosa (200):**
```json
{
  "success": true,
  "data": {
    "mensaje": "Ticket impreso exitosamente",
    "rutaArchivo": "./tickets/ticket-2024-01-15T10-30-00.txt"
  }
}
```

**Respuesta con error (500):**
```json
{
  "success": false,
  "error": "No se pudo conectar a la impresora en 192.168.1.100:9100"
}
```

### Permisos

Solo usuarios con roles `cajero` o `administrador` pueden imprimir tickets.

### Uso desde Flutter

```dart
import 'services/tickets_service.dart';

final ticketsService = TicketsService();

// Imprimir ticket
final resultado = await ticketsService.imprimirTicket(
  ordenId: 123,
  incluirCodigoBarras: true,
);

if (resultado['success'] == true) {
  print('Ticket impreso: ${resultado['data']['mensaje']}');
} else {
  print('Error: ${resultado['error']}');
}
```

### Formato del Ticket

El ticket incluye:
- Encabezado del restaurante (nombre, dirección, teléfono, RFC)
- Folio de la orden (ej: ORD-000123)
- Fecha y hora
- Mesa y cliente (si aplica)
- Cajero que imprimió
- Lista de productos con cantidad, descripción y precio
- Modificadores de productos
- Notas especiales
- Subtotal, descuentos, impuestos, propina sugerida
- Total
- Código de barras Code128 (opcional)
- Mensaje de agradecimiento

---

## 📊 2. REPORTES PDF Y CSV

### Librerías Utilizadas

- **pdfkit (v0.17.2)** - Generación de PDFs
- **json2csv (v6.0.0-alpha.2)** - Conversión de JSON a CSV

### Endpoints Disponibles

#### Reporte de Ventas

**GET** `/api/reportes/ventas/pdf?fechaInicio=2024-01-01&fechaFin=2024-01-31`

**GET** `/api/reportes/ventas/csv?fechaInicio=2024-01-01&fechaFin=2024-01-31`

**Permisos:** `administrador`, `cajero`

#### Top Productos

**GET** `/api/reportes/top-productos/pdf?fechaInicio=2024-01-01&fechaFin=2024-01-31&limite=10`

**GET** `/api/reportes/top-productos/csv?fechaInicio=2024-01-01&fechaFin=2024-01-31&limite=10`

**Permisos:** `administrador`

#### Corte de Caja

**GET** `/api/reportes/corte-caja/pdf?fecha=2024-01-15&cajeroId=5`

**GET** `/api/reportes/corte-caja/csv?fecha=2024-01-15&cajeroId=5`

**Permisos:** `administrador`, `cajero`

#### Reporte de Inventario

**GET** `/api/reportes/inventario/pdf?fechaInicio=2024-01-01&fechaFin=2024-01-31`

**GET** `/api/reportes/inventario/csv?fechaInicio=2024-01-01&fechaFin=2024-01-31`

**Permisos:** `administrador`

### Uso desde Flutter

```dart
import 'services/reportes_service.dart';

final reportesService = ReportesService();

// Generar reporte de ventas en PDF
await reportesService.generarReporteVentasPDF(
  fechaInicio: DateTime(2024, 1, 1),
  fechaFin: DateTime(2024, 1, 31),
);

// Generar corte de caja en CSV
await reportesService.generarCorteCajaCSV(
  fecha: DateTime.now(),
  cajeroId: 5, // Opcional
);
```

Los archivos se descargan automáticamente y se abren/comparten según la plataforma.

---

## 🔔 3. SISTEMA DE ALERTAS EN TIEMPO REAL

### Tipos de Alertas

| Tipo | Descripción | Roles Destino |
|------|-------------|---------------|
| `alerta.demora` | Orden con mucho tiempo en cocina | `capitan`, `cocinero` |
| `alerta.cancelacion` | Orden cancelada | `capitan`, `cocinero`, `mesero` |
| `alerta.modificacion` | Cambio en una orden | `capitan`, `cocinero` |
| `alerta.caja` | Problemas con pagos/caja | `administrador`, `cajero` |
| `alerta.cocina` | Alertas generales de cocina | `cocinero` |
| `alerta.mesa` | Alertas relacionadas con mesas | `capitan`, `mesero` |
| `alerta.pago` | Alertas de pagos | `cajero`, `administrador` |

### Estructura de una Alerta

```typescript
{
  tipo: "alerta.demora",
  mensaje: "Orden #123 lleva 25 minutos en cocina",
  ordenId: 123,
  prioridad: "alta", // "baja" | "media" | "alta" | "urgente"
  estacion: "parrilla", // Opcional
  emisor: {
    id: 1,
    username: "sistema",
    rol: "sistema"
  },
  timestamp: "2024-01-15T10:30:00Z",
  metadata: {
    tiempoEspera: 25
  }
}
```

### Uso desde Flutter

```dart
import 'services/socket_service.dart';

final socketService = SocketService();

// Escuchar todas las alertas
socketService.onAlerta((tipo, data) {
  print('Alerta recibida: $tipo');
  print('Mensaje: ${data['mensaje']}');
  print('Prioridad: ${data['prioridad']}');
  
  // Mostrar notificación según prioridad
  if (data['prioridad'] == 'urgente') {
    // Mostrar alerta urgente
  }
});

// O escuchar tipos específicos
socketService.onAlertaDemora((data) {
  print('Alerta de demora: ${data['mensaje']}');
});

socketService.onAlertaCancelacion((data) {
  print('Orden cancelada: ${data['ordenId']}');
});
```

### Base de Datos

Las alertas se guardan en la tabla `alerta`. Ejecutar el script:

```sql
-- Ver: backend/scripts/create-alertas-table.sql
```

### Emisión de Alertas desde el Backend

```typescript
import { emitirAlertaDemora, emitirAlertaCancelacion } from './modules/alertas/alertas.service';

// Alerta de demora
await emitirAlertaDemora(ordenId, tiempoEspera, usuarioId);

// Alerta de cancelación
await emitirAlertaCancelacion(ordenId, motivo, usuarioId, username, rol);
```

---

## 🗄️ 4. TABLAS DE BASE DE DATOS

### Tabla `alerta`

```sql
CREATE TABLE alerta (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tipo VARCHAR(50) NOT NULL,
  mensaje TEXT NOT NULL,
  orden_id BIGINT UNSIGNED NULL,
  mesa_id BIGINT UNSIGNED NULL,
  producto_id BIGINT UNSIGNED NULL,
  prioridad ENUM('baja', 'media', 'alta', 'urgente') DEFAULT 'media',
  estacion VARCHAR(50) NULL,
  creado_por_usuario_id BIGINT UNSIGNED NOT NULL,
  leido TINYINT(1) DEFAULT 0,
  leido_por_usuario_id BIGINT UNSIGNED NULL,
  leido_en TIMESTAMP NULL,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  -- Foreign keys...
);
```

### Tabla `bitacora_impresion` (Opcional)

```sql
CREATE TABLE bitacora_impresion (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  orden_id BIGINT UNSIGNED NOT NULL,
  usuario_id BIGINT UNSIGNED NULL,
  exito TINYINT(1) DEFAULT 1,
  mensaje TEXT NULL,
  creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  -- Foreign keys...
);
```

**Ejecutar:** `backend/scripts/create-alertas-table.sql`

---

## ✅ 5. CHECKLIST DE IMPLEMENTACIÓN

### Backend

- [x] Módulo de tickets creado
- [x] Módulo de reportes creado
- [x] Módulo de alertas creado
- [x] Rutas agregadas a `/api/tickets` y `/api/reportes`
- [x] Variables de entorno configuradas
- [x] Script SQL para tablas creado

### Frontend

- [x] `TicketsService` creado
- [x] `ReportesService` creado
- [x] `SocketService` actualizado con listeners de alertas
- [x] Dependencias agregadas a `pubspec.yaml`

### Próximos Pasos

1. **Ejecutar script SQL** en MySQL Workbench:
   ```sql
   -- Ejecutar: backend/scripts/create-alertas-table.sql
   ```

2. **Configurar variables de entorno** en `backend/.env`:
   ```env
   PRINTER_TYPE=simulation
   PRINTER_INTERFACE=file
   PRINTER_SIMULATION_PATH=./tickets
   ```

3. **Instalar dependencias de Flutter**:
   ```bash
   flutter pub get
   ```

4. **Probar endpoints** desde Swagger:
   - `http://localhost:3000/docs`

5. **Integrar en UI de Flutter**:
   - Agregar botones "Imprimir ticket" en pantalla de cajero
   - Agregar botones "Exportar PDF/CSV" en pantallas de reportes
   - Mostrar alertas en tiempo real en pantallas de capitán/cocinero

---

## 📝 NOTAS IMPORTANTES

1. **Modo Simulación**: Por defecto, la impresora está en modo simulación. Los tickets se guardan en `./tickets/` como archivos `.txt`.

2. **Permisos**: Todos los endpoints requieren autenticación JWT y roles específicos.

3. **Encoding CSV**: Los CSV incluyen BOM UTF-8 para compatibilidad con Excel.

4. **Alertas Urgentes**: Las alertas con prioridad `urgente` se emiten a todos los clientes conectados.

5. **Reconexión Socket.IO**: El servicio de Socket.IO maneja automáticamente la reconexión si se pierde la conexión.

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### Error: "No se pudo conectar a la impresora"

- Verificar que la impresora esté encendida y conectada
- Verificar `PRINTER_HOST` y `PRINTER_PORT` en `.env`
- Para USB, verificar que el dispositivo esté disponible

### Error: "Tabla alerta no existe"

- Ejecutar el script `create-alertas-table.sql` en MySQL Workbench

### PDF/CSV no se descargan en Flutter

- Verificar permisos de almacenamiento en Android/iOS
- Verificar que `path_provider` y `open_file` estén instalados

### Alertas no se reciben

- Verificar que Socket.IO esté conectado (`socketService.isConnected`)
- Verificar que el usuario tenga los roles correctos
- Revisar logs del backend para errores de Socket.IO

---

**Documentación creada el:** 2024-01-15  
**Versión:** 1.0.0

