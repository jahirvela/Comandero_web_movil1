@echo off
echo ========================================
echo    COMANDERO FLUTTER - TABLET
echo ========================================
echo.

echo 1. Verificando emuladores disponibles...
flutter emulators
echo.

echo 2. Iniciando emulador de tablet (Medium Tablet)...
echo    Esto puede tomar 1-2 minutos...
flutter emulators --launch Medium_Tablet
echo.

echo 3. Esperando 45 segundos para inicializacion...
timeout /t 45 /nobreak
echo.

echo 4. Verificando dispositivos...
flutter devices
echo.

echo 5. Si el emulador aparece, ejecutando aplicacion...
echo    Presiona Ctrl+C si quieres cancelar
flutter run -d Medium_Tablet

pause


