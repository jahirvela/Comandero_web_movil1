# 📱 Resumen Completo del Proyecto Comandix

## 🎯 ¿Qué es Comandix?

Comandix es un sistema completo de gestión para restaurantes que permite:
- **Gestionar mesas y órdenes** desde tablets
- **Controlar la cocina** en tiempo real
- **Procesar pagos** en caja
- **Administrar inventario** y productos
- **Generar reportes** de ventas y operaciones
- **Imprimir tickets** térmicos
- **Funcionar con Internet móvil** (módem 4G)

---

## 🏗️ Arquitectura del Sistema

### Backend (Servidor)
- **Lenguaje:** TypeScript (Node.js)
- **Base de datos:** MySQL 8
- **API:** REST con Express
- **Tiempo real:** Socket.IO
- **Seguridad:** JWT, bcrypt, rate limiting
- **Documentación:** Swagger UI

### Frontend (Aplicación Móvil)
- **Lenguaje:** Dart (Flutter)
- **Plataformas:** Android, iOS, Web
- **Estado:** Provider
- **Navegación:** GoRouter
- **Comunicación:** Dio (HTTP) + Socket.IO Client

### Infraestructura
- **Desarrollo:** Local (localhost)
- **Producción:** VPS remoto + Módem 4G en el puesto

---

## 📦 Lo que se ha Construido

### 1. 🔐 Sistema de Autenticación

**¿Qué hace?**
Permite que los usuarios (meseros, cocineros, cajeros, administradores) inicien sesión de forma segura.

**Cómo funciona:**
- El usuario ingresa su nombre de usuario y contraseña
- El servidor verifica las credenciales
- Si son correctas, devuelve dos tokens:
  - **Access Token:** Válido por 30 minutos (para hacer peticiones)
  - **Refresh Token:** Válido por 7 días (para renovar el access token)
- La app guarda estos tokens de forma segura
- Cada petición incluye el token para identificarse

**Características técnicas:**
- Contraseñas encriptadas con bcrypt (12 rondas)
- Tokens JWT firmados con secretos diferentes
- Renovación automática de tokens cuando expiran
- Protección contra fuerza bruta (5 intentos por minuto)

**Archivos importantes:**
- `backend/src/auth/` - Lógica de autenticación
- `lib/services/auth_service.dart` - Cliente Flutter
- `lib/controllers/auth_controller.dart` - Estado de sesión

---

### 2. 👥 Gestión de Usuarios y Roles

**¿Qué hace?**
Permite crear y administrar usuarios del sistema, asignándoles roles (administrador, mesero, cocinero, cajero, capitán).

**Funcionalidades:**
- Crear nuevos usuarios
- Editar información de usuarios
- Asignar/quitar roles
- Activar/desactivar usuarios
- Listar todos los usuarios

**Cómo funciona:**
- Solo los administradores pueden gestionar usuarios
- Cada usuario puede tener múltiples roles
- Los roles determinan qué puede hacer cada usuario

**Archivos importantes:**
- `backend/src/modules/usuarios/` - CRUD de usuarios
- `backend/src/modules/roles/` - Gestión de roles

---

### 3. 🪑 Gestión de Mesas

**¿Qué hace?**
Permite administrar las mesas del restaurante: crear, editar, cambiar estado (libre, ocupada, reservada, sucia).

**Funcionalidades:**
- Ver todas las mesas con su estado actual
- Cambiar el estado de una mesa
- Ver historial de órdenes de una mesa
- Crear/editar mesas (solo admin/capitán)

**Estados de mesa:**
- **Libre:** Disponible para clientes
- **Ocupada:** Hay clientes sentados
- **Reservada:** Reservada para más tarde
- **Sucia:** Necesita limpieza

**Archivos importantes:**
- `backend/src/modules/mesas/` - Lógica de mesas
- `lib/services/mesas_service.dart` - Cliente Flutter

---

### 4. 🍽️ Catálogo de Productos

