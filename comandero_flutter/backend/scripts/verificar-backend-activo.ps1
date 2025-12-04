# Script para verificar que el backend esté activo y accesible
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verificación del Backend" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar que el puerto 3000 esté en uso
Write-Host "1. Verificando puerto 3000..." -ForegroundColor Yellow
$port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
if ($port3000) {
    $state = $port3000[0].State
    Write-Host "   ✅ Puerto 3000 está en uso (Estado: $state)" -ForegroundColor Green
} else {
    Write-Host "   ❌ Puerto 3000 NO está en uso" -ForegroundColor Red
    Write-Host "   💡 El backend no está corriendo" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Solución:" -ForegroundColor Cyan
    Write-Host "   cd comandero_flutter\backend" -ForegroundColor Gray
    Write-Host "   npm run dev" -ForegroundColor Gray
    exit 1
}
Write-Host ""

# 2. Verificar que el endpoint /api/health responda
Write-Host "2. Verificando endpoint /api/health..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -Method GET -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✅ Backend responde correctamente" -ForegroundColor Green
        Write-Host "   Respuesta: $($response.Content)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ Backend NO responde" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "   💡 Posibles causas:" -ForegroundColor Yellow
    Write-Host "   - El backend está iniciando (espera unos segundos)" -ForegroundColor Gray
    Write-Host "   - Hay un error en el backend (revisa la terminal)" -ForegroundColor Gray
    Write-Host "   - MySQL no está corriendo" -ForegroundColor Gray
    exit 1
}
Write-Host ""

# 3. Verificar CORS
Write-Host "3. Verificando configuración de CORS..." -ForegroundColor Yellow
$envPath = Join-Path $PSScriptRoot "..\.env"
if (Test-Path $envPath) {
    $envContent = Get-Content $envPath -Raw
    if ($envContent -match "CORS_ORIGIN=(.+)") {
        $corsOrigin = $matches[1].Trim()
        if ($corsOrigin -match "localhost:\*") {
            Write-Host "   ✅ CORS configurado para permitir localhost:*" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  CORS podría no permitir todos los puertos" -ForegroundColor Yellow
            Write-Host "   Actual: $corsOrigin" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "   ⚠️  No se encontró archivo .env" -ForegroundColor Yellow
}
Write-Host ""

# 4. Verificar MySQL
Write-Host "4. Verificando MySQL..." -ForegroundColor Yellow
try {
    $mysql = Get-Service -Name MySQL81 -ErrorAction Stop
    if ($mysql.Status -eq 'Running') {
        Write-Host "   ✅ MySQL está corriendo" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  MySQL NO está corriendo" -ForegroundColor Yellow
        Write-Host "   Estado: $($mysql.Status)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ⚠️  No se pudo verificar MySQL" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Backend está activo y accesible" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Si el frontend aún no se conecta:" -ForegroundColor Yellow
Write-Host "   1. Reinicia el frontend (Ctrl + C y flutter run -d chrome)" -ForegroundColor Gray
Write-Host "   2. Verifica la consola del navegador (F12)" -ForegroundColor Gray
Write-Host "   3. Asegúrate de que CORS esté configurado correctamente" -ForegroundColor Gray

