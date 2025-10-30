@echo off
echo ========================================
echo    SOLUCION ALTERNATIVA - ADB
echo ========================================
echo.

echo Esta solucion usa ADB directamente para conectar
echo.

echo 1. Buscando ADB en el sistema...
where adb >nul 2>&1
if %errorlevel% neq 0 (
    echo ADB no encontrado en PATH, buscando en Android SDK...
    set ADB_PATH=C:\Android\sdk\platform-tools\adb.exe
    if exist "%ADB_PATH%" (
        set PATH=%PATH%;C:\Android\sdk\platform-tools
        echo ADB encontrado en: %ADB_PATH%
    ) else (
        echo ERROR: ADB no encontrado. Instala Android SDK.
        pause
        exit /b 1
    )
)

echo 2. Verificando dispositivos ADB...
adb devices
echo.

echo 3. Si aparece el emulador, ejecutando aplicacion...
flutter run -d Medium_Tablet

pause



