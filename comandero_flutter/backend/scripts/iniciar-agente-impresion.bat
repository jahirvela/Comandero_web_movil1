@echo off
chcp 65001 >nul
title Agente de impresion USB - Comancleth
cd /d "%~dp0"

REM ========== CONFIGURACION: edite estas lineas ==========
REM URL del API (donde esta el sistema). Ejemplo: https://comancleth.com/api
set API_BASE_URL=https://comancleth.com/api

REM Clave para el agente: en la web Admin - Configuracion - Impresoras, edite la impresora y pulse "Generar clave para agente". Pegue aqui la clave (no caduca).
set AGENT_API_KEY=pegue_aqui_la_clave_del_agente

REM Si no usa clave de agente, puede usar token JWT (caduca): descomente la linea siguiente y comente AGENT_API_KEY
REM set AUTH_TOKEN=pegue_aqui_su_token

REM ID de la impresora (el numero que ve en Admin - Configuracion - Impresoras)
set IMPRESORA_ID=1

REM Nombre EXACTO de la impresora en Windows (como sale en Configuración - Impresoras y escaneres)
set PRINTER_DEVICE=ZKTECO
REM ========== Fin configuracion ==========

set SCRIPT_PS=%~dp0print-raw-windows.ps1

echo.
echo Agente de impresion USB - Comancleth
echo Deje esta ventana abierta para que imprima comandas y tickets.
echo.
npx tsx agente-impresion-usb.ts

echo.
pause
