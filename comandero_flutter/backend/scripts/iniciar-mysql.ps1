# Script para iniciar MySQL81
# Requiere ejecutarse como Administrador

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Iniciando MySQL81" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si ya está corriendo
$service = Get-Service -Name MySQL81 -ErrorAction SilentlyContinue

if ($null -eq $service) {
    Write-Host "ERROR: El servicio MySQL81 no existe" -ForegroundColor Red
    Write-Host "Verifica que MySQL esté instalado correctamente" -ForegroundColor Yellow
    exit 1
}

if ($service.Status -eq 'Running') {
    Write-Host "✓ MySQL81 ya está corriendo" -ForegroundColor Green
    exit 0
}

Write-Host "Intentando iniciar MySQL81..." -ForegroundColor Yellow

try {
    # Intentar iniciar el servicio
    Start-Service -Name MySQL81 -ErrorAction Stop
    Start-Sleep -Seconds 3
    
    $service = Get-Service -Name MySQL81
    if ($service.Status -eq 'Running') {
        Write-Host "✓ MySQL81 iniciado correctamente" -ForegroundColor Green
        Write-Host ""
        Write-Host "El servicio está corriendo en el puerto configurado en .env" -ForegroundColor Cyan
    } else {
        Write-Host "⚠ MySQL81 no se pudo iniciar. Estado: $($service.Status)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Intenta iniciarlo manualmente:" -ForegroundColor Cyan
        Write-Host "  1. Abre 'Servicios' (services.msc)" -ForegroundColor White
        Write-Host "  2. Busca 'MySQL81'" -ForegroundColor White
        Write-Host "  3. Haz clic derecho > Iniciar" -ForegroundColor White
        Write-Host ""
        Write-Host "O ejecuta este script como Administrador" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: No se pudo iniciar MySQL81" -ForegroundColor Red
    Write-Host "Mensaje: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Posibles soluciones:" -ForegroundColor Yellow
    Write-Host "  1. Ejecuta PowerShell como Administrador" -ForegroundColor White
    Write-Host "  2. Verifica que MySQL esté instalado correctamente" -ForegroundColor White
    Write-Host "  3. Inicia MySQL manualmente desde 'Servicios'" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
