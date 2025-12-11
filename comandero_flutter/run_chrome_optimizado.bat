@echo off
echo ========================================
echo   COMANDIX - CHROME OPTIMIZADO
echo ========================================
echo.

REM Cerrar instancias anteriores de Chrome
echo [1/4] Cerrando instancias anteriores de Chrome...
taskkill /f /im chrome.exe 2>nul
taskkill /f /im msedge.exe 2>nul
timeout /t 1 /nobreak >nul

REM Limpiar caché de Flutter si es necesario (solo si hay problemas)
REM echo [2/4] Limpiando caché de Flutter...
REM flutter clean >nul 2>&1

echo [2/4] Obteniendo dependencias...
flutter pub get >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: No se pudieron obtener las dependencias
    pause
    exit /b 1
)

echo [3/4] Preparando entorno optimizado...
echo.

echo [4/4] Iniciando Chrome con optimizaciones de rendimiento...
echo.
echo Optimizaciones aplicadas:
echo   - Puerto fijo (8080) para evitar conflictos
echo   - Hostname localhost para mejor rendimiento
echo   - Modo desarrollo optimizado
echo.
echo Presiona Ctrl+C para detener...
echo.

REM Ejecutar con todas las optimizaciones
flutter run -d chrome ^
  --web-port=8080 ^
  --web-hostname=localhost ^
  --dart-define=FLUTTER_WEB_USE_SKIA=false

pause

