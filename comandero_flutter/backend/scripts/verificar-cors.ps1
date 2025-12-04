# Script para verificar y corregir configuración de CORS
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verificación de CORS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$envPath = Join-Path $PSScriptRoot "..\.env"

if (-not (Test-Path $envPath)) {
    Write-Host "❌ No se encontró el archivo .env" -ForegroundColor Red
    Write-Host "   Ubicación esperada: $envPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "📄 Leyendo archivo .env..." -ForegroundColor Yellow
$envContent = Get-Content $envPath -Raw

# Verificar CORS_ORIGIN
if ($envContent -match "CORS_ORIGIN=(.+)") {
    $currentCors = $matches[1].Trim()
    Write-Host "   CORS_ORIGIN actual: $currentCors" -ForegroundColor Gray
    
    # Verificar si incluye localhost con wildcard
    if ($currentCors -match "localhost:\*" -or $currentCors -match "http://localhost:\*") {
        Write-Host "   ✅ CORS está configurado para permitir localhost con cualquier puerto" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  CORS podría no permitir todos los puertos de localhost" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   💡 Configuración recomendada:" -ForegroundColor Cyan
        Write-Host "      CORS_ORIGIN=http://localhost:*,http://127.0.0.1:*" -ForegroundColor Gray
    }
} else {
    Write-Host "   ❌ No se encontró CORS_ORIGIN en .env" -ForegroundColor Red
    Write-Host ""
    Write-Host "   💡 Agrega esta línea a tu .env:" -ForegroundColor Cyan
    Write-Host "      CORS_ORIGIN=http://localhost:*,http://127.0.0.1:*" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verificación completada" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

