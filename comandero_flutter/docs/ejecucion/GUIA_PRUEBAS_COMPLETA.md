# 🧪 Guía Completa de Pruebas - Comandix

## ✅ ¡Login Funcionando!

Ahora que puedes iniciar sesión, aquí tienes una guía completa de pruebas para verificar que todo funcione correctamente.

---

## 📋 Índice de Pruebas

1. [Pruebas Básicas de Autenticación](#1-pruebas-básicas-de-autenticación)
2. [Pruebas de Módulos CRUD](#2-pruebas-de-módulos-crud)
3. [Pruebas de Tiempo Real (Socket.IO)](#3-pruebas-de-tiempo-real-socketio)
4. [Pruebas de Impresión de Tickets](#4-pruebas-de-impresión-de-tickets)
5. [Pruebas de Reportes (PDF/CSV)](#5-pruebas-de-reportes-pdfcsv)
6. [Pruebas de Alertas en Tiempo Real](#6-pruebas-de-alertas-en-tiempo-real)
7. [Pruebas de Roles y Permisos](#7-pruebas-de-roles-y-permisos)
8. [Pruebas en Diferentes Dispositivos](#8-pruebas-en-diferentes-dispositivos)
9. [Pruebas de Rendimiento](#9-pruebas-de-rendimiento)

---

## 1. Pruebas Básicas de Autenticación

### ✅ Login/Logout

**Prueba 1.1: Login Exitoso**
- [ ] Iniciar sesión con `admin` / `Demo1234`
- [ ] Verificar que redirige a la pantalla principal
- [ ] Verificar que muestra el nombre de usuario
- [ ] Verificar que el rol se muestra correctamente

**Prueba 1.2: Logout**
- [ ] Hacer clic en "Cerrar Sesión"
- [ ] Verificar que redirige a la pantalla de login
- [ ] Verificar que no se puede acceder a rutas protegidas

**Prueba 1.3: Sesión Persistente**
- [ ] Iniciar sesión
- [ ] Cerrar el navegador completamente
- [ ] Abrir el navegador nuevamente
- [ ] Verificar que la sesión se mantiene (si está configurado)

---

## 2. Pruebas de Módulos CRUD

### 2.1. Gestión de Usuarios

**Como Administrador:**

- [ ] **Listar usuarios:**
  - Ir a la sección de usuarios
  - Verificar que se muestran todos los usuarios
  - Verificar que se muestran los roles de cada usuario

- [ ] **Crear usuario:**
  - Crear un nuevo usuario (mesero, cocinero, etc.)
  - Verificar que se guarda correctamente
  - Verificar que aparece en la lista

- [ ] **Editar usuario:**
  - Editar un usuario existente
  - Cambiar nombre, teléfono, roles
  - Verificar que los cambios se guardan

- [ ] **Desactivar/Activar usuario:**
  - Desactivar un usuario
  - Verificar que no puede iniciar sesión
  - Reactivarlo y verificar que puede iniciar sesión

---

### 2.2. Gestión de Mesas

- [ ] **Listar mesas:**
  - Ver todas las mesas disponibles
  - Verificar estados (libre, ocupada, reservada)

- [ ] **Cambiar estado de mesa:**
  - Cambiar una mesa de "libre" a "ocupada"
  - Verificar que el cambio se refleja en tiempo real
  - Cambiar de vuelta a "libre"

- [ ] **Crear/Editar mesa:**
  - Crear una nueva mesa
  - Editar número, capacidad, ubicación
  - Verificar que se guarda correctamente

---

### 2.3. Gestión de Productos

- [ ] **Listar productos:**
  - Ver todos los productos
  - Filtrar por categoría
  - Buscar productos por nombre

- [ ] **Crear producto:**
  - Crear un nuevo producto
  - Asignar categoría, precio, descripción
  - Verificar que aparece en el menú

- [ ] **Editar producto:**
  - Cambiar precio, descripción, disponibilidad
  - Verificar que los cambios se reflejan

- [ ] **Desactivar producto:**
  - Desactivar un producto
  - Verificar que no aparece en el menú para meseros

---

### 2.4. Gestión de Categorías

- [ ] **Listar categorías:**
  - Ver todas las categorías

- [ ] **Crear categoría:**
  - Crear nueva categoría
  - Asignar nombre, descripción, orden

- [ ] **Editar categoría:**
  - Cambiar nombre, orden
  - Verificar que se actualiza

---

### 2.5. Gestión de Inventario

- [ ] **Listar items de inventario:**
  - Ver todos los insumos
  - Verificar stock actual, mínimo, máximo

- [ ] **Registrar movimiento:**
  - Registrar entrada de inventario
  - Registrar salida de inventario
  - Verificar que el stock se actualiza

- [ ] **Alertas de stock bajo:**
  - Verificar que se muestran alertas cuando el stock está bajo
  - Verificar que se pueden filtrar por estado

---

### 2.6. Gestión de Órdenes

- [ ] **Crear orden:**
  - Crear una nueva orden
  - Agregar productos
  - Asignar a una mesa
  - Verificar que se crea correctamente

- [ ] **Agregar items a orden:**
  - Agregar más productos a una orden existente
  - Verificar que se actualiza el total

- [ ] **Cambiar estado de orden:**
  - Cambiar estado: pendiente → en preparación → listo → entregado
  - Verificar que cada cambio se refleja

- [ ] **Ver historial de órdenes:**
  - Ver todas las órdenes
  - Filtrar por fecha, estado, mesa
  - Ver detalles de una orden

---

### 2.7. Gestión de Pagos

- [ ] **Registrar pago:**
  - Registrar pago en efectivo
  - Registrar pago con tarjeta
  - Verificar que se guarda correctamente

- [ ] **Registrar propina:**
  - Agregar propina a un pago
  - Verificar que se calcula correctamente

- [ ] **Ver historial de pagos:**
  - Ver todos los pagos
  - Filtrar por fecha, forma de pago
  - Ver detalles de un pago

---

## 3. Pruebas de Tiempo Real (Socket.IO)

### 3.1. Verificar Conexión Socket.IO

**En la consola del navegador (F12 → Console):**

- [ ] Verificar que aparece: `Socket.IO conectado` o `Socket connected`
- [ ] Verificar que no hay errores de conexión

---

### 3.2. Pruebas de Sincronización en Tiempo Real

**Abre 2 pestañas de Chrome con la app:**

**Pestaña 1 (Admin):**
- [ ] Crear una orden
- [ ] Cambiar estado de una mesa

**Pestaña 2 (Admin):**
- [ ] Verificar que la orden aparece automáticamente (sin refrescar)
- [ ] Verificar que el estado de la mesa se actualiza automáticamente

**Pestaña 1:**
- [ ] Cambiar estado de una orden (pendiente → en preparación)

**Pestaña 2:**
- [ ] Verificar que el estado se actualiza automáticamente

---

### 3.3. Pruebas de Reconexión

- [ ] Desconectar el backend temporalmente (Ctrl + C)
- [ ] Verificar que aparece mensaje de desconexión en la consola
- [ ] Reconectar el backend (`npm run dev`)
- [ ] Verificar que Socket.IO se reconecta automáticamente
- [ ] Verificar que aparece mensaje de reconexión

---

## 4. Pruebas de Impresión de Tickets

### 4.1. Verificar Configuración

**En el backend, verifica el archivo `.env`:**
```env
PRINTER_TYPE=simulation
PRINTER_INTERFACE=file
PRINTER_SIMULATION_PATH=./tickets
```

---

### 4.2. Imprimir Ticket de Orden

**Como Administrador o Cajero:**

- [ ] Ir a una orden completada
- [ ] Hacer clic en "Imprimir Ticket"
- [ ] Verificar que se genera el ticket
- [ ] Verificar que el archivo se guarda en `backend/tickets/` (si está en modo simulación)
- [ ] Abrir el archivo y verificar que contiene:
  - [ ] Información del restaurante
  - [ ] Número de orden
  - [ ] Fecha y hora
  - [ ] Lista de productos con precios
  - [ ] Totales (subtotal, impuestos, total)
  - [ ] Código de barras (si está configurado)

---

### 4.3. Imprimir Ticket de Pago

- [ ] Completar un pago
- [ ] Hacer clic en "Imprimir Comprobante"
- [ ] Verificar que se genera el ticket de pago
- [ ] Verificar que contiene información del pago

---

## 5. Pruebas de Reportes (PDF/CSV)

### 5.1. Generar Reporte de Ventas (PDF)

**Como Administrador o Cajero:**

- [ ] Ir a la sección de Reportes
- [ ] Seleccionar "Reporte de Ventas"
- [ ] Seleccionar rango de fechas
- [ ] Hacer clic en "Generar PDF"
- [ ] Verificar que se descarga el PDF
- [ ] Abrir el PDF y verificar que contiene:
  - [ ] Información del restaurante
  - [ ] Rango de fechas
  - [ ] Resumen de ventas
  - [ ] Lista de órdenes
  - [ ] Totales

---

### 5.2. Generar Reporte de Ventas (CSV)

- [ ] Seleccionar "Reporte de Ventas"
- [ ] Seleccionar rango de fechas
- [ ] Hacer clic en "Generar CSV"
- [ ] Verificar que se descarga el CSV
- [ ] Abrir el CSV en Excel y verificar que los datos son correctos

---

### 5.3. Generar Reporte de Productos Más Vendidos

- [ ] Ir a Reportes → "Productos Más Vendidos"
- [ ] Seleccionar rango de fechas
- [ ] Generar PDF o CSV
- [ ] Verificar que muestra los productos ordenados por cantidad vendida

---

### 5.4. Generar Corte de Caja (CSV)

**Como Cajero:**

- [ ] Ir a Reportes → "Corte de Caja"
- [ ] Seleccionar fecha
- [ ] Generar CSV
- [ ] Verificar que contiene:
  - [ ] Resumen de pagos por forma de pago
  - [ ] Total de efectivo
  - [ ] Total de tarjeta
  - [ ] Propinas
  - [ ] Totales

---

### 5.5. Generar Reporte de Inventario

**Como Administrador:**

- [ ] Ir a Reportes → "Inventario"
- [ ] Generar PDF o CSV
- [ ] Verificar que contiene:
  - [ ] Lista de todos los items
  - [ ] Stock actual
  - [ ] Stock mínimo
  - [ ] Alertas de stock bajo

---

## 6. Pruebas de Alertas en Tiempo Real

### 6.1. Verificar Conexión de Alertas

**En la consola del navegador:**
- [ ] Verificar que hay listeners para alertas
- [ ] Verificar que no hay errores

---

### 6.2. Probar Alertas de Demora

**Abre 2 pestañas:**

**Pestaña 1 (Cocinero):**
- [ ] Cambiar estado de una orden a "en preparación"
- [ ] Esperar más de X minutos (configurado)

**Pestaña 2 (Admin/Mesero):**
- [ ] Verificar que aparece alerta de demora
- [ ] Verificar que la alerta muestra información de la orden

---

### 6.3. Probar Alertas de Cancelación

**Pestaña 1:**
- [ ] Cancelar una orden

**Pestaña 2:**
- [ ] Verificar que aparece alerta de cancelación
- [ ] Verificar que muestra información de la orden cancelada

---

### 6.4. Probar Alertas de Modificación

**Pestaña 1:**
- [ ] Modificar una orden (agregar/eliminar productos)

**Pestaña 2:**
- [ ] Verificar que aparece alerta de modificación
- [ ] Verificar que muestra los cambios

---

### 6.5. Probar Alertas de Caja

**Pestaña 1 (Cajero):**
- [ ] Registrar un pago grande
- [ ] Abrir caja

**Pestaña 2 (Admin):**
- [ ] Verificar que aparece alerta de caja
- [ ] Verificar que muestra información del movimiento

---

## 7. Pruebas de Roles y Permisos

### 7.1. Crear Usuarios con Diferentes Roles

**Como Administrador:**

- [ ] Crear usuario "Mesero"
- [ ] Crear usuario "Cocinero"
- [ ] Crear usuario "Cajero"
- [ ] Crear usuario "Capitán"

---

### 7.2. Probar Permisos de Cada Rol

**Mesero:**
- [ ] Iniciar sesión como mesero
- [ ] Verificar que puede ver mesas
- [ ] Verificar que puede crear órdenes
- [ ] Verificar que NO puede acceder a sección de administración
- [ ] Verificar que NO puede generar reportes

**Cocinero:**
- [ ] Iniciar sesión como cocinero
- [ ] Verificar que puede ver órdenes en cocina
- [ ] Verificar que puede cambiar estado de órdenes
- [ ] Verificar que NO puede ver mesas
- [ ] Verificar que NO puede ver pagos

**Cajero:**
- [ ] Iniciar sesión como cajero
- [ ] Verificar que puede ver pagos
- [ ] Verificar que puede registrar pagos
- [ ] Verificar que puede generar corte de caja
- [ ] Verificar que NO puede crear productos

**Capitán:**
- [ ] Iniciar sesión como capitán
- [ ] Verificar que puede ver todas las mesas
- [ ] Verificar que puede ver todas las órdenes
- [ ] Verificar que puede cambiar estados
- [ ] Verificar que NO puede acceder a administración

**Administrador:**
- [ ] Iniciar sesión como admin
- [ ] Verificar que puede acceder a TODO
- [ ] Verificar que puede gestionar usuarios
- [ ] Verificar que puede generar todos los reportes

---

## 8. Pruebas en Diferentes Dispositivos

### 8.1. Chrome (Web)

- [ ] Verificar que todas las funcionalidades funcionan
- [ ] Verificar que el diseño se adapta correctamente
- [ ] Verificar que Socket.IO funciona
- [ ] Verificar que los reportes se descargan correctamente

---

### 8.2. Tablet (Emulador o Físico)

**Configuración:**
- [ ] Verificar que `api_config.dart` usa `10.0.2.2:3000` para Android
- [ ] Verificar que el backend está accesible desde el emulador

**Pruebas:**
- [ ] Iniciar sesión
- [ ] Verificar que todas las funcionalidades funcionan
- [ ] Verificar que el diseño se adapta a tablet
- [ ] Verificar que Socket.IO funciona

---

### 8.3. Móvil (Emulador o Físico)

**Configuración:**
- [ ] Verificar que `api_config.dart` usa `10.0.2.2:3000` para Android
- [ ] Verificar que el backend está accesible desde el emulador

**Pruebas:**
- [ ] Iniciar sesión
- [ ] Verificar que todas las funcionalidades funcionan
- [ ] Verificar que el diseño se adapta a móvil
- [ ] Verificar que Socket.IO funciona
- [ ] Verificar que los botones son fáciles de tocar

---

## 9. Pruebas de Rendimiento

### 9.1. Carga de Datos

- [ ] Cargar lista de 100+ productos
- [ ] Verificar que la carga es rápida (< 2 segundos)
- [ ] Verificar que no hay lag en la UI

---

### 9.2. Múltiples Órdenes Simultáneas

- [ ] Crear 10 órdenes rápidamente
- [ ] Verificar que todas se crean correctamente
- [ ] Verificar que se sincronizan en tiempo real

---

### 9.3. Reconexión Automática

- [ ] Desconectar el backend
- [ ] Intentar hacer una acción
- [ ] Reconectar el backend
- [ ] Verificar que se reconecta automáticamente
- [ ] Verificar que la acción se completa

---

## 10. Pruebas de Escenarios de Error

### 10.1. Backend Desconectado

- [ ] Detener el backend
- [ ] Intentar hacer login
- [ ] Verificar que muestra mensaje de error claro
- [ ] Reconectar el backend
- [ ] Verificar que funciona nuevamente

---

### 10.2. Credenciales Incorrectas

- [ ] Intentar login con usuario incorrecto
- [ ] Verificar que muestra mensaje de error
- [ ] Intentar login con contraseña incorrecta
- [ ] Verificar que muestra mensaje de error

---

### 10.3. Validaciones de Formularios

- [ ] Intentar crear producto sin nombre
- [ ] Verificar que muestra error de validación
- [ ] Intentar crear orden sin productos
- [ ] Verificar que muestra error de validación

---

## 📊 Checklist de Pruebas Rápidas

### Pruebas Esenciales (Hacer Primero):

- [ ] ✅ Login funciona
- [ ] ✅ Logout funciona
- [ ] ✅ Crear orden funciona
- [ ] ✅ Cambiar estado de orden funciona
- [ ] ✅ Socket.IO funciona (ver en 2 pestañas)
- [ ] ✅ Generar reporte PDF funciona
- [ ] ✅ Generar reporte CSV funciona
- [ ] ✅ Imprimir ticket funciona
- [ ] ✅ Alertas aparecen en tiempo real

---

## 🎯 Pruebas Recomendadas por Prioridad

### Prioridad ALTA (Hacer Primero):

1. **Login/Logout** ✅ (Ya funcionando)
2. **Crear y gestionar órdenes**
3. **Socket.IO en tiempo real** (2 pestañas)
4. **Generar reportes PDF/CSV**
5. **Imprimir tickets**

### Prioridad MEDIA:

6. **Gestión de usuarios y roles**
7. **Gestión de productos y categorías**
8. **Gestión de inventario**
9. **Alertas en tiempo real**

### Prioridad BAJA:

10. **Pruebas en tablet/móvil**
11. **Pruebas de rendimiento**
12. **Pruebas de escenarios de error**

---

## 📝 Notas para las Pruebas

### Verificar en la Consola del Navegador:

- **F12** → **Console** para ver logs
- **F12** → **Network** para ver peticiones HTTP
- **F12** → **Application** → **Storage** para ver tokens guardados

### Verificar en la Terminal del Backend:

- Logs de peticiones HTTP
- Logs de Socket.IO
- Errores de base de datos
- Errores de impresión

---

## ✅ Después de las Pruebas

Si encuentras algún problema:

1. **Anota el problema** con pasos para reproducirlo
2. **Toma capturas de pantalla** de los errores
3. **Copia los mensajes** de la consola del navegador
4. **Copia los mensajes** de la terminal del backend

---

**¡Empieza con las pruebas de Prioridad ALTA y luego continúa con las demás!** 🚀

---

**Última actualización:** 2024-01-15

