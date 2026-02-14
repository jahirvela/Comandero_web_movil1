# Instalación - Proyecto Comandero

Guía para clonar el repositorio y ejecutar el proyecto (backend + frontend) sin errores.

## Requisitos previos

- **Node.js** 18+ (para el backend)
- **MySQL** 8.0+ (o MariaDB compatible)
- **Flutter** 3.x (para la app móvil/web)

## 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd comandero_web_movil
```

## 2. Configurar la base de datos

### Opción A: Base de datos desde cero (recomendado)

1. Crear la base de datos:

```sql
CREATE DATABASE IF NOT EXISTS comandero CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

2. Ejecutar el script completo (estructura + datos semilla):

```bash
cd comandero_flutter/backend
mysql -u root -p comandero < backups/comandero.sql
```

3. **(Opcional)** Ejecutar migraciones adicionales si existen en `docs/migraciones/` y aplicar el script de semilla:

```bash
mysql -u root -p comandero < scripts/seed-datos-iniciales.sql
```

### Opción B: Solo datos semilla (estructura ya existe)

Si ya ejecutaste una migración previa y solo necesitas los datos semilla:

```bash
mysql -u root -p comandero < scripts/seed-datos-iniciales.sql
```

### Usuarios demo adicionales (opcional)

Para crear cajero1, capitan1, mesero1, cocinero1, admincaja (todos con contraseña `Demo1234`):

```bash
cd comandero_flutter/backend
npm install
npx tsx scripts/seed-users.ts
```

## 3. Configurar el backend

1. Copiar el archivo de variables de entorno:

```bash
cp .env.example .env
```

2. Editar `.env` con tus credenciales de MySQL:

```
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=tu_password
DB_NAME=comandero
```

3. Instalar dependencias e iniciar el servidor:

```bash
npm install
npm run dev
```

## 4. Configurar el frontend (Flutter)

```bash
cd comandero_flutter
flutter pub get
flutter run -d chrome   # Para web
# o
flutter run             # Para móvil/escritorio
```

## Credenciales por defecto

| Usuario   | Contraseña | Rol          |
|-----------|------------|--------------|
| admin     | Demo1234   | Administrador |

## Datos semilla incluidos

El script `seed-datos-iniciales.sql` incluye:

- **Roles:** administrador, cajero, capitan, mesero, cocinero
- **Permisos:** ver_caja, cerrar_caja, editar_menu, ver_reportes, gestionar_usuarios
- **Estados de mesa:** LIBRE, OCUPADA, RESERVADA, EN_LIMPIEZA
- **Estados de orden:** abierta, en_preparacion, listo, listo_para_recoger, pagada, cerrada, cancelada
- **Formas de pago:** efectivo, tarjeta_debito, tarjeta_credito, transferencia
- **Configuración:** IVA deshabilitado por defecto (id=1)
- **Usuario admin:** admin / Demo1234

## Solución de problemas

- **Error "rol no encontrado"**: Ejecuta `seed-datos-iniciales.sql` para cargar los roles.
- **Error "estado_mesa no existe"**: Asegúrate de haber ejecutado la migración completa antes del seed.
- **Error de conexión a BD**: Verifica las variables en `.env` y que MySQL esté en ejecución.
