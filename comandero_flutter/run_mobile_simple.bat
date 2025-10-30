@echo off
echo ========================================
echo    COMANDERO - EJECUTAR EN MÓVIL
echo ========================================
echo.

echo 1. Limpiando proyecto...
flutter clean
echo.

echo 2. Obteniendo dependencias...
flutter pub get
echo.

echo 3. Verificando dispositivos...
flutter devices
echo.

echo 4. Ejecutando en dispositivo móvil...
echo    (Si tienes un emulador abierto, se ejecutará ahí)
echo    (Si no, conecta tu teléfono físico con USB)
echo.
flutter run
echo.

echo Aplicación ejecutada.
pause