**¿Qué hace?**
Gestiona el menú del restaurante: categorías, productos, tamaños, precios.

**Estructura:**
- **Categorías:** Bebidas, Comidas, Postres, etc.
- **Productos:** Cada producto pertenece a una categoría
- **Tamaños:** Algunos productos tienen tamaños (chico, mediano, grande)
- **Modificadores:** Extras o personalizaciones (sin cebolla, extra queso, etc.)

**Funcionalidades:**
- Crear/editar categorías
- Crear/editar productos
- Asignar precios y tamaños
- Activar/desactivar productos

**Archivos importantes:**
- `backend/src/modules/categorias/` - Gestión de categorías
- `backend/src/modules/productos/` - Gestión de productos
- `lib/services/productos_service.dart` - Cliente Flutter

---

### 5. 📋 Sistema de Órdenes

**¿Qué hace?**
El corazón del sistema. Permite crear órdenes, agregar productos, cambiar estados, y todo se sincroniza en tiempo real.

**Flujo típico:**
1. Mesero crea una orden para una mesa
2. Agrega productos (con modificadores si aplica)
3. La orden aparece automáticamente en la cocina
4. Cocinero cambia el estado a "en preparación"
5. Cuando termina, cambia a "listo"
6. Mesero ve que está lista y la entrega
7. Cliente paga en caja
8. Orden se marca como "pagada"

**Estados de orden:**
- **Abierta:** Recién creada
- **En preparación:** Cocina está trabajando
- **Lista:** Lista para entregar
- **Entregada:** Ya se entregó al cliente
- **Pagada:** Cliente ya pagó
- **Cancelada:** Se canceló la orden

**Características técnicas:**
- Cálculo automático de totales (subtotal, descuentos, impuestos, propina)
- Sincronización en tiempo real con Socket.IO
- Historial completo de cambios

**Archivos importantes:**
- `backend/src/modules/ordenes/` - Lógica de órdenes
- `lib/services/ordenes_service.dart` - Cliente Flutter
- `backend/src/realtime/events.ts` - Eventos en tiempo real

---

### 6. 💰 Sistema de Pagos

**¿Qué hace?**
Registra los pagos de las órdenes, maneja diferentes formas de pago (efectivo, tarjeta, transferencia) y propinas.

**Funcionalidades:**
- Registrar pagos para órdenes
- Múltiples formas de pago
- Registrar propinas
- Ver historial de pagos
- Cálculo automático de totales

**Formas de pago:**
- Efectivo
- Tarjeta de débito
- Tarjeta de crédito
- Transferencia bancaria
- Otros

**Archivos importantes:**
- `backend/src/modules/pagos/` - Lógica de pagos
- `lib/services/pagos_service.dart` - Cliente Flutter

---

### 7. 📦 Gestión de Inventario

**¿Qué hace?**
Controla el inventario de insumos (ingredientes, productos, etc.) y registra movimientos (entradas, salidas, ajustes).

**Funcionalidades:**
- Crear/editar insumos
- Registrar movimientos de inventario
- Ver historial de movimientos
- Control de stock

**Tipos de movimientos:**
- **Entrada:** Se compró o recibió material
- **Salida:** Se usó material
- **Ajuste:** Corrección de inventario

**Archivos importantes:**
- `backend/src/modules/inventario/` - Lógica de inventario
- `lib/services/inventario_service.dart` - Cliente Flutter

---

### 8. ⚡ Tiempo Real (Socket.IO)

**¿Qué hace?**
Permite que todos los dispositivos vean los cambios instantáneamente sin necesidad de refrescar.

**Eventos en tiempo real:**
- **Pedido creado:** Cuando se crea una orden, aparece en cocina
- **Pedido actualizado:** Cambios en la orden se ven en todos lados
- **Pedido cancelado:** Se notifica a todos
- **Alertas:** Notificaciones importantes (demoras, cancelaciones, etc.)

