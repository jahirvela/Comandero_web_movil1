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
echo (Renderizador HTML para inicio más rápido)
echo.

REM Flags optimizados para desarrollo rápido:
REM --web-renderer=html: Renderizado más rápido (no CanvasKit)
REM --no-sound-null-safety: Evitar verificaciones innecesarias
REM --web-port=0: Puerto aleatorio para evitar conflictos
flutter run -d chrome --web-renderer=html --no-sound-null-safety --web-port=0

pause

