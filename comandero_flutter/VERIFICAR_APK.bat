@echo off
echo ========================================
echo    VERIFICAR APK GENERADO
echo ========================================
echo.

set APK_PATH=build\app\outputs\flutter-apk\app-release.apk

if exist "%APK_PATH%" (
    echo ✅ APK encontrado!
    echo.
    echo Ubicacion: %APK_PATH%
    echo.
    
    for %%A in ("%APK_PATH%") do (
        set SIZE=%%~zA
        set /a SIZE_MB=!SIZE!/1024/1024
        echo Tamaño: !SIZE_MB! MB
    )
    
    echo.
    echo ========================================
    echo PROXIMOS PASOS:
    echo ========================================
    echo.
    echo 1. Enviar APK por WhatsApp Web
    echo    - Abre WhatsApp Web en tu navegador
    echo    - Envia el APK a ti mismo
    echo.
    echo 2. Descargar en tu celular desde WhatsApp
    echo.
    echo 3. Permitir fuentes desconocidas en Android
    echo.
    echo 4. Instalar el APK
    echo.
    echo 5. Configurar IP del servidor en la app
    echo    - Obtener IP: ipconfig (buscar IPv4)
    echo.
    echo 6. Iniciar backend: cd backend ^&^& npm run dev
    echo.
    echo 7. Hacer login y probar!
    echo.
    echo Para mas detalles, ver: INSTRUCCIONES_INSTALAR_APK.md
    echo.
    echo ========================================
    echo.
    echo ¿Deseas abrir la carpeta del APK? (S/N)
    set /p ABRIR="> "
    if /i "%ABRIR%"=="S" (
        explorer "build\app\outputs\flutter-apk"
    )
) else (
    echo ❌ APK no encontrado en: %APK_PATH%
    echo.
    echo Ejecuta: flutter build apk --release
    echo.
)

pause

