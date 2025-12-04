# Pruebas automatizadas (Jest + Supertest)

## Comandos

- `npm test`  
  Ejecuta las pruebas en modo `NODE_ENV=test`. De forma predeterminada solo se corre `health.spec.ts`, que no requiere conexión a MySQL.

- `RUN_DB_TESTS=true npm test`  
  Ejecuta además los suites que dependen de la base de datos (`auth.spec.ts`, `usuarios.spec.ts`, `ordenes.spec.ts`). Es indispensable tener MySQL levantado, con el esquema y seeds cargados (usuario `admin` / `Demo1234` por omisión).

## Cobertura actual

- `health.spec.ts`: ping a `/api/health`.
- `auth.spec.ts`: login exitoso y rechazo de credenciales incorrectas.
- `usuarios.spec.ts`: creación de usuario y verificación en el listado.
- `ordenes.spec.ts`: creación de categoría + producto, y registro de una orden básica.

## Notas

- Las pruebas reutilizan el backend real (`app` de Express) y Supertest; no se mockea la capa de base de datos.
- Si la suite se queda esperando la base de datos, revisa la configuración `.env.test` (opcional) y las variables `TEST_USERNAME` / `TEST_PASSWORD`.
- El logger mostrará advertencias si MySQL no está disponible; es esperado cuando `RUN_DB_TESTS` está deshabilitado.

