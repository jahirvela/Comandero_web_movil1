# Script para forzar la configuración correcta de CORS
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Configurando CORS Correctamente" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$envPath = Join-Path $PSScriptRoot "..\.env"

if (-not (Test-Path $envPath)) {
    Write-Host "❌ No se encontró el archivo .env" -ForegroundColor Red
    Write-Host "   Creando desde .env.example..." -ForegroundColor Yellow
    
    $examplePath = Join-Path $PSScriptRoot "..\.env.example"
    if (Test-Path $examplePath) {
        Copy-Item $examplePath $envPath
    } else {
        Write-Host "   ❌ No se encontró .env.example" -ForegroundColor Red
        exit 1
    }
}

Write-Host "📄 Leyendo archivo .env..." -ForegroundColor Yellow
$lines = Get-Content $envPath
$newLines = @()
$corsFound = $false

foreach ($line in $lines) {
    if ($line -match "^CORS_ORIGIN=") {
        # Reemplazar la línea de CORS_ORIGIN
        $newLines += "CORS_ORIGIN=http://localhost:*,http://127.0.0.1:*"
        $corsFound = $true
        Write-Host "   ✅ CORS_ORIGIN actualizado" -ForegroundColor Green
    } else {
        $newLines += $line
    }
}

# Si no se encontró CORS_ORIGIN, agregarlo
if (-not $corsFound) {
    Write-Host "   ⚠️  CORS_ORIGIN no encontrado, agregando..." -ForegroundColor Yellow
    $newLines += ""
    $newLines += "# Configuración de CORS para desarrollo"
    $newLines += "CORS_ORIGIN=http://localhost:*,http://127.0.0.1:*"
    Write-Host "   ✅ CORS_ORIGIN agregado" -ForegroundColor Green
}

Write-Host ""
Write-Host "💾 Guardando cambios..." -ForegroundColor Yellow
$newLines | Set-Content -Path $envPath
Write-Host "   ✅ Cambios guardados" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Configuración de CORS:" -ForegroundColor Cyan
Write-Host "   CORS_ORIGIN=http://localhost:*,http://127.0.0.1:*" -ForegroundColor Gray
Write-Host ""
Write-Host "⚠️  IMPORTANTE: Reinicia el backend para que los cambios surtan efecto" -ForegroundColor Yellow
Write-Host "   1. Presiona Ctrl + C en la terminal del backend" -ForegroundColor Gray
Write-Host "   2. Ejecuta: npm run dev" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ CORS configurado correctamente" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
