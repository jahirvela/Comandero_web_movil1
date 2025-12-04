# Script para corregir configuración de CORS
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Corrigiendo Configuración de CORS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$envPath = Join-Path $PSScriptRoot "..\.env"

if (-not (Test-Path $envPath)) {
    Write-Host "❌ No se encontró el archivo .env" -ForegroundColor Red
    Write-Host "   Creando archivo .env desde .env.example..." -ForegroundColor Yellow
    
    $examplePath = Join-Path $PSScriptRoot "..\.env.example"
    if (Test-Path $examplePath) {
        Copy-Item $examplePath $envPath
        Write-Host "   ✅ Archivo .env creado" -ForegroundColor Green
    } else {
        Write-Host "   ❌ No se encontró .env.example" -ForegroundColor Red
        exit 1
    }
}

Write-Host "📄 Leyendo archivo .env..." -ForegroundColor Yellow
$envContent = Get-Content $envPath -Raw
$needsUpdate = $false

# Verificar y actualizar CORS_ORIGIN
if ($envContent -match "CORS_ORIGIN=(.+)") {
    $currentCors = $matches[1].Trim()
    Write-Host "   CORS_ORIGIN actual: $currentCors" -ForegroundColor Gray
    
    # Si no incluye el wildcard para localhost, actualizarlo
    if ($currentCors -notmatch "localhost:\*" -and $currentCors -notmatch "http://localhost:\*") {
        Write-Host "   ⚠️  Actualizando CORS_ORIGIN..." -ForegroundColor Yellow
        
        # Agregar localhost:* si no está
        $newCors = "http://localhost:*,http://127.0.0.1:*"
        if ($currentCors -ne "") {
            # Si ya hay valores, agregar al final
            $newCors = "$currentCors,$newCors"
        }
        
        $envContent = $envContent -replace "CORS_ORIGIN=(.+)", "CORS_ORIGIN=$newCors"
        $needsUpdate = $true
        Write-Host "   ✅ CORS_ORIGIN actualizado a: $newCors" -ForegroundColor Green
    } else {
        Write-Host "   ✅ CORS_ORIGIN ya está configurado correctamente" -ForegroundColor Green
    }
} else {
    Write-Host "   ⚠️  Agregando CORS_ORIGIN..." -ForegroundColor Yellow
    
    # Agregar CORS_ORIGIN al final del archivo
    $newCors = "http://localhost:*,http://127.0.0.1:*"
    if ($envContent -notmatch "`n$") {
        $envContent += "`n"
    }
    $envContent += "CORS_ORIGIN=$newCors`n"
    $needsUpdate = $true
    Write-Host "   ✅ CORS_ORIGIN agregado: $newCors" -ForegroundColor Green
}

if ($needsUpdate) {
    Write-Host ""
    Write-Host "💾 Guardando cambios..." -ForegroundColor Yellow
    Set-Content -Path $envPath -Value $envContent -NoNewline
    Write-Host "   ✅ Cambios guardados" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  IMPORTANTE: Reinicia el backend para que los cambios surtan efecto" -ForegroundColor Yellow
    Write-Host "   Ejecuta: npm run dev" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "✅ No se requieren cambios" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Proceso completado" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