**Cómo funciona:**
- Cada dispositivo se conecta al servidor con Socket.IO
- El servidor agrupa a los usuarios por rol (cocinero, mesero, etc.)
- Cuando algo cambia, el servidor envía el evento a los grupos relevantes
- La app recibe el evento y actualiza la pantalla automáticamente

**Características técnicas:**
- Reconexión automática si se pierde Internet
- Autenticación con JWT
- Agrupación por roles y estaciones
- Timeouts optimizados para Internet móvil

**Archivos importantes:**
- `backend/src/realtime/socket.ts` - Servidor Socket.IO
- `backend/src/realtime/events.ts` - Eventos
- `lib/services/socket_service.dart` - Cliente Flutter

---

### 9. 🖨️ Impresión de Tickets

**¿Qué hace?**
Imprime tickets térmicos (como los de los cajeros) con la información de la orden.

**Características:**
- Formato POS-80/ESC-POS (estándar de impresoras térmicas)
- Incluye: encabezado del restaurante, productos, totales, método de pago
- Soporte para impresoras USB, TCP/IP (red), y modo simulación (para desarrollo)

**Modo simulación:**
- En desarrollo, guarda los tickets como archivos .txt
- Útil para probar sin tener una impresora física

**Cómo funciona:**
1. Cajero o admin presiona "Imprimir ticket"
2. La app envía la orden al servidor
3. El servidor formatea el ticket con comandos ESC-POS
4. Se envía a la impresora (o se guarda en archivo si es simulación)
5. Se registra en bitácora si fue exitoso

**Archivos importantes:**
- `backend/src/modules/tickets/` - Lógica de impresión
- `lib/services/tickets_service.dart` - Cliente Flutter

---

### 10. 📊 Reportes PDF y CSV

**¿Qué hace?**
Genera reportes profesionales en PDF y CSV para análisis y contabilidad.

**Tipos de reportes:**
- **Ventas:** Ventas por día, semana, mes
- **Top Productos:** Productos más vendidos
- **Corte de Caja:** Resumen de caja del día
- **Inventario:** Movimientos de inventario

**Formato PDF:**
- Diseño profesional
- Tablas y gráficos
- Listo para imprimir o compartir

**Formato CSV:**
- Compatible con Excel
- Encoding UTF-8 (soporta acentos)
- Fácil de importar a otros sistemas

**Archivos importantes:**
- `backend/src/modules/reportes/` - Generación de reportes
- `lib/services/reportes_service.dart` - Cliente Flutter

---

### 11. 🔔 Sistema de Alertas

**¿Qué hace?**
Envía notificaciones en tiempo real sobre eventos importantes.

**Tipos de alertas:**
- **Demora:** Una orden está tardando mucho
- **Cancelación:** Se canceló una orden
- **Modificación:** Se modificó una orden
- **Caja:** Eventos relacionados con pagos
- **Cocina:** Alertas de la cocina
- **Mesa:** Eventos de mesas
- **Pago:** Eventos de pagos

**Cómo funciona:**
- Las alertas se registran en la base de datos
- Se envían en tiempo real a los roles relevantes
- Se muestran en la app con iconos y colores
- Se pueden marcar como leídas

**Archivos importantes:**
- `backend/src/modules/alertas/` - Sistema de alertas
- Integrado en `socket_service.dart`

---

### 12. 🌐 Configuración para Internet Móvil

**¿Qué hace?**
Adapta el sistema para funcionar con Internet móvil (módem 4G) que puede tener cortes y latencia variable.

**Características:**
- **Reintentos automáticos:** Si falla una petición, se reintenta automáticamente
- **Reconexión automática:** Socket.IO se reconecta solo si se pierde la conexión
- **Timeouts más largos:** Más tolerante a latencia
- **Mensajes claros:** El usuario sabe qué está pasando

**Configuración:**
- URLs configurables (desarrollo vs producción)
- Variables de entorno para cambiar fácilmente
- Documentación completa de despliegue

