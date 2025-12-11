@echo off
REM Script simple para limpiar cache del navegador
echo 🧹 Limpiando cache del navegador...
echo.

REM Cerrar Chrome
taskkill /F /IM chrome.exe >nul 2>&1
if %errorlevel% == 0 (
    echo ✅ Chrome cerrado
) else (
    echo ℹ️  Chrome no estaba abierto
)

REM Cerrar Edge
taskkill /F /IM msedge.exe >nul 2>&1
if %errorlevel% == 0 (
    echo ✅ Edge cerrado
) else (
    echo ℹ️  Edge no estaba abierto
)

echo.
echo ⏳ Esperando 2 segundos...
timeout /t 2 /nobreak >nul

REM Limpiar cache de Chrome
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" (
    echo 📦 Limpiando cache de Chrome...
    rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" >nul 2>&1
    echo    ✅ Cache de Chrome limpiado
)

REM Limpiar cache de Edge
if exist "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" (
    echo 📦 Limpiando cache de Edge...
    rd /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache" >nul 2>&1
    echo    ✅ Cache de Edge limpiado
)

echo.
echo ✅ ¡Cache limpiado exitosamente!
echo.
echo 💡 Consejo: Abre el navegador en modo incógnito (Ctrl + Shift + N)
echo.
pause

