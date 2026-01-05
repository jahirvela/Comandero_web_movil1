@echo off
echo ========================================
echo    DESPLEGAR A PRODUCCION
echo ========================================
echo.
echo Este script te guiara para desplegar
echo el sistema en produccion.
echo.
echo IMPORTANTE: Este script es solo para
echo referencia. El despliegue real debe
echo hacerse en el servidor de produccion.
echo.
pause

echo.
echo ========================================
echo PASO 1: Compilar Backend
echo ========================================
echo.
cd backend
echo Compilando backend...
call npm run build
if %errorlevel% neq 0 (
    echo ERROR: No se pudo compilar el backend
    pause
    exit /b 1
)
echo ✅ Backend compilado exitosamente
cd ..

echo.
echo ========================================
echo PASO 2: Compilar Aplicacion Web
echo ========================================
echo.
echo Ingresa la URL de produccion:
echo Ejemplos:
echo   - Con dominio: https://www.comandix.com
echo   - Con IP: http://192.168.1.100
echo.
set /p PROD_URL="URL de produccion: "

if "%PROD_URL%"=="" (
    echo ERROR: Debes ingresar una URL
    pause
    exit /b 1
)

echo.
echo Compilando aplicacion web para: %PROD_URL%
echo.
flutter build web --release --dart-define=API_ENV=production --dart-define=API_URL=%PROD_URL%/api

if %errorlevel% neq 0 (
    echo ERROR: No se pudo compilar la aplicacion web
    pause
    exit /b 1
)

echo.
echo ✅ Aplicacion web compilada exitosamente
echo.
echo Ubicacion: build\web\
echo.

echo.
echo ========================================
echo PASO 3: Generar APK para Produccion
echo ========================================
echo.
echo ¿Deseas generar el APK ahora? (S/N)
set /p GENERAR_APK="> "

if /i "%GENERAR_APK%"=="S" (
    echo.
    echo Generando APK...
    flutter build apk --release --dart-define=API_ENV=production --dart-define=API_URL=%PROD_URL%/api
    
    if %errorlevel% neq 0 (
        echo ERROR: No se pudo generar el APK
        pause
        exit /b 1
    )
    
    echo.
    echo ✅ APK generado exitosamente
    echo.
    echo Ubicacion: build\app\outputs\flutter-apk\app-release.apk
    echo.
)

echo.
echo ========================================
echo RESUMEN
echo ========================================
echo.
echo ✅ Backend compilado: backend\dist\
echo ✅ Web compilada: build\web\
if /i "%GENERAR_APK%"=="S" (
    echo ✅ APK generado: build\app\outputs\flutter-apk\app-release.apk
)
echo.
echo PROXIMOS PASOS:
echo.
echo 1. Subir backend\dist\ al servidor
echo 2. Subir build\web\ al servidor (carpeta web)
echo 3. Configurar .env en el servidor (ver .env.production.example)
echo 4. Iniciar backend con PM2: pm2 start ecosystem.config.js
echo 5. Configurar Nginx para servir la web
echo 6. Instalar APK en dispositivos
echo.
echo Para mas detalles, ver: GUIA_DESPLIEGUE_PRODUCCION.md
echo.
pause