**Archivos importantes:**
- `lib/config/api_config.dart` - Configuración de URLs
- `lib/services/api_service.dart` - Reintentos automáticos
- `lib/services/socket_service.dart` - Reconexión automática
- `backend/docs/deploy-network.md` - Guía de despliegue

---

## 🔧 Aspectos Técnicos Importantes

### Seguridad

**¿Qué se implementó?**
- **JWT:** Tokens seguros para autenticación
- **bcrypt:** Contraseñas encriptadas (nunca se guardan en texto plano)
- **Rate Limiting:** Protección contra ataques (100 peticiones/minuto general, 5 intentos/minuto en login)
- **Helmet:** Headers de seguridad HTTP
- **CORS:** Solo permite conexiones desde dominios autorizados
- **Validación:** Todos los datos se validan antes de procesarse (Zod)

### Base de Datos

**Estructura:**
- MySQL 8 con transacciones
- Pool de conexiones para eficiencia
- Relaciones entre tablas bien definidas
- Índices para búsquedas rápidas

**Tablas principales:**
- `usuario` - Usuarios del sistema
- `rol` - Roles y permisos
- `mesa` - Mesas del restaurante
- `categoria` - Categorías de productos
- `producto` - Productos del menú
- `orden` - Órdenes de clientes
- `orden_item` - Productos en cada orden
- `pago` - Pagos registrados
- `inventario_item` - Insumos de inventario
- `alerta` - Alertas del sistema

### API REST

**Estructura:**
- Rutas organizadas por módulo (`/api/usuarios`, `/api/mesas`, etc.)
- Métodos HTTP estándar (GET, POST, PUT, PATCH, DELETE)
- Respuestas consistentes: `{ data: ... }` o `{ error: ..., message: ... }`
- Códigos HTTP correctos (200, 201, 400, 401, 403, 404, 500)

**Documentación:**
- Swagger UI en `/docs` y `/api/docs`
- Todos los endpoints documentados
- Ejemplos de peticiones y respuestas

### Flutter App

**Arquitectura:**
- **Servicios:** Lógica de comunicación con el backend
- **Controladores:** Estado de la aplicación (Provider)
- **Vistas:** Pantallas de la app
- **Configuración:** URLs y configuraciones centralizadas

**Características:**
- Manejo automático de tokens
- Refresh automático de tokens
- Reconexión automática de Socket.IO
- Manejo robusto de errores
- Mensajes amigables al usuario

---

## 📁 Estructura del Proyecto

```
comandero_flutter/
├── backend/                    # Servidor Node.js/TypeScript
│   ├── src/
│   │   ├── auth/              # Autenticación
│   │   ├── modules/           # Módulos del sistema
│   │   │   ├── usuarios/
│   │   │   ├── mesas/
│   │   │   ├── categorias/
│   │   │   ├── productos/
│   │   │   ├── inventario/
│   │   │   ├── ordenes/
│   │   │   ├── pagos/
│   │   │   ├── tickets/
│   │   │   ├── reportes/
│   │   │   └── alertas/
│   │   ├── realtime/          # Socket.IO
│   │   ├── config/           # Configuraciones
│   │   ├── middlewares/       # Middlewares
│   │   ├── utils/             # Utilidades
│   │   └── db/                # Base de datos
│   ├── docs/                  # Documentación
│   └── scripts/               # Scripts útiles
│
└── lib/                       # Aplicación Flutter
    ├── config/                # Configuración
    ├── services/              # Servicios (API, Socket)
    ├── controllers/           # Controladores (Estado)
    └── views/                 # Pantallas
```

---

## 🚀 Cómo Funciona Todo Junto

### Escenario Real: Un Día en el Restaurante

**1. Inicio del día:**
- Administrador inicia sesión
- Verifica que todo esté configurado (mesas, productos, inventario)
- Las tablets se conectan al WiFi del módem 4G

**2. Llegan clientes:**
- Mesero inicia sesión en su tablet
- Ve las mesas disponibles
- Asigna una mesa a los clientes (cambia estado a "ocupada")
- Crea una orden para esa mesa

