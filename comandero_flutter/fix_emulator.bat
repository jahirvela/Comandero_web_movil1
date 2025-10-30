@echo off
echo ========================================
echo    SOLUCION PARA EMULADORES ANDROID
echo ========================================
echo.

echo PROBLEMA: El emulador se abre pero Flutter no lo detecta
echo SOLUCION: Vamos a solucionarlo paso a paso
echo.

echo 1. Verificando estado actual...
flutter devices
echo.

echo 2. Si no aparece el emulador, vamos a reiniciarlo...
echo    Cerrando emuladores existentes...
taskkill /f /im qemu-system-x86_64.exe 2>nul
taskkill /f /im emulator.exe 2>nul
echo.

echo 3. Esperando 5 segundos...
timeout /t 5 /nobreak
echo.

echo 4. Iniciando emulador de tablet nuevamente...
flutter emulators --launch Medium_Tablet
echo.

echo 5. Esperando 60 segundos para inicializacion completa...
echo    (Esto es importante - el emulador necesita tiempo)
timeout /t 60 /nobreak
echo.

echo 6. Verificando dispositivos nuevamente...
flutter devices
echo.

echo 7. Si aparece el emulador, ejecutando aplicacion...
flutter run -d Medium_Tablet

pause



