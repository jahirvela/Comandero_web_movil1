@echo off
chcp 65001 >nul
title Instalar inicio automatico - Agente de impresion
cd /d "%~dp0"

REM Crea un acceso directo al agente en la carpeta de Inicio de Windows.
REM El cliente ejecuta ESTE .bat UNA SOLA VEZ; despues, cada vez que encienda
REM el PC (o inicie sesion) se abrira el agente automaticamente.

set TARGET=%~dp0iniciar-agente-impresion.bat
set STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup

echo.
echo Instalando inicio automatico del agente de impresion...
echo.

REM Crear acceso directo con PowerShell (compatible con Windows 7+)
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%STARTUP%\Agente impresion Comancleth.lnk'); $s.TargetPath = '%TARGET%'; $s.WorkingDirectory = '%~dp0'; $s.Save()"

if %ERRORLEVEL% EQU 0 (
    echo Listo. A partir de ahora el agente se abrira solo al iniciar Windows.
    echo Puede cerrar esta ventana.
) else (
    echo No se pudo crear el acceso directo. Puede hacerlo manualmente:
    echo 1. Presione Windows + R, escriba shell:startup y Enter.
    echo 2. Cree un acceso directo a "iniciar-agente-impresion.bat" dentro de esa carpeta.
)

echo.
pause