**3. En la cocina:**
- Cocinero inicia sesión en su tablet
- Ve automáticamente la nueva orden (tiempo real)
- Cambia el estado a "en preparación"
- Cuando termina, cambia a "lista"

**4. Entrega:**
- Mesero ve que la orden está lista (tiempo real)
- La entrega al cliente
- Cambia el estado a "entregada"

**5. Pago:**
- Cliente va a caja
- Cajero inicia sesión
- Ve la orden pendiente de pago
- Registra el pago (efectivo o tarjeta)
- Imprime el ticket
- La orden se marca como "pagada"

**6. Cierre del día:**
- Administrador genera reportes de ventas
- Exporta a PDF o CSV
- Revisa el inventario
- Cierra la caja

**Todo esto funciona incluso si:**
- El Internet se corta momentáneamente (se reconecta solo)
- Hay latencia en la red (timeouts más largos)
- Múltiples tablets están usando el sistema (sincronización en tiempo real)

---

## ✅ Estado Actual del Proyecto

### Completado ✅

- [x] Sistema de autenticación completo
- [x] CRUD de todos los módulos
- [x] Tiempo real con Socket.IO
- [x] Impresión de tickets
- [x] Reportes PDF y CSV
- [x] Sistema de alertas
- [x] Configuración para Internet móvil
- [x] Seguridad implementada
- [x] Documentación completa
- [x] Verificación y corrección de errores

### Listo para Producción ✅

- [x] Variables de entorno configuradas
- [x] URLs configurables
- [x] Manejo robusto de errores
- [x] Reconexión automática
- [x] Logs seguros
- [x] Rate limiting
- [x] Validación de datos

---

## 📚 Documentación Disponible

1. **`VERIFICACION_COMPLETA_PROYECTO.md`** - Verificación técnica completa
2. **`RESUMEN_DESPLIEGUE_MODEM_VPS.md`** - Guía de despliegue con módem
3. **`backend/docs/deploy-network.md`** - Guía técnica de despliegue
4. **`backend/docs/realtime.md`** - Documentación de Socket.IO
5. **Swagger UI** - Documentación interactiva de la API

---

## 🎓 Para Entender Mejor

### Si eres Administrador:
- El sistema te permite ver todo lo que pasa en el restaurante
- Puedes crear usuarios, productos, mesas
- Generas reportes para análisis
- Todo está sincronizado en tiempo real

### Si eres Desarrollador:
- Backend en TypeScript con arquitectura limpia
- Frontend en Flutter con servicios bien organizados
- API REST documentada con Swagger
- Socket.IO para tiempo real
- Todo listo para producción

### Si eres Usuario Final (Mesero, Cocinero, Cajero):
- App fácil de usar en tablet
- Todo se actualiza automáticamente
- Funciona incluso con Internet lento
- Mensajes claros cuando hay problemas

---

## 🔮 Próximos Pasos Sugeridos

1. **Pruebas en el entorno real:**
   - Probar con tablets reales
   - Verificar funcionamiento con módem 4G
   - Validar impresión de tickets

2. **Mejoras futuras:**
   - Notificaciones push
   - Dashboard de estadísticas
   - Integración con sistemas de pago
   - App para clientes

3. **Optimizaciones:**
   - Caché de datos frecuentes
   - Compresión de imágenes
   - Optimización de consultas SQL

---

## 📞 Soporte y Mantenimiento

**Para problemas técnicos:**
- Revisar logs del backend
- Verificar conexión a MySQL
- Verificar variables de entorno
- Consultar documentación en `backend/docs/`

**Para configurar producción:**
- Seguir guía en `backend/docs/deploy-network.md`
- Configurar `.env.production`
- Compilar Flutter con variables correctas

---

**Última actualización:** 2024-01-15  
**Versión:** 1.0.0  
**Estado:** ✅ Completo y listo para pruebas

---

*Este documento combina explicaciones técnicas con lenguaje natural para que cualquier persona pueda entender qué hace el sistema y cómo funciona.*

