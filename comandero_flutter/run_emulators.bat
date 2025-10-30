@echo off
echo Iniciando emuladores de Android...

echo Iniciando emulador de celular (Pixel 5)...
start /B flutter emulators --launch Pixel_5_API_33

echo Esperando 30 segundos para que se inicie el primer emulador...
timeout /t 30 /nobreak

echo Iniciando emulador de tablet (Medium Tablet)...
start /B flutter emulators --launch Medium_Tablet

echo Esperando 30 segundos para que se inicie el segundo emulador...
timeout /t 30 /nobreak

echo Verificando dispositivos disponibles...
flutter devices

echo.
echo Ejecutando aplicacion en emulador de celular...
flutter run -d Pixel_5_API_33

pause


