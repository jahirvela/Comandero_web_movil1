# 📚 Documentación Técnica Completa - Proyecto Comandero

## 📋 Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Stack Tecnológico](#stack-tecnológico)
4. [Base de Datos](#base-de-datos)
5. [Backend](#backend)
6. [Frontend](#frontend)
7. [Comunicación en Tiempo Real (Socket.IO)](#comunicación-en-tiempo-real-socketio)
8. [Roles y Permisos](#roles-y-permisos)
9. [Funcionalidades Principales](#funcionalidades-principales)
10. [Seguridad](#seguridad)
11. [Despliegue y Producción](#despliegue-y-producción)
12. [Consideraciones Futuras](#consideraciones-futuras)
13. [Problemas Conocidos y Soluciones](#problemas-conocidos-y-soluciones)

---

## 🎯 Resumen Ejecutivo

**Comandero** es un sistema de gestión de restaurante completo desarrollado con Flutter (móvil/tablet) y Node.js/Express (backend). El sistema permite gestionar órdenes, mesas, pagos, inventario, reportes y más, con sincronización en tiempo real entre múltiples roles de usuario.

### Características Principales
- ✅ Sistema multi-rol (Administrador, Mesero, Cocinero, Cajero, Capitán)
- ✅ Sincronización en tiempo real con Socket.IO
- ✅ Gestión completa de órdenes y mesas
- ✅ Sistema de pagos y cierres de caja
- ✅ Inventario y reportes
- ✅ Impresión de tickets
- ✅ Interfaz responsive para móvil y tablet

---

## 🏗️ Arquitectura del Sistema

### Arquitectura General

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENTE (Flutter)                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Admin    │  │ Mesero   │  │ Cocinero │  │ Cajero   │   │
│  │ App      │  │ App      │  │ App      │  │ App      │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│       │              │              │              │          │
│       └──────────────┼──────────────┼──────────────┘          │
│                      │              │                         │
│              ┌───────▼──────────────▼───────┐                │
│              │   Socket.IO (Tiempo Real)     │                │
│              └───────┬──────────────┬───────┘                │
└──────────────────────┼──────────────┼───────────────────────┘
                       │              │
              ┌────────▼──────────────▼────────┐
              │      BACKEND (Node.js/Express)  │
              │  ┌──────────────────────────┐  │
              │  │   API REST (HTTP/HTTPS)  │  │
              │  └──────────────────────────┘  │
              │  ┌──────────────────────────┐  │
              │  │   Socket.IO Server       │  │
              │  └──────────────────────────┘  │
              └────────┬───────────────────────┘
                       │
              ┌────────▼────────┐
              │  MySQL Database │
              └─────────────────┘
```

### Patrón de Arquitectura

El proyecto sigue una **arquitectura en capas (Layered Architecture)**:

1. **Capa de Presentación (Frontend)**: Flutter con Provider para gestión de estado
2. **Capa de Aplicación (Backend)**: Express.js con controladores, servicios y repositorios
3. **Capa de Datos**: MySQL con repositorios que abstraen el acceso a datos

---

## 💻 Stack Tecnológico

### Frontend (Flutter)

#### Framework y Lenguaje
- **Flutter SDK**: ^3.9.0
- **Dart**: Lenguaje de programación
- **Plataformas**: Android, iOS, Web, Windows, macOS, Linux

#### Dependencias Principales

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `provider` | ^6.1.5+1 | Gestión de estado (State Management) |
| `go_router` | ^16.3.0 | Navegación y routing |
| `dio` | ^5.4.3+1 | Cliente HTTP para API REST |
| `socket_io_client` | ^2.0.3+1 | Cliente Socket.IO para tiempo real |
| `flutter_secure_storage` | ^9.2.4 | Almacenamiento seguro de tokens |
| `google_fonts` | ^6.3.2 | Fuentes personalizadas |
| `syncfusion_flutter_charts` | ^31.2.4 | Gráficos y visualizaciones |
| `intl` | ^0.20.2 | Internacionalización y formatos |
| `fluttertoast` | ^9.0.0 | Notificaciones toast |
| `path_provider` | ^2.1.4 | Acceso a rutas del sistema |
| `open_file` | ^3.5.0 | Abrir archivos del sistema |
| `share_plus` | ^10.1.2 | Compartir contenido |

#### ¿Por qué Flutter?

1. **Multiplataforma**: Un solo código base para Android, iOS, Web y Desktop
2. **Rendimiento**: Compilación nativa (AOT) para mejor rendimiento
3. **Hot Reload**: Desarrollo rápido con recarga instantánea
4. **Widgets**: Sistema de widgets rico y personalizable
5. **Comunidad**: Gran ecosistema de paquetes y documentación

### Backend (Node.js/Express)

#### Runtime y Framework
- **Node.js**: >=20.0.0
- **Express.js**: ^4.19.2
- **TypeScript**: ^5.9.3

#### Dependencias Principales

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `express` | ^4.19.2 | Framework web |
| `socket.io` | ^4.7.5 | Servidor WebSocket para tiempo real |
| `mysql2` | ^3.11.3 | Driver MySQL |
| `jsonwebtoken` | ^9.0.2 | Autenticación JWT |
| `bcrypt` | ^5.1.1 | Hash de contraseñas |
| `cors` | ^2.8.5 | Configuración CORS |
| `helmet` | ^7.1.0 | Seguridad HTTP headers |
| `express-rate-limit` | ^7.1.5 | Rate limiting |
| `pino` | ^9.14.0 | Logging estructurado |
| `zod` | ^3.23.8 | Validación de esquemas |
| `pdfkit` | ^0.17.2 | Generación de PDFs |
| `json2csv` | ^6.0.0-alpha.2 | Exportación a CSV |
| `escpos` | ^3.0.0-alpha.6 | Impresión de tickets |

#### ¿Por qué Node.js/Express?

1. **JavaScript/TypeScript**: Mismo lenguaje en frontend y backend (opcional)
2. **Rendimiento**: Event loop asíncrono ideal para I/O intensivo
3. **Ecosistema**: Gran cantidad de paquetes NPM
4. **Socket.IO**: Integración nativa para tiempo real
5. **Desarrollo rápido**: Prototipado y desarrollo ágil

### Base de Datos

- **MySQL**: 8.0+
- **Motor**: InnoDB (transaccional, ACID)
- **Charset**: utf8mb4 (soporte completo Unicode)

#### ¿Por qué MySQL?

1. **Madurez**: Base de datos probada y estable
2. **ACID**: Transacciones confiables para operaciones críticas
3. **Rendimiento**: Optimizado para lecturas y escrituras
4. **Herramientas**: Amplio soporte de herramientas y administración
5. **Escalabilidad**: Soporte para grandes volúmenes de datos

---

## 🗄️ Base de Datos

### Estructura de Tablas Principales

#### 1. Autenticación y Usuarios

```sql
usuario
├── id (BIGINT UNSIGNED, PK)
├── username (VARCHAR(80), UNIQUE)
├── password_hash (VARCHAR(255))
├── email (VARCHAR(255))
├── nombre_completo (VARCHAR(160))
├── activo (TINYINT(1))
└── timestamps

rol
├── id (BIGINT UNSIGNED, PK)
├── nombre (VARCHAR(80), UNIQUE)
└── descripcion (VARCHAR(255))

usuario_rol
├── usuario_id (FK → usuario.id)
├── rol_id (FK → rol.id)
└── PRIMARY KEY (usuario_id, rol_id)

permiso
├── id (BIGINT UNSIGNED, PK)
├── nombre (VARCHAR(120), UNIQUE)
└── descripcion (VARCHAR(255))

rol_permiso
├── rol_id (FK → rol.id)
├── permiso_id (FK → permiso.id)
└── PRIMARY KEY (rol_id, permiso_id)
```

#### 2. Mesas y Reservas

```sql
mesa
├── id (BIGINT UNSIGNED, PK)
├── codigo (VARCHAR(20), UNIQUE)
├── capacidad (INT)
├── estado_mesa_id (FK → estado_mesa.id)
├── categoria_id (FK → categoria.id) -- Área/Sección
├── activo (TINYINT(1))
└── timestamps

reserva
├── id (BIGINT UNSIGNED, PK)
├── mesa_id (FK → mesa.id)
├── cliente_id (FK → cliente.id)
├── fecha_reserva (DATE)
├── hora_reserva (TIME)
└── timestamps
```

#### 3. Productos y Categorías

```sql
categoria
├── id (BIGINT UNSIGNED, PK)
├── nombre (VARCHAR(120), UNIQUE)
├── descripcion (VARCHAR(255))
├── activo (TINYINT(1))
└── timestamps

producto
├── id (BIGINT UNSIGNED, PK)
├── categoria_id (FK → categoria.id)
├── nombre (VARCHAR(160))
├── descripcion (TEXT)
├── precio (DECIMAL(10,2))
├── disponible (TINYINT(1))
├── sku (VARCHAR(64))
├── inventariable (TINYINT(1))
└── timestamps

producto_tamano
├── id (BIGINT UNSIGNED, PK)
├── producto_id (FK → producto.id)
├── nombre (VARCHAR(80))
├── precio_adicional (DECIMAL(10,2))
└── timestamps

producto_insumo
├── id (BIGINT UNSIGNED, PK)
├── producto_id (FK → producto.id)
├── inventario_item_id (FK → inventario_item.id)
├── cantidad (DECIMAL(12,3))
└── timestamps
```

#### 4. Órdenes

```sql
orden
├── id (BIGINT UNSIGNED, PK)
├── mesa_id (FK → mesa.id, NULLABLE) -- NULL para "para llevar"
├── estado_orden_id (FK → estado_orden.id)
├── cliente_nombre (VARCHAR(160)) -- Para "para llevar"
├── cliente_telefono (VARCHAR(20))
├── subtotal (DECIMAL(10,2))
├── descuento_total (DECIMAL(10,2))
├── impuesto_total (DECIMAL(10,2))
├── propina_sugerida (DECIMAL(10,2))
├── total (DECIMAL(10,2))
├── notas (TEXT)
├── split_count (INT) -- División de cuenta
└── timestamps

orden_item
├── id (BIGINT UNSIGNED, PK)
├── orden_id (FK → orden.id)
├── producto_id (FK → producto.id)
├── cantidad (INT)
├── precio_unitario (DECIMAL(10,2))
├── subtotal (DECIMAL(10,2))
├── notas (TEXT)
└── timestamps

orden_item_modificador
├── orden_item_id (FK → orden_item.id)
├── modificador_opcion_id (FK → modificador_opcion.id)
└── PRIMARY KEY (orden_item_id, modificador_opcion_id)
```

#### 5. Pagos y Caja

```sql
pago
├── id (BIGINT UNSIGNED, PK)
├── orden_id (FK → orden.id)
├── forma_pago_id (FK → forma_pago.id)
├── monto (DECIMAL(10,2))
├── propina (DECIMAL(10,2))
├── propina_entregada (TINYINT(1))
├── fecha_pago (DATETIME)
└── timestamps

caja_cierre
├── id (BIGINT UNSIGNED, PK)
├── fecha (DATE)
├── apertura (TIMESTAMP)
├── cierre (TIMESTAMP)
├── monto_apertura (DECIMAL(10,2))
├── monto_cierre (DECIMAL(10,2))
├── total_ventas (DECIMAL(10,2))
├── total_efectivo (DECIMAL(10,2))
├── total_tarjeta (DECIMAL(10,2))
├── total_propinas (DECIMAL(10,2))
├── notas (TEXT)
├── usuario_id (FK → usuario.id)
└── timestamps
```

#### 6. Inventario

```sql
inventario_item
├── id (BIGINT UNSIGNED, PK)
├── nombre (VARCHAR(160), UNIQUE)
├── unidad (VARCHAR(32))
├── cantidad_actual (DECIMAL(12,3))
├── stock_minimo (DECIMAL(12,3))
├── costo_unitario (DECIMAL(12,4))
├── categoria (VARCHAR(80)) -- Categoría de inventario
├── activo (TINYINT(1))
└── timestamps

movimiento_inventario
├── id (BIGINT UNSIGNED, PK)
├── inventario_item_id (FK → inventario_item.id)
├── tipo (ENUM: 'entrada', 'salida', 'ajuste')
├── cantidad (DECIMAL(12,3))
├── motivo (VARCHAR(255))
├── orden_id (FK → orden.id, NULLABLE)
└── timestamps
```

#### 7. Alertas

```sql
alerta
├── id (BIGINT UNSIGNED, PK)
├── tipo (VARCHAR(50))
├── mensaje (TEXT)
├── orden_id (BIGINT UNSIGNED, NULLABLE)
├── mesa_id (BIGINT UNSIGNED, NULLABLE)
├── prioridad (VARCHAR(20))
├── leida (TINYINT(1))
├── usuario_id (FK → usuario.id)
├── emisor_id (FK → usuario.id)
└── timestamps
```

### Índices y Optimizaciones

- **Índices primarios**: Todas las tablas tienen `id` como PRIMARY KEY
- **Índices únicos**: `username`, `codigo` (mesa), `nombre` (categorías, productos)
- **Índices foráneos**: Todas las relaciones FK tienen índices para JOINs rápidos
- **Índices compuestos**: `(categoria_id, nombre)` en productos, `(usuario_id, rol_id)` en usuario_rol

### Relaciones Principales

```
usuario ──┬── usuario_rol ── rol ── rol_permiso ── permiso
          │
          ├── orden (creado_por)
          ├── pago
          └── caja_cierre

mesa ──┬── orden
       └── reserva

categoria ── producto ──┬── producto_tamano
                        ├── producto_insumo ── inventario_item
                        └── orden_item

orden ──┬── orden_item ── orden_item_modificador
        ├── pago
        └── movimiento_inventario
```

---

## 🔧 Backend

### Estructura de Directorios

```
backend/src/
├── auth/              # Autenticación y autorización
│   ├── auth.controller.ts
│   ├── auth.routes.ts
│   ├── auth.service.ts
│   ├── auth.middleware.ts
│   └── jwt.utils.ts
├── config/            # Configuración
│   ├── database.ts    # Conexión MySQL
│   ├── cors.ts        # Configuración CORS
│   ├── env.ts         # Variables de entorno
│   ├── logger.ts      # Configuración Pino
│   ├── rate-limit.ts  # Rate limiting
│   └── swagger.ts     # Documentación API
├── middlewares/       # Middlewares Express
│   ├── error-handler.ts
│   ├── not-found.ts
│   └── validate-request.ts
├── modules/           # Módulos de negocio
│   ├── alertas/
│   ├── categorias/
│   ├── cierres/
│   ├── inventario/
│   ├── mesas/
│   ├── ordenes/
│   ├── pagos/
│   ├── productos/
│   ├── reportes/
│   ├── reservas/
│   ├── roles/
│   ├── tickets/
│   └── usuarios/
├── realtime/          # Socket.IO
│   ├── socket.ts      # Configuración Socket.IO
│   └── events.ts      # Eventos emitidos
├── routes/            # Rutas principales
│   └── index.ts
├── types/             # Tipos TypeScript
│   ├── ordenes.ts
│   └── usuarios.ts
├── utils/             # Utilidades
│   ├── http-error.ts
│   └── date-utils.ts
└── server.ts          # Punto de entrada
```

### Patrón de Diseño: Repository Pattern

Cada módulo sigue el patrón Repository:

```
Controller → Service → Repository → Database
```

**Ejemplo: Módulo de Órdenes**

```typescript
// ordenes.controller.ts
export const crearOrden = async (req, res, next) => {
  const orden = await ordenesService.crearOrden(data);
  res.status(201).json({ data: orden });
};

// ordenes.service.ts
export const crearOrden = async (input: CrearOrdenInput) => {
  const orden = await ordenesRepository.crear(input);
  await emitOrderCreated(orden); // Socket.IO
  return orden;
};

// ordenes.repository.ts
export const crear = async (input: CrearOrdenInput) => {
  const [result] = await db.execute(
    'INSERT INTO orden (...) VALUES (...)',
    [values]
  );
  return await obtenerPorId(result.insertId);
};
```

### API REST Endpoints

#### Autenticación
- `POST /api/auth/login` - Iniciar sesión
- `POST /api/auth/logout` - Cerrar sesión
- `GET /api/auth/profile` - Obtener perfil

#### Usuarios
- `GET /api/usuarios` - Listar usuarios
- `POST /api/usuarios` - Crear usuario
- `PUT /api/usuarios/:id` - Actualizar usuario
- `DELETE /api/usuarios/:id` - Eliminar usuario
- `POST /api/usuarios/:id/cambiar-password` - Cambiar contraseña

#### Mesas
- `GET /api/mesas` - Listar mesas
- `POST /api/mesas` - Crear mesa
- `PUT /api/mesas/:id` - Actualizar mesa
- `DELETE /api/mesas/:id` - Eliminar mesa
- `PATCH /api/mesas/:id/estado` - Cambiar estado

#### Órdenes
- `GET /api/ordenes` - Listar órdenes
- `GET /api/ordenes/:id` - Obtener orden
- `POST /api/ordenes` - Crear orden
- `PUT /api/ordenes/:id` - Actualizar orden
- `PATCH /api/ordenes/:id/estado` - Cambiar estado
- `POST /api/ordenes/:id/items` - Agregar items
- `DELETE /api/ordenes/:id` - Cancelar orden

#### Productos
- `GET /api/productos` - Listar productos
- `POST /api/productos` - Crear producto
- `PUT /api/productos/:id` - Actualizar producto
- `DELETE /api/productos/:id` - Eliminar producto

#### Pagos
- `GET /api/pagos` - Listar pagos
- `POST /api/pagos` - Crear pago
- `GET /api/pagos/:id` - Obtener pago

#### Cierres de Caja
- `GET /api/cierres` - Listar cierres
- `POST /api/cierres` - Crear cierre
- `GET /api/cierres/:id` - Obtener cierre

#### Reportes
- `GET /api/reportes/ventas` - Reporte de ventas
- `GET /api/reportes/productos` - Reporte de productos
- `GET /api/reportes/exportar` - Exportar reporte

### Seguridad Backend

1. **JWT Authentication**: Tokens firmados con expiración
2. **bcrypt**: Hash de contraseñas (10 rounds)
3. **Helmet**: Headers de seguridad HTTP
4. **CORS**: Configuración restrictiva por origen
5. **Rate Limiting**: 100 requests/minuto por IP
6. **Validación**: Zod schemas para validar inputs
7. **SQL Injection**: Prepared statements (mysql2)

---

## 📱 Frontend

### Estructura de Directorios

```
lib/
├── controllers/       # State Management (Provider)
│   ├── admin_controller.dart
│   ├── auth_controller.dart
│   ├── cajero_controller.dart
│   ├── captain_controller.dart
│   ├── cocinero_controller.dart
│   ├── mesero_controller.dart
│   └── app_controller.dart
├── services/          # Servicios API y Socket
│   ├── api_service.dart
│   ├── socket_service.dart
│   ├── auth_service.dart
│   ├── mesas_service.dart
│   ├── ordenes_service.dart
│   ├── productos_service.dart
│   └── ...
├── models/            # Modelos de datos
│   ├── table_model.dart
│   ├── product_model.dart
│   ├── payment_model.dart
│   └── ...
├── views/             # Pantallas/Vistas
│   ├── admin/
│   ├── mesero/
│   ├── cocinero/
│   ├── cajero/
│   └── captain/
├── utils/             # Utilidades
│   ├── date_utils.dart
│   └── app_colors.dart
└── main.dart          # Punto de entrada
```

### Gestión de Estado: Provider Pattern

```dart
// Ejemplo: MeseroController
class MeseroController extends ChangeNotifier {
  List<TableModel> _tables = [];
  TableModel? _selectedTable;
  Map<String, List<CartItem>> _tableOrders = {};
  
  // Getters
  List<TableModel> get tables => _tables;
  TableModel? get selectedTable => _selectedTable;
  
  // Métodos
  Future<void> loadTables() async {
    _tables = await _mesasService.getMesas();
    notifyListeners(); // Notifica cambios a la UI
  }
  
  void selectTable(TableModel table) {
    _selectedTable = table;
    notifyListeners();
  }
}
```

### Navegación: GoRouter

```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    GoRoute(
      path: '/mesero',
      builder: (context, state) => MeseroApp(),
    ),
    // ...
  ],
);
```

### Servicios API

```dart
// api_service.dart
class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000/api',
    headers: {'Content-Type': 'application/json'},
  ));
  
  Future<Response> get(String path) async {
    final token = await _storage.read(key: 'accessToken');
    _dio.options.headers['Authorization'] = 'Bearer $token';
    return await _dio.get(path);
  }
}
```

---

## 🔌 Comunicación en Tiempo Real (Socket.IO)

### ¿Por qué Socket.IO?

Socket.IO fue elegido por las siguientes razones:

1. **Tiempo Real**: Actualizaciones instantáneas entre clientes
2. **Fallback Automático**: Si WebSocket falla, usa polling HTTP
3. **Rooms y Namespaces**: Organización por roles y salas
4. **Reconexión Automática**: Maneja desconexiones de red
5. **Ecosistema Maduro**: Ampliamente usado y documentado
6. **Compatible con Móvil**: Funciona bien en redes móviles inestables

### Configuración Socket.IO

#### Backend

```typescript
// server.ts
export const io = new SocketServer(httpServer, {
  cors: {
    origin: env.CORS_ORIGIN,
    methods: ['GET', 'POST'],
    credentials: true
  },
  pingTimeout: 60000,      // 60s para móvil
  pingInterval: 25000,      // 25s
  transports: ['websocket', 'polling'], // Fallback
  connectTimeout: 45000,    // 45s
});
```

#### Frontend

```dart
// socket_service.dart
class SocketService {
  IO.Socket? _socket;
  
  Future<void> connect() async {
    final token = await _storage.read(key: 'accessToken');
    _socket = IO.io(
      'http://localhost:3000',
      IO.OptionBuilder()
        .setAuth({'token': token})
        .enableAutoConnect()
        .enableReconnection()
        .build(),
    );
  }
}
```

### Eventos Socket.IO Implementados

#### Eventos del Backend → Frontend

| Evento | Descripción | Destinatarios |
|--------|-------------|---------------|
| `pedido.creado` | Nueva orden creada | Cocinero, Mesero, Admin |
| `pedido.actualizado` | Orden actualizada | Todos los roles |
| `pedido.cancelado` | Orden cancelada | Cocinero, Mesero |
| `mesa.actualizada` | Mesa actualizada | Mesero, Capitán, Admin |
| `mesa.eliminada` | Mesa eliminada | Mesero, Capitán, Admin |
| `cuenta.enviada` | Cuenta enviada al cajero | Cajero, Admin |
| `alerta.cocina` | Alerta de cocina | Cocinero |
| `alerta.mesa` | Alerta de mesa | Mesero, Capitán |
| `alerta.pago` | Alerta de pago | Cajero, Admin |
| `pago.creado` | Pago procesado | Cajero, Admin |

#### Eventos del Frontend → Backend

| Evento | Descripción | Emisor |
|--------|-------------|--------|
| `cocina.alerta` | Enviar alerta a cocina | Mesero, Capitán |
| `join` | Unirse a una sala | Todos |
| `leave` | Salir de una sala | Todos |

### Rooms y Namespaces

```typescript
// Backend: Organización por roles
io.to('role:mesero').emit('mesa.actualizada', mesa);
io.to('role:cocinero').emit('pedido.creado', orden);
io.to('role:administrador').emit('pago.creado', pago);
```

### ¿Socket.IO dará problemas en producción?

#### ✅ Ventajas para Producción

1. **Escalabilidad**: Socket.IO soporta múltiples servidores con Redis adapter
2. **Reconexión**: Maneja automáticamente cortes de red
3. **Fallback**: Si WebSocket falla, usa polling HTTP
4. **Optimización**: Comprime mensajes automáticamente
5. **Monitoreo**: Herramientas de monitoreo disponibles

#### ⚠️ Consideraciones

1. **Recursos del Servidor**: Cada conexión consume memoria
   - **Solución**: Implementar desconexión automática por inactividad
   - **Solución**: Usar Redis adapter para múltiples servidores

2. **Firewalls y Proxies**: Algunos firewalls bloquean WebSocket
   - **Solución**: Socket.IO usa polling como fallback automático
   - **Solución**: Configurar proxy reverso (Nginx) correctamente

3. **Latencia en Redes Móviles**: Redes móviles pueden tener alta latencia
   - **Solución**: Timeouts configurados (60s pingTimeout)
   - **Solución**: Reconexión automática implementada

4. **Escalabilidad Horizontal**: Múltiples instancias del servidor
   - **Solución**: Usar Redis adapter para compartir conexiones
   - **Solución**: Load balancer con sticky sessions

#### 🚀 Recomendaciones para Producción

```typescript
// Configuración recomendada para producción
const io = new SocketServer(httpServer, {
  adapter: createAdapter(redisClient), // Redis adapter
  pingTimeout: 60000,
  pingInterval: 25000,
  maxHttpBufferSize: 1e6, // 1MB
  allowEIO3: true,
  transports: ['websocket', 'polling'],
});
```

---

## 👥 Roles y Permisos

### Roles del Sistema

1. **Administrador**
   - Gestión completa de usuarios
   - Gestión de mesas y áreas
   - Gestión de productos y categorías
   - Ver todos los tickets y reportes
   - Ver contraseñas de usuarios (solo admin)
   - Cierres de caja

2. **Mesero**
   - Ver mesas y su estado
   - Crear órdenes
   - Enviar órdenes a cocina
   - Ver historial de órdenes
   - Enviar cuentas al cajero
   - Recibir notificaciones de cocina

3. **Cocinero**
   - Ver órdenes pendientes
   - Cambiar estado de órdenes (en preparación, listo)
   - Ver alertas de cocina
   - Marcar órdenes como completadas

4. **Cajero**
   - Ver cuentas enviadas
   - Procesar pagos (efectivo, tarjeta)
   - Ver historial de pagos
   - Realizar cierres de caja
   - Ver reportes de ventas

5. **Capitán**
   - Ver todas las mesas
   - Ver órdenes activas
   - Recibir alertas de demora
   - Supervisar operaciones

### Sistema de Permisos

```sql
-- Estructura de permisos
rol → rol_permiso → permiso
usuario → usuario_rol → rol
```

**Ejemplo de Permisos:**
- `ordenes.crear`
- `ordenes.actualizar`
- `ordenes.cancelar`
- `pagos.procesar`
- `usuarios.crear`
- `usuarios.eliminar`
- `reportes.ver`

---

## 🎯 Funcionalidades Principales

### 1. Gestión de Mesas

- ✅ Crear, editar, eliminar mesas
- ✅ Asignar mesas a áreas/categorías
- ✅ Cambiar estado de mesas (Libre, Ocupada, Reservada, En Limpieza)
- ✅ Ver mesas en tiempo real
- ✅ Filtrar por área

### 2. Gestión de Órdenes

- ✅ Crear órdenes desde mesero
- ✅ Órdenes para llevar (sin mesa)
- ✅ Agregar productos con modificadores
- ✅ Aplicar descuentos
- ✅ División de cuenta (split)
- ✅ Propina sugerida
- ✅ Notas del pedido
- ✅ Enviar a cocina
- ✅ Actualizar estado (preparación, listo)
- ✅ Cancelar órdenes

### 3. Gestión de Productos

- ✅ CRUD completo de productos
- ✅ Categorías de productos
- ✅ Tamaños y precios
- ✅ Modificadores (extras, opciones)
- ✅ Relación con inventario
- ✅ Disponibilidad

### 4. Sistema de Pagos

- ✅ Pagos en efectivo
- ✅ Pagos con tarjeta
- ✅ Propinas
- ✅ División de pagos
- ✅ Historial de pagos
- ✅ Tickets de pago

### 5. Cierres de Caja

- ✅ Apertura de caja
- ✅ Cierre de caja
- ✅ Cálculo automático de totales
- ✅ Reportes de cierre
- ✅ Historial de cierres

### 6. Inventario

- ✅ Gestión de items de inventario
- ✅ Movimientos de inventario
- ✅ Consumo automático al marcar orden como "listo"
- ✅ Alertas de stock bajo
- ✅ Categorías de inventario

### 7. Reportes

- ✅ Reporte de ventas
- ✅ Reporte de productos más vendidos
- ✅ Reporte de cierres de caja
- ✅ Exportación a PDF y CSV

### 8. Notificaciones en Tiempo Real

- ✅ Notificaciones de órdenes listas
- ✅ Notificaciones de órdenes en preparación
- ✅ Alertas de cocina
- ✅ Alertas de mesas
- ✅ Persistencia de notificaciones limpiadas

---

## 🔒 Seguridad

### Autenticación

- **JWT Tokens**: Tokens firmados con expiración (24 horas)
- **Refresh Tokens**: (Opcional, no implementado aún)
- **Almacenamiento Seguro**: `flutter_secure_storage` para tokens

### Autorización

- **Middleware de Autenticación**: Verifica token en cada request
- **Middleware de Autorización**: Verifica permisos por rol
- **Validación de Roles**: Backend valida roles antes de operaciones

### Protección de Datos

- **Contraseñas**: Hash con bcrypt (10 rounds)
- **SQL Injection**: Prepared statements
- **XSS**: Sanitización de inputs
- **CORS**: Configuración restrictiva
- **Rate Limiting**: 100 requests/minuto

### Vulnerabilidades Corregidas

1. ✅ **SQL Injection**: Uso de prepared statements
2. ✅ **XSS**: Sanitización de inputs
3. ✅ **CSRF**: Tokens JWT
4. ✅ **Brute Force**: Rate limiting
5. ✅ **Exposición de Contraseñas**: Solo admin puede ver contraseñas (requerimiento)

---

## 🚀 Despliegue y Producción

### Requisitos del Servidor

- **Node.js**: >=20.0.0
- **MySQL**: 8.0+
- **RAM**: Mínimo 2GB (recomendado 4GB+)
- **CPU**: 2+ cores
- **Disco**: 10GB+ (depende de datos)

### Variables de Entorno

```env
# Backend
NODE_ENV=production
PORT=3000
DB_HOST=localhost
DB_USER=comandero_user
DB_PASSWORD=secure_password
DB_NAME=comandero
JWT_SECRET=your_secret_key
CORS_ORIGIN=https://yourdomain.com

# Frontend
API_BASE_URL=https://api.yourdomain.com
SOCKET_URL=https://api.yourdomain.com
```

### Proceso de Despliegue

1. **Base de Datos**
   ```bash
   mysql -u root -p < scripts/migracion-completa-bd.sql
   ```

2. **Backend**
   ```bash
   cd backend
   npm install
   npm run build
   pm2 start ecosystem.config.js
   ```

3. **Frontend**
   ```bash
   flutter build apk --release  # Android
   flutter build ios --release  # iOS
   flutter build web --release  # Web
   ```

### Monitoreo

- **PM2**: Gestión de procesos Node.js
- **Logs**: Pino logger con rotación
- **Health Checks**: Endpoint `/health`

### Backups

- **Automáticos**: Scripts de backup diarios
- **Manuales**: Comando `npm run backup:database`
- **Restauración**: Comando `npm run restore:backup`

---

## 🔮 Consideraciones Futuras

### Mejoras Sugeridas

1. **Performance**
   - [ ] Implementar caché Redis para consultas frecuentes
   - [ ] Optimizar queries SQL con índices adicionales
   - [ ] Implementar paginación en listas grandes
   - [ ] Lazy loading de imágenes

2. **Funcionalidades**
   - [ ] Sistema de reservas completo
   - [ ] Integración con sistemas de pago (Stripe, PayPal)
   - [ ] App para clientes (ver menú, hacer pedidos)
   - [ ] Sistema de puntos/fidelidad
   - [ ] Integración con delivery (Uber Eats, etc.)

3. **Tecnología**
   - [ ] Migrar a Flutter 3.x (si hay nueva versión)
   - [ ] Implementar GraphQL como alternativa a REST
   - [ ] Microservicios para escalabilidad
   - [ ] Docker containers para despliegue

4. **Seguridad**
   - [ ] Implementar refresh tokens
   - [ ] 2FA (autenticación de dos factores)
   - [ ] Auditoría de acciones (logs de cambios)
   - [ ] Encriptación de datos sensibles

5. **UX/UI**
   - [ ] Modo oscuro
   - [ ] Personalización de temas
   - [ ] Animaciones mejoradas
   - [ ] Accesibilidad (a11y)

---

## ⚠️ Problemas Conocidos y Soluciones

### 1. Historial de Órdenes Desaparece

**Problema**: El historial de órdenes desaparece después de logout/login.

**Solución Implementada**:
- Persistencia en `FlutterSecureStorage`
- Filtrado correcto de órdenes pagadas
- Verificación de estado en backend antes de mostrar

**Estado**: ✅ Resuelto

### 2. Notificaciones Reaparecen

**Problema**: Notificaciones limpiadas reaparecen después de recargar.

**Solución Implementada**:
- Persistencia de notificaciones limpiadas en storage
- Verificación antes de agregar nuevas notificaciones

**Estado**: ✅ Resuelto

### 3. Estado "En Limpieza" se Revierte

**Problema**: El estado "En Limpieza" se revertía a "Libre" después de unos segundos.

**Solución Implementada**:
- Mapeo robusto de estados en backend
- Actualización optimista en frontend
- Verificación de estado real en backend

**Estado**: ✅ Resuelto

### 4. Socket.IO Desconexiones en Móvil

**Problema**: Conexiones Socket.IO se desconectan en redes móviles inestables.

**Solución Implementada**:
- Timeouts más largos (60s pingTimeout)
- Reconexión automática
- Fallback a polling HTTP

**Estado**: ✅ Resuelto

### 5. Zona Horaria Incorrecta

**Problema**: Fechas y horas no se mostraban en la zona horaria correcta.

**Solución Implementada**:
- Utilidad `AppDateUtils` para conversión de zonas horarias
- Backend almacena en UTC
- Frontend convierte a zona horaria local

**Estado**: ✅ Resuelto

---

## 📊 Métricas y Estadísticas

### Código

- **Backend**: ~15,000 líneas de código TypeScript
- **Frontend**: ~25,000 líneas de código Dart
- **Base de Datos**: 20+ tablas
- **API Endpoints**: 50+ endpoints REST
- **Eventos Socket.IO**: 15+ eventos

### Funcionalidades

- **Roles**: 5 roles implementados
- **Módulos**: 12 módulos principales
- **Pantallas**: 30+ pantallas Flutter
- **Servicios**: 19 servicios frontend

---

## 📝 Conclusión

El proyecto **Comandero** es un sistema completo de gestión de restaurante con las siguientes características destacadas:

✅ **Arquitectura sólida**: Separación de responsabilidades, código mantenible
✅ **Tiempo real**: Sincronización instantánea entre roles
✅ **Seguridad**: Autenticación, autorización, protección de datos
✅ **Escalabilidad**: Preparado para crecimiento
✅ **Multiplataforma**: Funciona en móvil, tablet y web
✅ **Producción-ready**: Listo para despliegue con las configuraciones adecuadas

### Tecnologías Clave

- **Flutter**: Frontend multiplataforma
- **Node.js/Express**: Backend robusto
- **MySQL**: Base de datos relacional
- **Socket.IO**: Comunicación en tiempo real
- **JWT**: Autenticación segura

### Próximos Pasos Recomendados

1. Implementar pruebas automatizadas (unitarias e integración)
2. Configurar CI/CD para despliegue automático
3. Implementar monitoreo y alertas (Sentry, DataDog)
4. Optimizar performance con caché Redis
5. Documentar API con Swagger/OpenAPI

---

**Documentación generada el**: 2025-01-XX
**Versión del Proyecto**: 1.0.0
**Última actualización**: 2025-01-XX

