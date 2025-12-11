@echo off
REM Script principal optimizado para iniciar Chrome rápidamente
REM Este es el script que debes usar normalmente

echo ========================================
echo   COMANDIX - Inicio Rapido
echo ========================================
echo.

REM Cerrar Chrome anterior (sin esperar mucho)
taskkill /f /im chrome.exe 2>nul
timeout /t 1 /nobreak >nul

REM Iniciar con optimizaciones (sin limpiar build para ser mas rapido)
echo Iniciando Chrome optimizado...
echo.
echo Tiempo estimado: 5-15 segundos
echo.

flutter run -d chrome --web-port=8080 --web-hostname=localhost

pause

