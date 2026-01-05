@echo off
echo ========================================
echo    OBTENER IP DE LA LAPTOP
echo ========================================
echo.
echo Esta es la IP que debes usar para conectar
echo el APK del celular al backend de la laptop:
echo.
echo ----------------------------------------

ipconfig | findstr /i "IPv4"

echo ----------------------------------------
echo.
echo INSTRUCCIONES:
echo.
echo 1. Anota la IP que aparece arriba (ejemplo: 192.168.1.5)
echo 2. Abre la app en tu celular
echo 3. En la pantalla de login, busca "Configurar servidor"
echo 4. Ingresa la IP que anotaste (ejemplo: 192.168.1.5)
echo 5. Presiona "Probar conexion" o "Guardar"
echo.
echo IMPORTANTE: Asegurate de que:
echo   - El backend este corriendo en la laptop
echo   - El celular y la laptop esten en la misma red WiFi
echo.
pause

