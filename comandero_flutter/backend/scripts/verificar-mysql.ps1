# Script para verificar el estado y configuración de MySQL81

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Estado de MySQL81" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$service = Get-Service -Name MySQL81 -ErrorAction SilentlyContinue

if ($null -eq $service) {
    Write-Host "ERROR: El servicio MySQL81 no existe" -ForegroundColor Red
    exit 1
}

Write-Host "Nombre del servicio: " -NoNewline
Write-Host $service.Name -ForegroundColor White

Write-Host "Estado actual: " -NoNewline
if ($service.Status -eq 'Running') {
    Write-Host $service.Status -ForegroundColor Green
} else {
    Write-Host $service.Status -ForegroundColor Red
}

Write-Host "Tipo de inicio: " -NoNewline
if ($service.StartType -eq 'Automatic') {
    Write-Host $service.StartType -ForegroundColor Green
    Write-Host ""
    Write-Host "✓ MySQL81 está configurado para iniciarse automáticamente" -ForegroundColor Green
    Write-Host "  Se iniciará cada vez que Windows inicie" -ForegroundColor Cyan
} elseif ($service.StartType -eq 'Manual') {
    Write-Host $service.StartType -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⚠ MySQL81 está configurado como Manual" -ForegroundColor Yellow
    Write-Host "  Necesitarás iniciarlo manualmente cada vez" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Para configurarlo como automático, ejecuta:" -ForegroundColor Cyan
    Write-Host "  Set-Service -Name MySQL81 -StartupType Automatic" -ForegroundColor White
} else {
    Write-Host $service.StartType -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

