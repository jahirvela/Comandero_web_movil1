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
echo (Modo desarrollo optimizado)
echo.

REM Ejecutar con flags optimizados para Chrome
REM --web-port=8080: Puerto fijo para evitar conflictos
REM --web-hostname=localhost: Hostname local para mejor rendimiento
flutter run -d chrome --web-port=8080 --web-hostname=localhost

pause

