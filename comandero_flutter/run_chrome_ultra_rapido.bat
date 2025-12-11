@echo off
echo ========================================
echo   COMANDIX - MODO ULTRA RAPIDO
echo ========================================
echo.
echo Este script optimiza al maximo el inicio de Chrome
echo Puede tardar 30-60 segundos la primera vez
echo.

REM Cerrar todo lo relacionado con Chrome/Flutter
echo [1/5] Cerrando procesos anteriores...
taskkill /f /im chrome.exe 2>nul
taskkill /f /im msedge.exe 2>nul
taskkill /f /im dart.exe 2>nul
taskkill /f /im flutter.exe 2>nul
timeout /t 2 /nobreak >nul

REM Limpiar puerto 8080 si está ocupado
echo [2/5] Liberando puerto 8080...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8080" ^| findstr "LISTENING"') do (
    taskkill /f /pid %%a >nul 2>&1
)
timeout /t 1 /nobreak >nul

REM Verificar dependencias (sin output)
echo [3/5] Verificando dependencias...
flutter pub get >nul 2>&1

REM Limpiar build anterior para forzar rebuild optimizado
echo [4/5] Preparando build optimizado...
if exist build\web (
    rmdir /s /q build\web >nul 2>&1
)

echo [5/5] Iniciando Chrome con MAXIMAS optimizaciones...
echo.
echo NOTA: La primera compilacion puede tardar 30-60 segundos
echo       Las siguientes seran mucho mas rapidas (5-10 segundos)
echo.
echo Presiona Ctrl+C para detener...
echo.

REM Ejecutar con todas las optimizaciones posibles (sin --release para mantener hot reload)
flutter run -d chrome ^
  --web-port=8080 ^
  --web-hostname=localhost ^
  --dart-define=FLUTTER_WEB_USE_SKIA=false ^
  --dart-define=FLUTTER_WEB_AUTO_DETECT=false

if %errorlevel% neq 0 (
    echo.
    echo ERROR: No se pudo iniciar Chrome
    echo Intentando en modo debug...
    flutter run -d chrome --web-port=8080
)

pause

