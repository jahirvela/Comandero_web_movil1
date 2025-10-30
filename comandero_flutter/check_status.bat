@echo off
echo ========================================
echo    COMANDERO FLUTTER - VERIFICACION
echo ========================================
echo.

echo Verificando estado del proyecto...
echo.

echo 1. Dependencias:
flutter pub get
echo.

echo 2. Analisis de codigo:
flutter analyze
echo.

echo 3. Dispositivos disponibles:
flutter devices
echo.

echo 4. Emuladores disponibles:
flutter emulators
echo.

echo ========================================
echo    OPCIONES DISPONIBLES:
echo ========================================
echo.
echo Para ejecutar en:
echo - Chrome (Web): flutter run -d chrome
echo - Celular: Ejecuta start_mobile.bat
echo - Tablet: Ejecuta start_tablet.bat
echo - Windows: flutter run -d windows
echo.

pause


