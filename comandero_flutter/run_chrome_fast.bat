@echo off
echo ========================================
echo    COMANDERO FLUTTER - CHROME RAPIDO
echo ========================================
echo.

echo Optimizando inicio de Chrome...
echo.

REM Cerrar instancias anteriores de Chrome que puedan estar bloqueando
echo Cerrando instancias anteriores de Chrome...
taskkill /f /im chrome.exe 2>nul
taskkill /f /im msedge.exe 2>nul
timeout /t 1 /nobreak >nul

echo Obteniendo dependencias (si es necesario)...
flutter pub get >nul 2>&1
echo.

echo Iniciando Chrome con optimizaciones...
echo (Usando renderizador HTML para inicio más rápido)
echo.

REM Ejecutar con flags optimizados para Chrome
REM --web-renderer=html: Renderizado HTML más rápido (no CanvasKit)
REM --no-sound-null-safety: Evitar verificaciones innecesarias
REM --dart-define=FLUTTER_WEB_USE_SKIA=false: Desactivar Skia
REM --web-port=0: Puerto aleatorio para evitar conflictos
flutter run -d chrome --web-renderer=html --no-sound-null-safety --web-port=0

pause

