@echo off
echo ========================================
echo    GENERAR APK - COMANDERO FLUTTER
echo ========================================
echo.

echo Selecciona el tipo de APK a generar:
echo.
echo 1. APK Debug (rapido, para pruebas)
echo 2. APK Release (optimizado, para distribucion)
echo 3. APK Split (mas pequeno, por arquitectura)
echo 4. Salir
echo.

set /p opcion="Ingresa el numero de opcion (1-4): "

if "%opcion%"=="1" goto debug
if "%opcion%"=="2" goto release
if "%opcion%"=="3" goto split
if "%opcion%"=="4" goto salir

echo Opcion invalida
pause
exit /b 1

:debug
echo.
echo Generando APK Debug...
echo.
flutter build apk --debug
if %errorlevel% neq 0 (
    echo.
    echo ERROR: No se pudo generar el APK
    pause
    exit /b 1
)
echo.
echo ========================================
echo APK Debug generado exitosamente!
echo.
echo Ubicacion: build\app\outputs\flutter-apk\app-debug.apk
echo ========================================
goto fin

:release
echo.
echo Generando APK Release (optimizado)...
echo.
flutter build apk --release
if %errorlevel% neq 0 (
    echo.
    echo ERROR: No se pudo generar el APK
    pause
    exit /b 1
)
echo.
echo ========================================
echo APK Release generado exitosamente!
echo.
echo Ubicacion: build\app\outputs\flutter-apk\app-release.apk
echo.
echo Tamaño aproximado: 
dir /s build\app\outputs\flutter-apk\app-release.apk | find "app-release.apk"
echo ========================================
goto fin

:split
echo.
echo Generando APK Split (por arquitectura)...
echo.
flutter build apk --split-per-abi --release
if %errorlevel% neq 0 (
    echo.
    echo ERROR: No se pudo generar el APK
    pause
    exit /b 1
)
echo.
echo ========================================
echo APK Split generado exitosamente!
echo.
echo Ubicaciones:
echo   - build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk (32-bit)
echo   - build\app\outputs\flutter-apk\app-arm64-v8a-release.apk (64-bit, recomendado)
echo   - build\app\outputs\flutter-apk\app-x86_64-release.apk (x86)
echo.
echo Recomendacion: Usa app-arm64-v8a-release.apk para la mayoria de dispositivos
echo ========================================
goto fin

:salir
exit /b 0

:fin
echo.
echo Deseas abrir la carpeta del APK? (S/N)
set /p abrir="> "
if /i "%abrir%"=="S" (
    explorer build\app\outputs\flutter-apk
)
echo.
pause

