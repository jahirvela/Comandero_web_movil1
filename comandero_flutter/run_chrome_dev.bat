@echo off
echo ========================================
echo    COMANDERO FLUTTER - CHROME DEV
echo ========================================
echo.

REM Cerrar instancias anteriores de Chrome
echo Cerrando instancias anteriores...
taskkill /f /im chrome.exe 2>nul
timeout /t 1 /nobreak >nul

echo Ejecutando en modo desarrollo optimizado...
echo.
echo Flags optimizados para desarrollo rápido:
echo   - Puerto fijo (8080) para mejor rendimiento
echo   - Hostname localhost
echo.

REM Flags optimizados para desarrollo rápido
flutter run -d chrome --web-port=8080 --web-hostname=localhost

pause

