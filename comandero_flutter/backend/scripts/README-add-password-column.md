# Agregar Columna Password a la Tabla Usuario

Este script agrega la columna `password` a la tabla `usuario` para almacenar contraseñas en texto plano (solo para visualización del administrador).

## 📋 Instrucciones

### Opción 1: Ejecutar desde MySQL/MariaDB CLI

```bash
mysql -u tu_usuario -p tu_base_de_datos < add-password-column.sql
```

### Opción 2: Ejecutar desde MySQL Workbench o phpMyAdmin

1. Abre tu herramienta de gestión de base de datos (MySQL Workbench, phpMyAdmin, etc.)
2. Selecciona tu base de datos
3. Copia y pega el contenido del archivo `add-password-column.sql`
4. Ejecuta el script

### Opción 3: Ejecutar desde Node.js (si tienes un script de migración)

Puedes ejecutar el SQL directamente desde tu aplicación Node.js usando el pool de conexiones.

## ✅ Verificación

Después de ejecutar el script, verifica que la columna se agregó correctamente:

```sql
DESCRIBE usuario;
```

Deberías ver la columna `password` de tipo `VARCHAR(255)` después de `password_hash`.

## 🔒 Nota de Seguridad

- La columna `password` almacena contraseñas en **texto plano** (sin encriptar)
- Esta columna es **solo para uso administrativo** (para que el admin pueda ver y compartir contraseñas)
- Las contraseñas también se almacenan hasheadas en `password_hash` para autenticación segura
- **NUNCA** expongas esta columna en APIs públicas o interfaces de usuario normales

## 📝 Después de Ejecutar el Script

Una vez que ejecutes el script SQL, el código del backend ya está actualizado para:
- ✅ Insertar contraseñas en texto plano al crear usuarios
- ✅ Leer contraseñas en texto plano al listar/obtener usuarios
- ✅ Actualizar contraseñas en texto plano al cambiar contraseñas

No necesitas reiniciar el servidor, pero asegúrate de que el script SQL se haya ejecutado correctamente.

