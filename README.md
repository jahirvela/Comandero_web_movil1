# COMANDERO - Sistema de Gestión de Restaurante

Sistema completo de gestión de restaurante desarrollado en Flutter con backend Node.js/TypeScript.

## 📁 Estructura del Proyecto

Este repositorio contiene únicamente la carpeta `comandero_flutter` que incluye:
- **Frontend Flutter**: Aplicación móvil y web multiplataforma
- **Backend Node.js/TypeScript**: API REST y Socket.IO para comunicación en tiempo real
- **Base de datos MySQL**: Script SQL completo para recrear la base de datos

## 🚀 Instalación

### Requisitos Previos
- Flutter SDK (última versión estable)
- Node.js 18+ y npm
- MySQL 8.0+ o MariaDB 10.5+
- Git

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   cd comandero_web_movil
   ```

2. **Configurar la Base de Datos**
   ```bash
   # Crear la base de datos
   mysql -u root -p
   CREATE DATABASE comandero CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   EXIT;
   
   # Importar el script SQL completo (estructura + datos semilla)
   mysql -u root -p comandero < comandero_flutter/backend/backups/comandero.sql
   ```

   Incluye todos los datos semilla: roles, permisos, estados de mesa/orden, formas de pago,
   configuración e impresoras. Usuario admin: admin / Demo1234.

   Si solo necesitas datos semilla: `mysql -u root -p comandero < comandero_flutter/backend/scripts/seed-datos-iniciales.sql`

3. **Configurar el Backend**
   ```bash
   cd comandero_flutter/backend
   npm install
   
   # Copiar archivo de configuración
   cp .env.example .env
   
   # Editar .env con tus credenciales de base de datos
   # DATABASE_HOST=127.0.0.1
   # DATABASE_USER=root
   # DATABASE_PASSWORD=tu_password
   # DATABASE_NAME=comandero
   ```

4. **Usuarios demo adicionales (opcional)**

   El script SQL ya incluye admin (admin / Demo1234). Para más usuarios demo:
   Ejecuta:

   ```bash
   cd comandero_flutter/backend

   npx tsx scripts/seed-users.ts
   ```

5. **Configurar el Frontend**
   ```bash
   cd comandero_flutter
   flutter pub get
   ```

6. **Iniciar el Backend**
   ```bash
   cd backend
   npm run dev
   ```

7. **Ejecutar la Aplicación Flutter**
   ```bash
   flutter run
   ```

## 📊 Base de Datos

El script SQL completo se encuentra en:
- `comandero_flutter/backend/backups/comandero.sql`

Este script incluye:
- ✅ Estructura completa de todas las tablas
- ✅ Relaciones y foreign keys
- ✅ Índices para optimización
- ✅ Datos iniciales (roles, permisos, estados, formas de pago)
- ✅ Usuario administrador por defecto

## 🔐 Credenciales por Defecto

**Usuario Administrador (incluido en comandero.sql):**
- Username: `admin`
- Password: `Demo1234`

## 📝 Notas Importantes

- El repositorio solo incluye la carpeta `comandero_flutter`
- No se incluyen archivos binarios de base de datos ni backups comprimidos
- Solo se incluye el script SQL completo para recrear la base de datos
- Los archivos `.env` y `node_modules` están excluidos del control de versiones

## 🛠️ Desarrollo

Para más información sobre el desarrollo y despliegue, consulta la documentación en:
- `comandero_flutter/docs/`
- `comandero_flutter/backend/docs/`

## 📄 Licencia

[Especificar licencia si aplica]
