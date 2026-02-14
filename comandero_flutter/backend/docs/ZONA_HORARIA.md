# Zona horaria en Comandix

## Comportamiento del sistema

- **Zona horaria de la aplicación:** `America/Mexico_City` (CDMX).
- **Base de datos:** MySQL guarda todas las fechas/horas en **UTC**.
- **API:** Las fechas se envían al frontend en hora CDMX (ISO con offset, ej. `-06:00`).
- **Frontend:** Muestra siempre en hora local (CDMX) usando `AppDateUtils.parseToLocal()` y `formatTime()`.

## Cómo se garantiza la hora correcta

1. **Backend (Node.js)**  
   En cada conexión a MySQL se ejecuta `SET time_zone = '+00:00'`. Así, `NOW()` y `CURRENT_TIMESTAMP` se guardan en UTC.

2. **Al leer de MySQL**  
   El driver usa `timezone: 'Z'`, por lo que interpreta los valores como UTC. El backend convierte a CDMX con `utcToMxISO()` antes de enviar la respuesta.

3. **Al desplegar en un servidor**  
   No hace falta configurar la zona horaria del sistema operativo para la app. La lógica depende de:
   - Sesión MySQL en UTC (ya aplicada por el pool).
   - Código que siempre convierte UTC → CDMX al responder.

## Nota sobre datos antiguos

Si antes de este ajuste la base guardaba hora local (por ejemplo, servidor en México), los registros antiguos pueden seguir mostrando una hora desfasada (p. ej. 6 horas menos). Los **nuevos** registros (órdenes, pagos, alertas, etc.) se guardan en UTC y se muestran correctamente en CDMX.

## Resumen para el cliente

- La hora que ve el usuario (mesero, cajero, cocinero, etc.) es la de **México (CDMX)**.
- En servidor privado o en la nube no es necesario tocar la zona horaria del SO para que la app muestre bien la hora.
- Si el cliente usa otra zona horaria en el futuro, bastaría con cambiar la constante `APP_TIMEZONE` en `src/config/time.ts` y la lógica equivalente en el frontend.
