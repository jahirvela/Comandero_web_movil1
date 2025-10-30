@echo off
echo ========================================
echo    COMANDERO - EJECUCION LIMPIA
echo ========================================
echo.

echo Esperando 60 segundos para que el emulador se inicie...
timeout /t 60 /nobreak
echo.

echo Verificando dispositivos...
flutter devices
echo.

echo Desinstalando aplicacion anterior si existe...
C:\Android\sdk\platform-tools\adb.exe uninstall com.example.comandero_flutter
echo.

echo Ejecutando aplicacion Comandero...
flutter run -d emulator-5554
echo.

pause

