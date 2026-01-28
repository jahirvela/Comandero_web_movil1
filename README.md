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
   
   # Importar el script SQL
   mysql -u root -p comandero < comandero_flutter/backend/backups/comandero.sql
   ```

3. **Configurar el Backend**
   ```bash
   cd comandero_flutter/backend
   npm install
   
   # Copiar archivo de configuración
   cp .env.example .env
   
   # Editar .env con tus credenciales de base de datos
   # DB_HOST=localhost
   # DB_USER=root
   # DB_PASSWORD=tu_password
   # DB_NAME=comandero
   ```

4. **Configurar el Frontend**
   ```bash
   cd comandero_flutter
   flutter pub get
   ```

5. **Iniciar el Backend**
   ```bash
   cd backend
   npm run dev
   ```

6. **Ejecutar la Aplicación Flutter**
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

**Usuario Administrador:**
- Username: `admin`
- Password: (configurar después de importar la BD usando el script `crear-usuario-admin.js`)

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
